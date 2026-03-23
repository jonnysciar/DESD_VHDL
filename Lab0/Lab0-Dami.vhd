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

	constant max_leds_used : integer := 16;  --To modify the number of leds on which we run the KittCar effect

	signal state, next_state : state_type := S0;  --For the Finite State Machine
	signal leds_out : STD_LOGIC_VECTOR(NUM_OF_LEDS-1 downto 0);
	signal reset, clk : std_logic;
	signal direction : std_logic;            --If direction = 1 we are going rightward
											 --If direction = 0 we are going leftward
	
	
begin

	leds <= leds_out;

	Next_state_logic : process (state, direction)
		
		begin

			case (state) is

				when S0 =>
					if direction = 1 then
						next_state <= S1;
					else
						next_state <= S0 --is this correct?
					end if;

				when S1 =>
					if direction = 1 then
						next_state <= S2;
					else
						next_state <= S0;
					end if;

				when S2 =>
					if direction = 1 then
						next_state <= S3;
					else
						next_state <= S1;
					end if;

				when S3 =>
					if direction = 1 then
						next_state <= S4;
					else
						next_state <= S2;
					end if;

				when S4 =>
					if direction = 1 then
						next_state <= S5;
					else
						next_state <= S3;
					end if;

				when S5 =>
					if direction = 1 then
						next_state <= S6;
					else
						next_state <= S4;
					end if;

				when S6 =>
					if direction = 1 then
						next_state <= S7;
					else
						next_state <= S5;
					end if;

				when S7 =>
					if direction = 1 then
						next_state <= S8;
					else
						next_state <= S6;
					end if;

				when S8 =>
					if direction = 1 then
						next_state <= S9;
					else
						next_state <= S7;
					end if;

				when S9 =>
					if direction = 1 then
						next_state <= S10;
					else
						next_state <= S8;
					end if;

				when S10 =>
					if direction = 1 then
						next_state <= S11;
					else
						next_state <= S9;
					end if;

				when S11 =>
					if direction = 1 then
						next_state <= S12;
					else
						next_state <= S10;
					end if;

				when S12 =>
					if direction = 1 then
						next_state <= S13;
					else
						next_state <= S11;
					end if;

				when S13 =>
					if direction = 1 then
						next_state <= S14;
					else
						next_state <= S12;
					end if;

				when S14 =>
					if direction = 1 then
						next_state <= S15;
					else
						next_state <= S13;
					end if;

				when S15 =>
					if direction = 1 then
						next_state <= S15;  --Is this correct?
					else
						next_state <= S14;
					end if;

			end case;
			
		end process;

end Behavioral;
