library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity led_level_controller is
    generic(
        NUM_LEDS : positive := 16;
        CHANNEL_LENGHT  : positive := 24;   -- 3 Byte for AXIS audio I2S
        refresh_time_ms : positive := 1;    -- refresh the LEDS every refresh_time_ms
        clock_period_ns : positive := 10    -- base time
    );
    Port (
        
        aclk			: in std_logic;
        aresetn			: in std_logic;
        
        led    : out std_logic_vector(NUM_LEDS-1 downto 0);

        s_axis_tvalid	: in std_logic;
        s_axis_tdata	: in std_logic_vector(CHANNEL_LENGHT-1 downto 0);
        s_axis_tlast    : in std_logic;
        s_axis_tready	: out std_logic

    );
end led_level_controller;

architecture Behavioral of led_level_controller is
    
    type state_type is (IDLE, SAMPLE_LEFT, SAMPLE_RIGHT, UPDATE_LEDS);
    signal state : state_type := IDLE;

    -- Timer for refresh rate control
    signal timer            : natural := 0;
    constant TIMER_MAX      : natural := refresh_time_ms * 1_000_000 / clock_period_ns; -- Convert ms to number of clock cycles

    -- CHANNEL_LENGHT + 1 width to account for possible overflow
    signal tmp_sum          : signed(CHANNEL_LENGHT downto 0) := (others => '0');
    signal tmp_led          : std_logic_vector(NUM_LEDS-1 downto 0) := (others => '0');
begin

    -- Drive tready always high, mirroring provided module
    s_axis_tready <= '1';

    led <= tmp_led;

    process(aclk, aresetn)
        variable var_found      : boolean;
        variable var_magnitude  : unsigned(CHANNEL_LENGHT downto 0);
        variable var_leds       : std_logic_vector(NUM_LEDS-1 downto 0);
    begin
        if aresetn = '0' then
            state <= IDLE;
            timer <= 0;
            -- led <= (others => '0');

        elsif rising_edge(aclk) then
            case state is

                -- Wait refresh
                when IDLE =>
                    if timer = TIMER_MAX - 1 then
                        timer <= 0;
                        state <= SAMPLE_LEFT;
                    else
                        timer <= timer + 1;
                    end if;

                when SAMPLE_LEFT =>
                    if (s_axis_tvalid = '1' and s_axis_tlast = '0') then
                        -- Sample left channel data
                        tmp_sum <= resize(signed(s_axis_tdata), CHANNEL_LENGHT + 1);
                        state <= SAMPLE_RIGHT;
                    end if;

                when SAMPLE_RIGHT =>
                    if (s_axis_tvalid = '1' and s_axis_tlast = '1') then
                        -- Sample right channel data
                        tmp_sum <= tmp_sum + resize(signed(s_axis_tdata), CHANNEL_LENGHT + 1);
                        state <= UPDATE_LEDS;
                    end if;

                when UPDATE_LEDS =>

                    -- Prevent abs() overflow on max negative by clamping, otherwise extract magnitude
                    if tmp_sum = to_signed(-2**CHANNEL_LENGHT, CHANNEL_LENGHT+1) then
                        var_magnitude := to_unsigned(2**CHANNEL_LENGHT - 1, CHANNEL_LENGHT+1);
                    elsif tmp_sum < 0 then
                        var_magnitude := unsigned(-tmp_sum);
                    else
                        var_magnitude := unsigned(tmp_sum);
                    end if;

                    -- Average the two channels (divide by 2)
                    var_magnitude := shift_right(var_magnitude, 1);

                    -- Select only the MSB (performs averaging + resizing)
                    var_leds  := std_logic_vector(var_magnitude(CHANNEL_LENGHT - 1 downto CHANNEL_LENGHT - NUM_LEDS));
                    var_found := false;
                    
                    -- Clear out led value
                    tmp_led <= (others => '0');

                    -- Scan the vector for the first '1', then turn all subsequent '1's to '0's
                    for i in NUM_LEDS-1 downto 0 loop
                        if var_leds(i) = '1' and not var_found then
                            tmp_led(i) <= '1';
                            var_found := true;
                        elsif var_found then
                            tmp_led(i) <= '1';
                        end if;
                    end loop;
                    
                    state <= IDLE;

            end case;
            
        end if;
    end process; 
end Behavioral;
