library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity led_level_controller_tb is
end entity led_level_controller_tb;

architecture rtl of led_level_controller_tb is

	component led_level_controller is
		generic(
			NUM_LEDS : positive := 16;
			CHANNEL_LENGHT  : positive := 24;
			refresh_time_ms : positive := 1;
			clock_period_ns : positive := 10
		);
		port (
			aclk 	: in  std_logic;
			aresetn : in  std_logic;
			led 	: out std_logic_vector(NUM_LEDS-1 downto 0);
			s_axis_tvalid 	: in  std_logic;
			s_axis_tdata 	: in  std_logic_vector(CHANNEL_LENGHT-1 downto 0);
			s_axis_tlast 	: in  std_logic;
			s_axis_tready 	: out std_logic
		);
	end component;

	component led_level_controller_1 is
		generic(
			NUM_LEDS : positive := 16;	
			CHANNEL_LENGHT	: positive	:= 24;
			refresh_time_ms	: positive	:= 1;
			clock_period_ns : positive	:= 10
		);
		port(
			aclk	: in  std_logic;
			aresetn	: in  std_logic;
			led		: out std_logic_vector(NUM_LEDS-1 downto 0);
			s_axis_tvalid	: in  std_logic;
			s_axis_tdata	: in  std_logic_vector(CHANNEL_LENGHT-1 downto 0);
			s_axis_tlast	: in  std_logic;
			s_axis_tready	: out std_logic
		);
	end component;

	-- Common generics
	constant NUM_LEDS : positive := 16;
	constant CHANNEL_LENGHT : positive := 24;
	constant refresh_time_ms : positive := 1;
	constant clock_period_ns : positive := 10;
	constant CLK_PERIOD		 : time := 10 ns;

	-- Common inputs
	signal aclk : std_logic := '0';
	signal aresetn : std_logic := '0';
    
	signal s_axis_tvalid : std_logic := '0';
	signal s_axis_tdata : std_logic_vector(CHANNEL_LENGHT-1 downto 0) := (others => '0');
	
	-- Reference DUT (DUT1) signals
	signal s_axis_tready_ref : std_logic;
	signal s_axis_tlast_ref  : std_logic := '0';
	signal led_ref		 	 : std_logic_vector(NUM_LEDS-1 downto 0);

	-- My own implementation (DUT2) signals
	signal s_axis_tready_1	: std_logic;
	signal s_axis_tlast_1 	: std_logic := '0';
	signal led_1			: std_logic_vector(NUM_LEDS-1 downto 0);

begin

	-- Clock generation
    clk_process: process
    begin
        aclk <= '0';
        wait for CLK_PERIOD/2;
        aclk <= '1';
        wait for CLK_PERIOD/2;
    end process;

	ref: led_level_controller
	generic map(
		NUM_LEDS => NUM_LEDS,
		CHANNEL_LENGHT => CHANNEL_LENGHT,
		refresh_time_ms => 1,
		clock_period_ns => 10
	)
	port map(
		aclk => aclk,
		aresetn => aresetn,
		led => led_ref,
		s_axis_tvalid => s_axis_tvalid,
		s_axis_tdata => s_axis_tdata,
		s_axis_tlast => s_axis_tlast_ref,
		s_axis_tready => s_axis_tready_ref
	);

	dut: led_level_controller_1
	generic map(
		NUM_LEDS => NUM_LEDS,
		CHANNEL_LENGHT => CHANNEL_LENGHT,
		refresh_time_ms => 1,
		clock_period_ns => 10
	)
	port map(
		aclk => aclk,
		aresetn => aresetn,
		led => led_1,
		s_axis_tvalid => s_axis_tvalid,
		s_axis_tdata => s_axis_tdata,
		s_axis_tlast => s_axis_tlast_1,
		s_axis_tready => s_axis_tready_1
	);

	-- Left/Right channel
	lr: process
	begin
		wait until rising_edge(aclk);
		-- If the handshake is performed
		if s_axis_tready_ref = '1' then
			s_axis_tlast_ref <= not s_axis_tlast_ref;
		end if;

		if s_axis_tready_1 = '1' then
			s_axis_tlast_1 <= not s_axis_tlast_1;
		end if;
	end process;
	
	-- Testbench routine
	stimulus : process
	begin
		-- Reset sequence
        wait for 20 ns;
		aresetn <= '1';

		-- Always high
		s_axis_tvalid <= '1';

		-- Rotate through the tests
		-- for i in test_vec'range loop
		-- 	s_axis_tdata <= test_vec(i);
		-- 	wait for 1.5 ms;
		-- end loop;

		s_axis_tdata <= std_logic_vector(to_unsigned(2**8, CHANNEL_LENGHT));
		wait for 1.5 ms;

		s_axis_tdata <= std_logic_vector(to_unsigned(0, CHANNEL_LENGHT));	
		wait for 0.2 ms;

		s_axis_tdata <= std_logic_vector(to_unsigned(2**8 - 1, CHANNEL_LENGHT));	
		wait for 1.5 ms;

		s_axis_tdata <= std_logic_vector(to_unsigned(0, CHANNEL_LENGHT));	
		wait for 0.2 ms;

		s_axis_tdata <= std_logic_vector(to_unsigned(2**8 + 1, CHANNEL_LENGHT));	
		wait for 1.5 ms;

		s_axis_tdata <= std_logic_vector(to_unsigned(2**9, CHANNEL_LENGHT));	
		wait for 0.2 ms;

		-- Total: 9ms
	end process;
end architecture rtl;
