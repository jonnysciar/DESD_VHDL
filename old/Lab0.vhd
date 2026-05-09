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

    type state_type is (RIGHT, LEFT);
    signal state : state_type := RIGHT;

    -- Initialize with the rightmost LED on
    constant LEDS_INIT : std_logic_vector(NUM_OF_LEDS - 1 downto 0) := (0 => '1', others => '0');
    constant DIRECTION_INIT : state_type := RIGHT; 

    signal counter : INTEGER := 0;
    signal shift_en : std_logic := '0';

    -- Output value of the leds
    signal leds_value: std_logic_vector(NUM_OF_LEDS -1 DOWNTO 0) := (others => '0');

begin

    leds <= leds_value;

    clk_div: process(clk, reset)
    begin
        if reset = '1' then
            counter <= 0;
        elsif rising_edge(clk) then
            -- Convert MIN_KITT_CAR_STEP_MS in nanoseconds multiplying by 10^6
            if counter = (MIN_KITT_CAR_STEP_MS * 10**6) / CLK_PERIOD_NS then
                counter <= 0;
                shift_en <= '1';
            else
                counter <= counter + 1;
                shift_en <= '0';
            end if;
        end if;
    end process clk_div;

    kittcar: process(reset, clk)
    begin
        if reset = '1' then
            state <= DIRECTION_INIT;
            leds_value <= LEDS_INIT;
        elsif rising_edge(clk) then

            -- Execute only when shift_en is high
            -- Check out the clk_div process to see how shift_en is generated
            if shift_en = '1' then

                case state is
                    when RIGHT =>
                        if leds_value(0) = '1' then
                            state <= LEFT;
                        else
                            state <= RIGHT;
                            leds_value <= std_logic_vector(shift_right(unsigned(leds_value), 1));
                        end if;
                    when LEFT =>
                        if leds_value(NUM_OF_LEDS - 1) = '1' then
                            state <= RIGHT;
                        else
                            state <= LEFT;
                            leds_value <= std_logic_vector(shift_left(unsigned(leds_value), 1));
                        end if;
                end case;

            end if;

        end if;
    end process;

end Behavioral;
