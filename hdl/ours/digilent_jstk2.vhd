library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity digilent_jstk2 is
	generic (
		DELAY_US		: integer := 25;			-- CONSTANT DO NOT TOUCH
		CLKFREQ		 	: integer := 100_000_000;	-- Base time
		SPI_SCLKFREQ 	: integer := 66_666			-- Base time
	);
	Port ( 
		aclk 			: in  STD_LOGIC;
		aresetn			: in  STD_LOGIC;

		-- Master AXI4-Stream interface (to send data to the joystick)
		m_axis_tvalid	: out STD_LOGIC;
		m_axis_tdata	: out STD_LOGIC_VECTOR(7 downto 0);
		m_axis_tready	: in STD_LOGIC;

		-- Slave AXI4-Stream interface (to receive data from the joystick)
		s_axis_tvalid	: in STD_LOGIC;
		s_axis_tdata	: in STD_LOGIC_VECTOR(7 downto 0);

		-- To Effect Selector
		jstk_x			: out std_logic_vector(9 downto 0);
		jstk_y			: out std_logic_vector(9 downto 0);
		btn_trigger		: out std_logic;
		-- To Edge Detector
		btn_jstk		: out std_logic;
		
		-- From Output Selector
		led_r			: in std_logic_vector(7 downto 0);
		led_g			: in std_logic_vector(7 downto 0);
		led_b			: in std_logic_vector(7 downto 0)
	);
end digilent_jstk2;

architecture Behavioral of digilent_jstk2 is

	constant CMDSETLEDRGB		: std_logic_vector(7 downto 0) := x"84";

	-- CHIEDI AI PROF:
	-- perchè solo 1 byte?
	-- Inter-packet delay plus the time needed to transfer 1 byte (for the CS de-assertion)
	-- constant DELAY_CYCLES		: integer := DELAY_US * (CLKFREQ / 1_000_000) + CLKFREQ / SPI_SCLKFREQ;

	type tx_state_t is (WAIT_DELAY, SEND_HEADER, SEND_RED, SEND_GREEN, SEND_BLUE, SEND_DUMMY);
	signal tx_state 		: tx_state_t := WAIT_DELAY;

	-- Temporary signals to hold the data before it is sent on the AXI stream
	signal jstk_x_reg			: std_logic_vector(9 downto 0);
	signal jstk_y_reg			: std_logic_vector(9 downto 0);
	
	-- Calculate delay: (25us delay) + (time to send 5 bytes) at CLKFREQ
	constant DELAY_CYCLES 		: integer := (CLKFREQ / 1_000_000) * DELAY_US + ((CLKFREQ / SPI_SCLKFREQ)*5);
	signal delay_counter 		: integer range 0 to DELAY_CYCLES := 0;

	------------------------------------------------------------------------------

	type rx_state_t  is (GET_X_LOW, GET_X_HIGH, GET_Y_LOW, GET_Y_HIGH, GET_BTNS);
	signal rx_state  		: rx_state_t := GET_X_LOW;

	-- LED registered values
	signal led_r_reg		: std_logic_vector(7 downto 0);
	signal led_g_reg		: std_logic_vector(7 downto 0);
	signal led_b_reg		: std_logic_vector(7 downto 0);


begin
	-----------------------------------------------------------------------------------------
	-- IP to SPI: Send LED values to the joystick based on the input from the output selector
	-----------------------------------------------------------------------------------------

	-- Set m_axis tvalid based on the current tx state
	with tx_state select m_axis_tvalid <=
		'0'	when WAIT_DELAY,
		'1'	when SEND_HEADER,
		'1'	when SEND_RED,
		'1'	when SEND_GREEN,
		'1'	when SEND_BLUE,
		'1'	when SEND_DUMMY;
	
	m_axis: process(aclk, aresetn)
	begin
		if aresetn = '0' then
			tx_state			<= WAIT_DELAY;
			delay_counter		<= 0;

		elsif rising_edge(aclk) then
			case (tx_state) is
			    when WAIT_DELAY =>
					-- Count the delay cycles before starting the next transaction
					if delay_counter = (DELAY_CYCLES - 1) then
						delay_counter <= 0;
						tx_state <= SEND_HEADER;
					else
						delay_counter <= delay_counter + 1;
					end if;

				when SEND_HEADER =>
					if m_axis_tready = '1' then
						m_axis_tdata	<= CMDSETLEDRGB;	-- Header byte for cmdSetLEDs
						-- Register the inputs here so they are stable for the entire cmdSetLEDs transaction
						led_r_reg		<= led_r;
						led_g_reg		<= led_g;
						led_b_reg		<= led_b;
						tx_state <= SEND_RED;
					end if;

				when SEND_RED =>
					if m_axis_tready = '1' then
						m_axis_tdata	<= led_r_reg;
						tx_state <= SEND_GREEN;
					end if;

				when SEND_GREEN =>
					if m_axis_tready = '1' then
						m_axis_tdata	<= led_g_reg;
						tx_state <= SEND_BLUE;
					end if;

				when SEND_BLUE =>
					if m_axis_tready = '1' then
						m_axis_tdata	<= led_b_reg;
						tx_state <= SEND_DUMMY;
					end if;

				when SEND_DUMMY =>
					if m_axis_tready = '1' then
						m_axis_tdata	<= x"00";		-- Dummy byte
						tx_state <= WAIT_DELAY;			-- Go back to delay state
					end if;
			end case;

		end if;
	end process;

	------------------------------------------------------------------------------------
	-- SPI to IP: Receive joystick data and send it to effect selector and edge detector
	------------------------------------------------------------------------------------

	-- We don't have a tready signal on the slave side since we always accept data

	s_axis: process(aclk, aresetn)
	begin
		if aresetn = '0' then	
			-- Set the state to the beginning of the transaction
			rx_state		<= GET_X_LOW;
		
		elsif rising_edge(aclk) then
			-- If the input data is valid... (we will always accept it since there is no tready)
			if s_axis_tvalid = '1' then

				case (rx_state) is
					when GET_X_LOW =>
						jstk_x_reg(7 downto 0) 	<= s_axis_tdata;
						rx_state 				<= GET_X_HIGH;
					when GET_X_HIGH =>
						jstk_x_reg(9 downto 8) 	<= s_axis_tdata(1 downto 0);
						-- Update the output for jstk_x after receiving the complete info
						jstk_x					<= jstk_x_reg; 	
						rx_state 				<= GET_Y_LOW;
					when GET_Y_LOW =>
						jstk_y_reg(7 downto 0) 	<= s_axis_tdata;
						rx_state 				<= GET_Y_HIGH;
					when GET_Y_HIGH =>
						jstk_y_reg(9 downto 8) 	<= s_axis_tdata(1 downto 0);
						-- Update the output for jstk_y after receiving the complete info
						jstk_y					<= jstk_y_reg; 	
						rx_state 				<= GET_BTNS;
					when GET_BTNS =>
						-- Sort FS Status into the appropriate output signals
						-- Cross-reference with the joystick's datasheet
						btn_jstk				<= s_axis_tdata(0);
						btn_trigger				<= s_axis_tdata(1);
						-- Go back to the beginning of the transaction for the next set of data
						rx_state 				<= GET_X_LOW;
				end case;
			end if;
		end if;
	end process;

end Behavioral;
