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
			aclk : in std_logic;
			aresetn : in std_logic;
			led : out std_logic_vector(NUM_LEDS-1 downto 0);
			s_axis_tvalid : in std_logic;
			s_axis_tdata : in std_logic_vector(CHANNEL_LENGHT-1 downto 0);
			s_axis_tlast : in std_logic;
			s_axis_tready : out std_logic
		);
	end component;

	constant NUM_LEDS : positive := 16;
	constant CHANNEL_LENGHT : positive := 24;

	signal aclk : std_logic := '0';
	signal aresetn : std_logic := '0';
	signal led : std_logic_vector(NUM_LEDS-1 downto 0);
	signal s_axis_tvalid : std_logic := '0';
	signal s_axis_tdata : std_logic_vector(CHANNEL_LENGHT-1 downto 0) := (others => '0');
	signal s_axis_tlast : std_logic := '0';
	signal s_axis_tready : std_logic;

begin

	aclk <= not aclk after 5 ns;

	dut: led_level_controller
		generic map(
			NUM_LEDS => NUM_LEDS,
			CHANNEL_LENGHT => CHANNEL_LENGHT,
			refresh_time_ms => 1,
			clock_period_ns => 10
		)
		port map(
			aclk => aclk,
			aresetn => aresetn,
			led => led,
			s_axis_tvalid => s_axis_tvalid,
			s_axis_tdata => s_axis_tdata,
			s_axis_tlast => s_axis_tlast,
			s_axis_tready => s_axis_tready
		);

	stimulus : process
	begin
		wait for 20 ns;
		aresetn <= '1';

		wait until rising_edge(aclk);
		s_axis_tvalid <= '1';
		s_axis_tlast <= '0';
		s_axis_tdata <= std_logic_vector(to_signed(1024, CHANNEL_LENGHT));
		wait until rising_edge(aclk);
		s_axis_tlast <= '1';
		s_axis_tdata <= std_logic_vector(to_signed(2048, CHANNEL_LENGHT));
		wait until rising_edge(aclk);
		s_axis_tvalid <= '0';

		wait for 200 ns;
		wait;
	end process;

end architecture rtl;
