library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity output_sel_tb is
end entity output_sel_tb;

architecture Behavioral of output_sel_tb is

    component output_sel is
        Generic (
            TDATA_WIDTH		: positive := 24;		-- 3 byte for audio
            LED_WIDTH		: positive := 8;
            HIGHER_BOUND	: integer := 2**23-1;	-- Inclusive (max value of TDATA at 24 bit signed)
            LOWER_BOUND		: integer := -2**23		-- Inclusive (min value of TDATA at 24 bit signed)
        );
        Port (
            aclk			: in std_logic;
            aresetn			: in std_logic;

            s_axis_tvalid	: in std_logic;
            s_axis_tdata	: in std_logic_vector(TDATA_WIDTH-1 downto 0);
            s_axis_tlast	: in std_logic;
            s_axis_tready	: out std_logic;

            m_axis_tvalid	: out std_logic;
            m_axis_tdata	: out std_logic_vector(TDATA_WIDTH-1 downto 0);
            m_axis_tlast	: out std_logic;
            m_axis_tready	: in std_logic;

            toggle			: in std_logic;

            led_r			: out std_logic_vector(LED_WIDTH-1 downto 0);
            led_g			: out std_logic_vector(LED_WIDTH-1 downto 0);
            led_b			: out std_logic_vector(LED_WIDTH-1 downto 0)
        );
    end component output_sel;
    
    constant TDATA_WIDTH	: positive := 24;
    constant LED_WIDTH	    : positive := 8;
    constant HIGHER_BOUND	: integer := 2**23-1;	-- Inclusive (max value of TDATA at 24 bit signed)
    constant LOWER_BOUND	: integer := -2**23;    -- Inclusive (min value of TDATA at 24 bit signed)
    
    signal aclk             : std_logic := '0';
    signal aresetn			: std_logic;

    signal s_axis_tvalid	: std_logic;
    signal s_axis_tdata	    : std_logic_vector(TDATA_WIDTH-1 downto 0);
    signal s_axis_tlast	    : std_logic;
    signal s_axis_tready	: std_logic;

    signal m_axis_tvalid	: std_logic;
    signal m_axis_tdata	    : std_logic_vector(TDATA_WIDTH-1 downto 0);
    signal m_axis_tlast	    : std_logic;
    signal m_axis_tready	: std_logic;
    
    signal toggle  : std_logic := '0';

    signal led_r   : std_logic_vector(LED_WIDTH-1 downto 0) := (others => '0');
    signal led_g	: std_logic_vector(LED_WIDTH-1 downto 0) := (others => '0');
    signal led_b	: std_logic_vector(LED_WIDTH-1 downto 0) := (others => '0');
begin

    aresetn <= '1';
    aclk <= not aclk after 5 ns;
    
    output_sel_inst: output_sel
    generic map(
        TDATA_WIDTH	=> TDATA_WIDTH,
        LED_WIDTH => LED_WIDTH,
        HIGHER_BOUND => HIGHER_BOUND,
        LOWER_BOUND => LOWER_BOUND
    )
    port map (
        aclk => aclk,
        aresetn	=> aresetn,
    
        s_axis_tvalid => s_axis_tvalid, 
        s_axis_tdata => s_axis_tdata, 
        s_axis_tlast => s_axis_tlast, 
        s_axis_tready => s_axis_tready, 
    
        m_axis_tvalid => m_axis_tvalid,
        m_axis_tdata => m_axis_tdata,
        m_axis_tlast => m_axis_tlast,
        m_axis_tready => m_axis_tready,

        toggle => toggle,

        led_r => led_r,
        led_g => led_g,
        led_b => led_b
    );

    m_axis_tready <= '1';
    
    process(aclk)
    begin
        if rising_edge(aclk) then
            if s_axis_tready = '1' then
                s_axis_tdata <= std_logic_vector(to_signed(1, s_axis_tdata'length));
                s_axis_tvalid <= '1';
                s_axis_tlast <= not s_axis_tdata; 
            end if;
        end if;
    end process;
    
end architecture;