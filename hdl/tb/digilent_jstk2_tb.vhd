library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity digilent_jstk2_tb is
end digilent_jstk2_tb;

architecture Behavioral of digilent_jstk2_tb is

    -- Reference DUT
    component digilent_jstk2
    generic (
        DELAY_US        : integer := 25;
        CLKFREQ         : integer := 100_000_000;
        SPI_SCLKFREQ    : integer := 66_666
    );
    Port ( 
        aclk            : in  STD_LOGIC;
        aresetn         : in  STD_LOGIC;

        m_axis_tvalid   : out STD_LOGIC;
        m_axis_tdata    : out STD_LOGIC_VECTOR(7 downto 0);
        m_axis_tready   : in  STD_LOGIC;

        s_axis_tvalid   : in  STD_LOGIC;
        s_axis_tdata    : in  STD_LOGIC_VECTOR(7 downto 0);

        jstk_x          : out std_logic_vector(9 downto 0);
        jstk_y          : out std_logic_vector(9 downto 0);
        btn_trigger     : out std_logic;
        btn_jstk        : out std_logic;
        
        led_r           : in  std_logic_vector(7 downto 0);
        led_g           : in  std_logic_vector(7 downto 0);
        led_b           : in  std_logic_vector(7 downto 0)
    );
    end component;

    -- My implementation DUT
    component digilent_jstk2_1
    generic (
        DELAY_US        : integer := 25;
        CLKFREQ         : integer := 100_000_000;
        SPI_SCLKFREQ    : integer := 66_666
    );
    Port ( 
        aclk            : in  STD_LOGIC;
        aresetn         : in  STD_LOGIC;

        m_axis_tvalid   : out STD_LOGIC;
        m_axis_tdata    : out STD_LOGIC_VECTOR(7 downto 0);
        m_axis_tready   : in  STD_LOGIC;

        s_axis_tvalid   : in  STD_LOGIC;
        s_axis_tdata    : in  STD_LOGIC_VECTOR(7 downto 0);

        jstk_x          : out std_logic_vector(9 downto 0);
        jstk_y          : out std_logic_vector(9 downto 0);
        btn_trigger     : out std_logic;
        btn_jstk        : out std_logic;
        
        led_r           : in  std_logic_vector(7 downto 0);
        led_g           : in  std_logic_vector(7 downto 0);
        led_b           : in  std_logic_vector(7 downto 0)
    );
    end component;

    -- Clock period definitions
    constant CLK_PERIOD : time := 10 ns;

    -- Inputs (Common)
    signal aclk          : std_logic := '0';
    signal aresetn       : std_logic := '0';
    signal m_axis_tready : std_logic := '1'; -- always ready for the master output
    signal led_r         : std_logic_vector(7 downto 0) := (others => '0');
    signal led_g         : std_logic_vector(7 downto 0) := (others => '0');
    signal led_b         : std_logic_vector(7 downto 0) := (others => '0');

    -- Outputs (DUT 0)
    signal m_axis_tvalid_0 : std_logic;
    signal m_axis_tdata_0  : std_logic_vector(7 downto 0);

    -- Outputs (DUT 1)
    signal m_axis_tvalid_1 : std_logic;
    signal m_axis_tdata_1  : std_logic_vector(7 downto 0);

begin

    -- Instantiate the reference implementation (DUT 0)
    dut0: digilent_jstk2
    port map (
        aclk          => aclk,
        aresetn       => aresetn,
        m_axis_tvalid => m_axis_tvalid_0,
        m_axis_tdata  => m_axis_tdata_0,
        m_axis_tready => m_axis_tready,
        s_axis_tvalid => '0',
        s_axis_tdata  => (others => '0'),
        jstk_x        => open,
        jstk_y        => open,
        btn_trigger   => open,
        btn_jstk      => open,
        led_r         => led_r,
        led_g         => led_g,
        led_b         => led_b
    );

    -- Instantiate my own implementation (DUT 1)
    dut1: digilent_jstk2_1
    port map (
        aclk          => aclk,
        aresetn       => aresetn,
        m_axis_tvalid => m_axis_tvalid_1,
        m_axis_tdata  => m_axis_tdata_1,
        m_axis_tready => m_axis_tready,
        s_axis_tvalid => '0',
        s_axis_tdata  => (others => '0'),
        jstk_x        => open,
        jstk_y        => open,
        btn_trigger   => open,
        btn_jstk      => open,
        led_r         => led_r,
        led_g         => led_g,
        led_b         => led_b
    );

    -- Clock process definitions
    clk_process: process
    begin
        aclk <= '0';
        wait for CLK_PERIOD/2;
        aclk <= '1';
        wait for CLK_PERIOD/2;
    end process;

    -- Stimulus process
    stim_proc: process
    begin
        -- Hold reset state for 100 ns.
        wait for 100 ns;
        aresetn <= '1';
        
        -- Start giving LED values 
        
        -- Test Case 1: Pure Red
        led_r <= x"FF";
        led_g <= x"00";
        led_b <= x"00";
        -- The base delay is 25 us, plus time to transmit. Wait 50us to be safe.
        wait for 50 us; 
        
        -- Test Case 2: Pure Green
        led_r <= x"00";
        led_g <= x"FF";
        led_b <= x"00";
        wait for 50 us; 
        
        -- Test Case 3: Mixed color (Purple)
        led_r <= x"AA";
        led_g <= x"00";
        led_b <= x"BB";
        wait for 50 us;
        
        -- Test Case 4: White
        led_r <= x"FF";
        led_g <= x"FF";
        led_b <= x"FF";
        wait for 50 us;

    end process;

end Behavioral;