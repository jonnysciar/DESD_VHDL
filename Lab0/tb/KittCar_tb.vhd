----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 03/20/2026 03:11:03 PM
-- Design Name: 
-- Module Name: KittCar_tb - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity KittCar_tb is
--  Port ( );
end KittCar_tb;

architecture Behavioral of KittCar_tb is

    -- I need constants/signals for the test bench (TB) and the device under test (DUT)

    -- Constants For Test Bench (TB)
    constant    CLK_PERIOD 	: time := 10 ns;
    -- constant    RESET_WND 	: time := 100 ns;
    -- constant    SIM_TIME 	: time := 1000 ns;

    -- Constants For DUT
    constant    NUM_OF_LEDS     :   INTEGER RANGE 1 TO 16   := 16;

    -- Device Under Test (DUT)
    Component KittCar
        Generic (
            CLK_PERIOD_NS          :   POSITIVE   RANGE   1   TO 100     := 10; -- clk period in nanoseconds
            MIN_KITT_CAR_STEP_MS   :   POSITIVE   RANGE   1   TO 2000    := 1;  -- Minimum step period in milliseconds (i.e., value in milliseconds of Delta_t)

            NUM_OF_SWS             :   INTEGER     RANGE   1 TO 16 := 16; -- Number of input switches
            NUM_OF_LEDS            :   INTEGER     RANGE   1 TO 16 := 16  -- Number of output LEDs

        );
        Port (
            reset   :   IN  STD_LOGIC;
            clk     :   IN  STD_LOGIC;
            sw      :   IN  STD_LOGIC_VECTOR(NUM_OF_SWS-1 downto 0);
            leds    :   OUT STD_LOGIC_VECTOR(NUM_OF_LEDS-1 downto 0)
        );
    end Component;

    -- signal TB
    signal  reset   :   STD_LOGIC := '0';
    signal  clk     :   STD_LOGIC := '1';
    
    signal  led_output :   STD_LOGIC_VECTOR(NUM_OF_LEDS-1 downto 0);

begin

    kitt_inst : KittCar
    Port Map (
        reset => reset,
        clk   => clk,
        sw    => (others => '0'),
        leds  => led_output
    );

    -- TB Clk Generation
    clk <= not clk after CLK_PERIOD/2;

    

end Behavioral;
