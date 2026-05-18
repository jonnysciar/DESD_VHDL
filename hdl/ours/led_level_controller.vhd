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
    signal tmp_sum          : unsigned(CHANNEL_LENGHT downto 0) := (others => '0');

begin

    -- Drive tready always high, mimicking provided module
    s_axis_tready <= '1';
    
    -- Maybe not necessary
    -- with led_count select led =>
    --    x"F" when 16;
    --    x"4" when 4;
    --    x"3" when 3;
    --    x"2" when 2;
    --    x"1" when 1;
    --    x"0" when 0;

    process(aclk, aresetn)
        variable var_found  : boolean;
        variable var_leds   : std_logic_vector(NUM_LEDS-1 downto 0); 
    begin
        if aresetn = '0' then
            state <= IDLE;
            timer <= 0;
            led <= (others => '0');

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
                    -- Note: zero-padding is used to solve width mismatch
                    if (s_axis_tvalid = '1' and s_axis_tlast = '0') then
                        -- Sample left channel data
                        tmp_sum <= '0' & unsigned(s_axis_tdata);
                        state <= SAMPLE_RIGHT;
                    end if;

                when SAMPLE_RIGHT =>
                    if (s_axis_tvalid = '1' and s_axis_tlast = '1') then
                        -- Sample right channel data
                        tmp_sum <= tmp_sum + ('0' & unsigned(s_axis_tdata));
                        state <= UPDATE_LEDS;
                    end if;

                when UPDATE_LEDS =>

                    -- Select only the MSB (performs averaging + resizing)
                    var_leds  := std_logic_vector(tmp_sum(CHANNEL_LENGHT downto CHANNEL_LENGHT - NUM_LEDS + 1));
                    var_found := false;
                    
                    -- Clear out led value
                    led <= (others => '0');

                    -- Scan the vector for the first '1', then turn all subsequent '1's to '0's
                    for i in NUM_LEDS-1 downto 0 loop
                        if var_leds(i) = '1' and not var_found then
                            led(i) <= '1';
                            var_found := true;
                        elsif var_found then
                            led(i) <= '1';
                        end if;
                    end loop;
                    
                    state <= IDLE;

            end case;
            
        end if;
    end process; 
    

end Behavioral;
