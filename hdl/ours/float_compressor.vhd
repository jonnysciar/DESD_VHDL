
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
    constant MAX_EXP : integer := 2**EXPONENT_LENGTH;

    
    signal sign_bit  : std_logic := '0';
    signal in_module : unsigned(CHANNEL_LENGHT-1 downto 0) := (others => '0');

    signal exponent  : std_logic_vector(EXPONENT_LENGTH-1 downto 0) := (others => '0');
    signal mantissa  : std_logic_vector(MANTISSA_LENGTH-1 downto 0) := (others => '0');
    
    signal is_small :   std_logic := '0';
    signal is_overflow  : std_logic := '0';

    signal out_valid : std_logic := '0';
    signal out_last  : std_logic := '0';

    
    type state_type is (EXTRACT_NUM, GET_EXP, FIX_MANTISSA);
    signal state : state_type := EXTRACT_NUM;

    -- MSB index stored between states
    signal msb_index : integer range 0 to CHANNEL_LENGHT-1 := 0;

begin

    
    process(aclk, aresetn)

        variable msb_tmp : integer range 0 to CHANNEL_LENGHT-1;
        variable tmp     : unsigned(CHANNEL_LENGHT-1 downto 0);

    begin
        if aresetn = '0' then
            sign_bit  <= '0';
            in_module <= (others => '0');
            exponent  <= (others => '0');
            mantissa  <= (others => '0');
            out_valid <= '0';
            out_last  <= '0';
            is_small    <= '0';
            is_overflow <= '0';
            state     <= EXTRACT_NUM;

        elsif rising_edge(aclk) then

            if out_valid = '1' and m_axis_tready = '1' then
                out_valid <= '0';
            end if;

            case state is

               -- to get the input in an useful form
                when EXTRACT_NUM =>
                    if s_axis_tvalid = '1' and m_axis_tready = '1' then
                        sign_bit  <= s_axis_tdata(CHANNEL_LENGHT-1);
                        in_module <= unsigned(abs(signed(s_axis_tdata)));
                        out_last  <= s_axis_tlast;
                        is_small <= '0';
                        is_overflow <= '0';
                        state     <= GET_EXP;
                    end if;

                --compute msb and exponential part of the number
                when GET_EXP =>
                    -- Find MSB index
                    msb_tmp := 0;
                    for i in CHANNEL_LENGHT-1 downto 0 loop
                        if in_module(i) = '1' then
                            msb_tmp := i;
                            exit;
                        end if;
                    end loop;

                    -- Store MSB for next state
                    msb_index <= msb_tmp;

                    -- Exponent logic
                    if msb_tmp < MANTISSA_LENGTH then
                        exponent <= (others => '0');
                        is_small <= '1';
                    elsif msb_tmp >= MAX_EXP - 1 then
                        exponent <= (others => '1');
                        sign_bit <= '1';
                        is_overflow <= '1';
                    else
                        exponent <= std_logic_vector(to_unsigned(msb_tmp, EXPONENT_LENGTH));
                    end if;

                    state <= FIX_MANTISSA;

                --mantissa assignment
                when FIX_MANTISSA =>
                    if is_small = '1' then
                        tmp := in_module;
                    elsif is_overflow = '1' then
                        tmp := (others => '1');
                    else
                        tmp := in_module srl (msb_index - MANTISSA_LENGTH); 
                    end if;

                    mantissa  <= std_logic_vector(tmp(MANTISSA_LENGTH-1 downto 0));
                    out_valid <= '1';
                    state     <= EXTRACT_NUM;

            end case;
        end if;
    end process;

    --axis output
    m_axis_tdata  <= sign_bit & exponent & mantissa;
    m_axis_tvalid <= out_valid;
    m_axis_tlast  <= out_last;

    s_axis_tready <= '1' when (state = EXTRACT_NUM) and (m_axis_tready = '1') else '0';

end architecture rtl;
