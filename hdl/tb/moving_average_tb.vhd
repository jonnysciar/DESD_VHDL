library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity moving_average_tb is
end moving_average_tb;

architecture Behavioral of moving_average_tb is

    -- Component Declaration for REF (moving_average)
    component moving_average
        Generic (
            LOG2_LEN : POSITIVE := 5;
            CHANNEL_LENGHT : integer := 24
        );
        Port (
            aclk : in std_logic;
            aresetn : in std_logic;
            s_axis_tvalid : in std_logic;
            s_axis_tready : out std_logic;
            s_axis_tdata : in std_logic_vector(CHANNEL_LENGHT-1 downto 0);
            s_axis_tlast : in std_logic;
            enable_filter : in std_logic;
            m_axis_tready : in std_logic;
            m_axis_tvalid : out std_logic;
            m_axis_tdata : out std_logic_vector(CHANNEL_LENGHT-1 downto 0);
            m_axis_tlast : out std_logic
        );
    end component;

    -- Component Declaration for DUT (moving_average_1)
    component moving_average_1
        Generic (
            LOG2_LEN : POSITIVE := 5;
            CHANNEL_LENGHT : integer := 24;
            MEMORY_DEPTH : integer := 32
        );
        Port (
            aclk : in std_logic;
            aresetn : in std_logic;
            s_axis_tvalid : in std_logic;
            s_axis_tready : out std_logic;
            s_axis_tdata : in std_logic_vector(CHANNEL_LENGHT-1 downto 0);
            s_axis_tlast : in std_logic;
            enable_filter : in std_logic;
            m_axis_tready : in std_logic;
            m_axis_tvalid : out std_logic;
            m_axis_tdata : out std_logic_vector(CHANNEL_LENGHT-1 downto 0);
            m_axis_tlast : out std_logic
        );
    end component;

    -- Constants
    constant CHANNEL_LENGHT : integer := 24;
    constant clk_period : time := 10 ns; -- 100 MHz clock

    -- Global Signals
    signal aclk : std_logic := '0';
    signal aresetn : std_logic := '0';
    signal enable_filter : std_logic := '1';
    
    -- Shared Next stage readiness
    signal m_axis_tready : std_logic := '1';

    -- Signals for REF
    signal ref_s_axis_tvalid : std_logic := '0';
    signal ref_s_axis_tready : std_logic;
    signal ref_s_axis_tdata : std_logic_vector(CHANNEL_LENGHT-1 downto 0) := (others => '0');
    signal ref_s_axis_tlast : std_logic := '0';
    signal ref_m_axis_tvalid : std_logic;
    signal ref_m_axis_tdata : std_logic_vector(CHANNEL_LENGHT-1 downto 0);
    signal ref_m_axis_tlast : std_logic;

    -- Signals for DUT
    signal dut_s_axis_tvalid : std_logic := '0';
    signal dut_s_axis_tready : std_logic;
    signal dut_s_axis_tdata : std_logic_vector(CHANNEL_LENGHT-1 downto 0) := (others => '0');
    signal dut_s_axis_tlast : std_logic := '0';
    signal dut_m_axis_tvalid : std_logic;
    signal dut_m_axis_tdata : std_logic_vector(CHANNEL_LENGHT-1 downto 0);
    signal dut_m_axis_tlast : std_logic;

begin

    -- Instantiate REF
    ref_inst: moving_average
    generic map (
        LOG2_LEN => 5, CHANNEL_LENGHT => CHANNEL_LENGHT
    )
    port map (
        aclk => aclk, aresetn => aresetn, enable_filter => enable_filter,
        s_axis_tvalid => ref_s_axis_tvalid, s_axis_tready => ref_s_axis_tready,
        s_axis_tdata => ref_s_axis_tdata, s_axis_tlast => ref_s_axis_tlast,
        m_axis_tready => m_axis_tready, m_axis_tvalid => ref_m_axis_tvalid,
        m_axis_tdata => ref_m_axis_tdata, m_axis_tlast => ref_m_axis_tlast
    );

    -- Instantiate DUT
    dut_inst: moving_average_1
    generic map (
        LOG2_LEN => 5, CHANNEL_LENGHT => CHANNEL_LENGHT, MEMORY_DEPTH => 32
    )
    port map (
        aclk => aclk, aresetn => aresetn, enable_filter => enable_filter,
        s_axis_tvalid => dut_s_axis_tvalid, s_axis_tready => dut_s_axis_tready,
        s_axis_tdata => dut_s_axis_tdata, s_axis_tlast => dut_s_axis_tlast,
        m_axis_tready => m_axis_tready, m_axis_tvalid => dut_m_axis_tvalid,
        m_axis_tdata => dut_m_axis_tdata, m_axis_tlast => dut_m_axis_tlast
    );

    -- Clock process
    clk_process : process
    begin
        aclk <= '0';
        wait for clk_period/2;
        aclk <= '1';
        wait for clk_period/2;
    end process;

    -- Global reset & enable process
    global_proc: process
    begin
        aresetn <= '0';
        enable_filter <= '1';
        wait for 50 ns;
        
        aresetn <= '1';
        wait for 400 ns;
        
        enable_filter <= '0';
        wait for 100 ns;
        
        enable_filter <= '1';
        wait;
    end process;

    -- Stimulus for REF (moving_average)
    -- Questo processo fornisce gli ingressi per la reference rispettando i suoi ritardi.
    stim_proc_ref: process
        procedure send_sample(data_L : integer; data_R : integer) is
        begin
            ref_s_axis_tvalid <= '1'; 
            ref_s_axis_tdata <= std_logic_vector(to_signed(data_L, CHANNEL_LENGHT)); 
            ref_s_axis_tlast <= '0';
            wait until rising_edge(aclk) and ref_s_axis_tready = '1';
            
            ref_s_axis_tvalid <= '1'; 
            ref_s_axis_tdata <= std_logic_vector(to_signed(data_R, CHANNEL_LENGHT)); 
            ref_s_axis_tlast <= '1';
            wait until rising_edge(aclk) and ref_s_axis_tready = '1';
            
            ref_s_axis_tvalid <= '0';
        end procedure;
    begin
        wait until aresetn = '1';
        wait for 20 ns;
        for i in 0 to 35 loop
            send_sample(32, 64);
            wait for clk_period * 2;
        end loop;
        
        wait until enable_filter = '0';
        wait for clk_period * 2;
        send_sample(10, -20);
        wait for clk_period * 2;
        send_sample(15, -25);
        
        wait until enable_filter = '1';
        wait for clk_period * 5;
        for i in 0 to 45 loop
            send_sample(100, -100);
            wait for clk_period;
        end loop;
        wait;
    end process;

    -- Stimulus for DUT (moving_average_1)
    -- Questo processo fornisce gli stessi identici ingressi per il DUT, ma in parallelo
    -- rispettando i tready specifici della variante 1 (probabilmente molto più rapida).
    stim_proc_dut: process
        procedure send_sample(data_L : integer; data_R : integer) is
        begin
            dut_s_axis_tvalid <= '1'; 
            dut_s_axis_tdata <= std_logic_vector(to_signed(data_L, CHANNEL_LENGHT)); 
            dut_s_axis_tlast <= '0';
            wait until rising_edge(aclk) and dut_s_axis_tready = '1';
            
            dut_s_axis_tvalid <= '1'; 
            dut_s_axis_tdata <= std_logic_vector(to_signed(data_R, CHANNEL_LENGHT)); 
            dut_s_axis_tlast <= '1';
            wait until rising_edge(aclk) and dut_s_axis_tready = '1';
            
            dut_s_axis_tvalid <= '0';
        end procedure;
    begin
        wait until aresetn = '1';
        wait for 20 ns;
        for i in 0 to 35 loop
            send_sample(32, 64);
            wait for clk_period * 2;
        end loop;
        
        wait until enable_filter = '0';
        wait for clk_period * 2;
        send_sample(10, -20);
        wait for clk_period * 2;
        send_sample(15, -25);
        
        wait until enable_filter = '1';
        wait for clk_period * 5;
        for i in 0 to 45 loop
            send_sample(100, -100);
            wait for clk_period;
        end loop;
        wait for 500 ns;
        
        assert false report "Simulazione completata con successo" severity failure;
    end process;

    -- Master receiver process (Backpressure)
    rcv_proc: process
    begin
        m_axis_tready <= '1';
        wait for 300 ns;
        
        -- Test backpressure: Abbassiamo il tready e vediamo se il valid / dati non vengono persi
        m_axis_tready <= '0';
        wait for 50 ns;
        
        m_axis_tready <= '1';
        wait;
    end process;

end Behavioral;