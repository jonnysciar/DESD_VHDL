---------- DEFAULT LIBRARY ---------
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.ALL;
------------------------------------

entity KittCar is
	Generic (

		CLK_PERIOD_NS			:	POSITIVE	RANGE	1	TO	100     := 10;	-- clk period in nanoseconds
		MIN_KITT_CAR_STEP_MS	:	POSITIVE	RANGE	1	TO	2000    := 1;	-- Minimum step period in milliseconds (i.e., value in milliseconds of Delta_t)

		NUM_OF_SWS		:	INTEGER	RANGE	1 TO 16 := 16;	-- Number of input switches
		NUM_OF_LEDS		:	INTEGER	RANGE	1 TO 16 := 16	-- Number of output LEDs

	);
	Port (

		------- Reset/Clock --------
		reset	:	IN	STD_LOGIC;
		clk		:	IN	STD_LOGIC;
		----------------------------

		-------- LEDs/SWs ----------
		sw		:	IN	STD_LOGIC_VECTOR(NUM_OF_SWS-1 downto 0);	-- Switches avaiable on Basys3
		leds	:	OUT	STD_LOGIC_VECTOR(NUM_OF_LEDS-1 downto 0)	-- LEDs avaiable on Basys3
		----------------------------

	);
end KittCar;

architecture Behavioral of KittCar is
    constant DIRECTION_INIT : STD_LOGIC := '0';
    constant LEDS_INIT : UNSIGNED(NUM_OF_LEDS-1 downto 0) := TO_UNSIGNED(2**(NUM_OF_LEDS - 1), NUM_OF_LEDS);
    constant LEDS_LL : INTEGER := 2**(NUM_OF_LEDS - 1);
    constant LEDS_RL : INTEGER := 1;
    
    signal leds_value : UNSIGNED(NUM_OF_LEDS-1 downto 0) := LEDS_INIT;
    signal direction : STD_LOGIC := DIRECTION_INIT;
    signal counter : INTEGER := 0;

    begin
        process(clk, reset)
        begin
            if reset = '1' then
                leds_value <= LEDS_INIT;
                direction <= DIRECTION_INIT;
                counter <= 0;
                leds <= STD_LOGIC_VECTOR(leds_value);
            elsif rising_edge(clk) then
                counter <= counter + 1;
                if leds_value = TO_UNSIGNED(LEDS_LL, NUM_OF_LEDS) then
                    direction <= '0';
                elsif leds_value = TO_UNSIGNED(LEDS_RL, NUM_OF_LEDS) then
                    direction <= '1';    
                end if;
                if counter >= (MIN_KITT_CAR_STEP_MS * 2**TO_INTEGER(UNSIGNED(sw)) * 1_000_000) / CLK_PERIOD_NS then
                    counter <= 0;
                    if direction = '1' then
                        leds_value <= shift_left(leds_value, 1);
                    else
                        leds_value <= shift_right(leds_value, 1);
                    end if;
                    
                    leds <= STD_LOGIC_VECTOR(leds_value);
                end if;
            end if;     
        end process;
end Behavioral;

