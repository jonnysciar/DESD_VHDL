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
    constant LED_POS_INIT : INTEGER := 0;

    signal direction : STD_LOGIC := DIRECTION_INIT;
    signal led_pos : INTEGER := LED_POS_INIT;
    signal counter : INTEGER := 0;
    signal val : std_logic := '0';
begin
    kittcar: process(reset, clk) is
    begin
        if reset = '1' then
            direction <= DIRECTION_INIT;
            led_pos <= LED_POS_INIT;
        end if;
        
        if rising_edge(clk) then
            counter <= counter + 1;
            if counter = 100000000 then
                counter <= 0;
                val <= not val; 
                leds(0) <= val;
            end if;
        end if;
    end process kittcar;
end Behavioral;

--architecture Behavioral of KittCar is
    
--    type state_type is (RIGHT, LEFT);
--    signal state : state_type := RIGHT;
--    signal leds_value: std_logic_vector(NUM_OF_LEDS -1 TO 0):= (others => '0');  -- value of the leds
    
--begin
--            process(clk, reset)
--            begin
--                if reset = '1' then
--                    -- asynchronous reset
--                    leds_value <= (others => '0');
--                    state <= RIGHT;
--                elsif rising_edge(clk) then
--                    case state is
--                        when RIGHT =>
--                            if unsigned(leds_value) = to_unsigned(1, NUM_OF_LEDS) then
--                                state <= LEFT;
--                            else
--                                leds_value <= std_logic_vector(shift_right(unsigned(leds_value), 1));
--                                state <= RIGHT; 
--                            end if; 
--                        when LEFT =>
--                            if unsigned(leds_value) = to_unsigned(2**(NUM_OF_LEDS - 1), NUM_OF_LEDS) then
--                                state <= RIGHT;
--                            else
--                                leds_value <= std_logic_vector(shift_left(unsigned(leds_value), 1));
--                                state <= LEFT;
--                            end if;            
--                    end case;
--                end if;
--                leds <= leds_value;       
--end process;

--end Behavioral;

