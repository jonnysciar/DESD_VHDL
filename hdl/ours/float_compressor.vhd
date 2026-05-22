library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity float_compressor is
    generic(
        CHANNEL_LENGHT  : positive := 24;
        OUTPUT_LENGHT   : positive := 16;
        EXPONENT_LENGTH : positive := 4
    );
    port (
        aclk    : in  std_logic;
        aresetn : in  std_logic;

        s_axis_tvalid : in  std_logic;
        s_axis_tdata  : in  std_logic_vector(CHANNEL_LENGHT-1 downto 0);
        s_axis_tlast  : in  std_logic;
        s_axis_tready : out std_logic;

        m_axis_tvalid : out std_logic;
        m_axis_tdata  : out std_logic_vector(OUTPUT_LENGHT-1 downto 0);
        m_axis_tlast  : out std_logic;
        m_axis_tready : in  std_logic
    );
end entity float_compressor;

architecture rtl of float_compressor is
    constant MANTISSA_LENGTH : positive := OUTPUT_LENGHT - 1 - EXPONENT_LENGTH;
    
    signal sign_bit  : std_logic := '0';
    signal exponent  : std_logic_vector(EXPONENT_LENGTH-1 downto 0) := (others => '0');
    signal mantissa  : std_logic_vector(MANTISSA_LENGTH-1 downto 0) := (others => '0');

    signal s_axis_tready_int : std_logic := '0';

    signal last_int  : std_logic := '0';
    signal data_int  : unsigned(CHANNEL_LENGHT-1 downto 0);

    type state_type is (READ, COMPUTE, WRITE);
    signal state : state_type := READ;
begin
    s_axis_tready <= s_axis_tready_int;

    with state select s_axis_tready_int <=
    '1' when READ,
    '0' when COMPUTE,
    '0' when WRITE;
    
    process(aclk, aresetn)
        variable v_msb_pos : integer := 0;
        variable v_sign_bit : std_logic := '0';
    begin
        if aresetn = '0' then
            sign_bit  <= '0';
            exponent  <= (others => '0');
            mantissa  <= (others => '0');

            last_int <= '0';
            data_int <= (others => '0');
            m_axis_tvalid <= '0';
        elsif rising_edge(aclk) then
            m_axis_tvalid <= '0';

            case state is
               -- Read the input and preprocess it
                when READ =>
                    if s_axis_tvalid = '1' and s_axis_tready_int = '1' then
                        v_sign_bit := s_axis_tdata(CHANNEL_LENGHT - 1);
                        sign_bit <= v_sign_bit;
                        last_int <= s_axis_tlast;

                        if v_sign_bit = '1' then
                            data_int <= unsigned(-signed(s_axis_tdata));
                        else
                            data_int <= unsigned(s_axis_tdata);
                        end if;

                        state <= COMPUTE;
                    end if;

                -- Compute exponent and mantissa
                when COMPUTE =>
                    v_msb_pos := 0;

                    for i in CHANNEL_LENGHT-1 downto 0 loop
                        if data_int(i) = '1' then
                            v_msb_pos := i;
                            exit;
                        end if;
                    end loop;

                    if v_msb_pos < MANTISSA_LENGTH then
                        exponent <= (others => '0');
                        mantissa <= std_logic_vector(data_int(MANTISSA_LENGTH-1 downto 0));
                    else
                        exponent <= std_logic_vector(to_unsigned(v_msb_pos - MANTISSA_LENGTH + 1, EXPONENT_LENGTH));
                        mantissa <= std_logic_vector(data_int(v_msb_pos - 1 downto v_msb_pos - MANTISSA_LENGTH));
                    end if;

                    state <= WRITE;

                -- Write sign_bit, exponent and mantissa
                when WRITE =>
                    if m_axis_tready = '1' then
                        m_axis_tdata <= sign_bit & exponent & mantissa;
                        m_axis_tlast <= last_int;
                        m_axis_tvalid <= '1';
                        state <= READ;
                    end if;
            end case;
        end if;
    end process;
end architecture rtl;
