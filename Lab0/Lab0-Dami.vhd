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

	type state_type is (S0, S1, S2, S3, S4, S5, S6, S7, S8, S9, S10, S11, S12, S13, S14, S15, RST); --One state for each led


	signal state, next_state : state_type := S0;  --For the Finite State Machine
	signal leds_out : STD_LOGIC_VECTOR(NUM_OF_LEDS-1 downto 0);
	signal reset_signal, clk_signal : std_logic;
	signal direction : std_logic;            --If direction = 1 we are going rightward
											 --If direction = 0 we are going leftward
begin

	leds <= leds_out;									--I still have to implement the switches and the speed of the blinking

	Next_state_logic : process (state, direction)       --To govern where should I go based on the value of "direction"
		begin

			case (state) is

				when RST =>					--Is this correct?
					if direction = '1' then
						next_state <= S0;
					else
						direction <= '1'; 
					end if;
				
				when S0 =>
					if direction = '1' then
						next_state <= S1;
					else
						direction <= '1';
						next_state <= S1;
					end if;

				when S1 =>
					if direction = '1' then
						next_state <= S2;
					else
						next_state <= S0;
					end if;

				when S2 =>
					if direction = '1' then
						next_state <= S3;
					else
						next_state <= S1;
					end if;

				when S3 =>
					if direction = '1' then
						next_state <= S4;
					else
						next_state <= S2;
					end if;

				when S4 =>
					if direction = '1' then
						next_state <= S5;
					else
						next_state <= S3;
					end if;

				when S5 =>
					if direction = '1' then
						next_state <= S6;
					else
						next_state <= S4;
					end if;

				when S6 =>
					if direction = '1' then
						next_state <= S7;
					else
						next_state <= S5;
					end if;

				when S7 =>
					if direction = '1' then
						next_state <= S8;
					else
						next_state <= S6;
					end if;

				when S8 =>
					if direction = '1' then
						next_state <= S9;
					else
						next_state <= S7;
					end if;

				when S9 =>
					if direction = '1' then
						next_state <= S10;
					else
						next_state <= S8;
					end if;

				when S10 =>
					if direction = '1' then
						next_state <= S11;
					else
						next_state <= S9;
					end if;

				when S11 =>
					if direction = '1' then
						next_state <= S12;
					else
						next_state <= S10;
					end if;

				when S12 =>
					if direction = '1' then
						next_state <= S13;
					else
						next_state <= S11;
					end if;

				when S13 =>
					if direction = '1' then
						next_state <= S14;
					else
						next_state <= S12;
					end if;

				when S14 =>
					if direction = '1' then
						next_state <= S15;
					else
						next_state <= S13;
					end if;

				when S15 =>
					next_state <= S14;  		  
					direction <= '0';

			end case;
			
		end process;

		Synchronous_logic : process(clk, reset)      --To actually go to the next state
		begin										 
			
			if reset = '1' then
				state <= RST;
			elsif rising_edge(clk) then
				state <= next_state;
			end if;
				
		end process;

		Output_logic : process(state)				--To govern the ouput
		begin

			case (state) is

				when S0 =>
					leds_out <= (NUM_OF_LEDS-1 => '1', others => '0');
				when S1 =>
					leds_out <= (NUM_OF_LEDS-2 => '1', others => '0');
				when S2 =>
					leds_out <= (NUM_OF_LEDS-3 => '1', others => '0');
				when S3 =>
					leds_out <= (NUM_OF_LEDS-4 => '1', others => '0');
				when S4 =>
					leds_out <= (NUM_OF_LEDS-5 => '1', others => '0');
				when S5 =>
					leds_out <= (NUM_OF_LEDS-6 => '1', others => '0');
				when S6 =>
					leds_out <= (NUM_OF_LEDS-7 => '1', others => '0');
				when S7 =>
					leds_out <= (NUM_OF_LEDS-8 => '1', others => '0');
				when S8 =>
					leds_out <= (NUM_OF_LEDS-9 => '1', others => '0');
				when S9 =>
					leds_out <= (NUM_OF_LEDS-10 => '1', others => '0');
				when S10 =>
					leds_out <= (NUM_OF_LEDS-11 => '1', others => '0');
				when S11 =>
					leds_out <= (NUM_OF_LEDS-12 => '1', others => '0');
				when S12 =>
					leds_out <= (NUM_OF_LEDS-13 => '1', others => '0');
				when S13 =>
					leds_out <= (NUM_OF_LEDS-14 => '1', others => '0');
				when S14 =>
					leds_out <= (NUM_OF_LEDS-15 => '1', others => '0');
				when S15 =>
					leds_out <= (NUM_OF_LEDS-16 => '1', others => '0');
				when RST =>
					leds_out <= (others => '0');
						
			end case;
			
		end process;

end Behavioral;
