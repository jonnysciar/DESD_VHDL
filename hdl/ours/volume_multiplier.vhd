library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity volume_multiplier is
    Generic (
        TDATA_WIDTH     : positive := 24;
        AMP_WIDTH       : positive := 5;
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
        
        amp_factor      : in std_logic_vector(AMP_WIDTH-1 downto 0)
    );
end volume_multiplier;

architecture Behavioral of volume_multiplier is
    signal s_axis_tready_int : std_logic := '0';
    signal m_axis_tvalid_int : std_logic := '0';

begin
    s_axis_tready <= s_axis_tready_int;
    m_axis_tvalid <= m_axis_tvalid_int;

    process(aclk, aresetn)
    variable v_amp_factor : integer;
    variable v_data	: std_logic_vector(TDATA_WIDTH-2 downto 0);
    begin
        if aresetn = '0' then
            s_axis_tready_int <= '0';
            m_axis_tvalid_int <= '0';
        elsif rising_edge(aclk) then
            s_axis_tready_int <= '1';
            m_axis_tvalid_int <= '0';
            
            if s_axis_tvalid = '1' and s_axis_tready_int = '1' and m_axis_tready = '1' then
                m_axis_tlast <= s_axis_tlast;
                m_axis_tvalid_int <= '1';
                v_amp_factor := to_integer(signed(amp_factor));
                
                if v_amp_factor > 0 then
                    if s_axis_tdata(s_axis_tdata'high) = '0' then
                        v_data := s_axis_tdata(TDATA_WIDTH-2 downto 0);
                        if unsigned(v_data(TDATA_WIDTH-2 downto TDATA_WIDTH-1-v_amp_factor)) /= 0 then
                            v_data := std_logic_vector(to_unsigned(HIGHER_BOUND, TDATA_WIDTH-1));
                        else
                            v_data := std_logic_vector(shift_left(unsigned(v_data), abs(v_amp_factor)));
                        end if;
                        m_axis_tdata <= s_axis_tdata(s_axis_tdata'high) & v_data;
                    else
                        m_axis_tdata <= std_logic_vector(shift_left(unsigned(s_axis_tdata), abs(v_amp_factor)));
                        if s_axis_tdata(s_axis_tdata'high - 1) = '0' then
                            m_axis_tdata <= std_logic_vector(to_unsigned(LOWER_BOUND, TDATA_WIDTH));
                        end if;
                    end if;
                elsif v_amp_factor < 0 then
                    m_axis_tdata <= std_logic_vector(shift_right(signed(s_axis_tdata), abs(v_amp_factor)));
                else
                    m_axis_tdata <= s_axis_tdata;
                end if;
                
            end if;
        end if;
    end process;
end Behavioral;
