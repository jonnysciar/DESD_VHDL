library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity volume_multiplier is
    Generic (
        TDATA_WIDTH     : positive := 24;
        VOLUME_WIDTH    : positive := 10;
        HIGHER_BOUND	: integer := 2**23-1;	-- Inclusive (max value of TDATA at 24 bit signed)
        LOWER_BOUND		: integer := -2**23		-- Inclusive (min value of TDATA at 24 bit signed)
    );
    Port (
        aresetn         : in std_logic;
        aclk            : in std_logic;

        s_axis_tvalid	: in std_logic;
        s_axis_tdata	: in std_logic_vector(TDATA_WIDTH-1 downto 0);
        s_axis_tlast	: in std_logic;
        s_axis_tready	: out std_logic;

        m_axis_tvalid	: out std_logic;
        m_axis_tdata	: out std_logic_vector(TDATA_WIDTH-1 downto 0);
        m_axis_tlast	: out std_logic;
        m_axis_tready	: in std_logic;
        
        amp_factor      : in std_logic_vector(VOLUME_WIDTH-1 downto 0)
    );
end volume_multiplier;

architecture Behavioral of volume_multiplier is
    signal s_axis_tready_int : std_logic := '0';

begin
    s_axis_tready <= s_axis_tready_int;

    process(aclk, aresetn)
    variable v_amp_factor : integer;
    variable v_data	: signed(TDATA_WIDTH + VOLUME_WIDTH - 1 downto 0);
    begin
        if aresetn = '0' then
            s_axis_tready_int <= '0';
            m_axis_tvalid <= '0';
        elsif rising_edge(aclk) then
            s_axis_tready_int <= '1';
            m_axis_tvalid <= '0';
            
            if s_axis_tvalid = '1' and s_axis_tready_int = '1' and m_axis_tready = '1' then
                m_axis_tlast <= s_axis_tlast;
                m_axis_tvalid <= '1';
                v_amp_factor := to_integer(signed(amp_factor));

                if v_amp_factor > 0 then
                    v_data := shift_left(resize(signed(s_axis_tdata), TDATA_WIDTH + VOLUME_WIDTH), v_amp_factor);
                else
                    v_data := shift_right(resize(signed(s_axis_tdata), TDATA_WIDTH + VOLUME_WIDTH), -v_amp_factor);
                end if;

                if v_data < LOWER_BOUND then
                    m_axis_tdata <= std_logic_vector(to_signed(LOWER_BOUND, TDATA_WIDTH));
                elsif v_data > HIGHER_BOUND then
                    m_axis_tdata <= std_logic_vector(to_signed(HIGHER_BOUND, TDATA_WIDTH));
                else
                    m_axis_tdata <= std_logic_vector(resize(v_data, TDATA_WIDTH));
                end if;
                
            end if;
        end if;
    end process;
end Behavioral;
