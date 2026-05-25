library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

------------------------------- SPIEGAZIONE -------------------------------------------------
-- Ho scelto come tempo di refresh, vale a dire il lasso di tempo che passa tra la prima e
-- l'ultima cifra, 4ms cioè 4 volte mux_time_ms.
-- Da qui, per calcolare ogni quanti cicli di clock servono per poter passare da una cifra
-- alla successiva:
-- (mux_time_ms * 10^(-3))/(clock_period_ns * 10^(-9)) = 100_000.
-- Non potendo usare (o non volendo, onestamente non ho conntrollato se esistano) esponenti
-- negativi, il calcolo di sopra è equivalente a:
-- (mux_time_ms * 1_000_000_000)/(clock_period_ns * 1_000) = 100_000.
---------------------------------------------------------------------------------------------

entity driver_4_7seg is
    Generic(
    
        mux_time_ms: positive:=1;       -- multiplexin time between digit, switch to one digit to another every mux_time_ms
        clock_period_ns: positive :=10  -- time base
        
    );
    Port ( 
    
    	clk : in STD_LOGIC;
        resetn: in STD_LOGIC;
        num1, num2, num3, num4: in STD_LOGIC_VECTOR(3 downto 0);
        
        an: out STD_LOGIC_VECTOR(3 downto 0);
        seg: out STD_LOGIC_VECTOR(0 to 6);
        dp: out STD_LOGIC
        
        );
end driver_4_7seg;

architecture Behavioral of driver_4_7seg is

    signal num: std_logic_vector(3 downto 0);
    signal seg_s: STD_LOGIC_VECTOR(0 to 6);
    signal an_s : std_logic_vector(3 downto 0);
    
    type state_type is (RESET, DIG1, DIG2, DIG3, DIG4);
    signal device_state : state_type := RESET;
    signal delay_counter : integer range 0 to 4*((mux_time_ms * 1_000_000_000) / (clock_period_ns * 1_000))-1;

begin

    with num select seg_s <=
        "0000001" when "0000",
        "1001111" when "0001",
        "0010010" when "0010",
        "0000110" when "0011",
        "1001100" when "0100",
        "0100100" when "0101",
        "0100000" when "0110",
        "0001111" when "0111",
        "0000000" when "1000",
        "0000100" when "1001",
        "0001000" when "1010",
        "1100000" when "1011",
        "0110001" when "1100",
        "1000010" when "1101",
        "0110000" when "1110",
        "0111000" when "1111",
        "1111111" when others;

    
    multiplexing_screen : process (clk, resetn)
    
        variable tot_num_clk_cycles_div : integer := (mux_time_ms * 1_000_000_000) / (clock_period_ns * 1_000);
    begin
        
        if resetn = '0' then
            device_state <= RESET;
            
        elsif rising_edge(clk) then
                      
            case (device_state) is
            
                when RESET =>
                    num <= "0000";
                    an_s <= "1110";
                    delay_counter <= 0;
                    device_state <= DIG1;
                    
                when DIG1 =>
                    an_s <= "1110";
                    delay_counter <= delay_counter +1;
                    num <= num1;
                    if delay_counter = tot_num_clk_cycles_div - 1 then
                        device_state <= DIG2;
                    end if;
                    
                when DIG2 =>
                    an_s <= "1101";
                    delay_counter <= delay_counter +1;
                    num <= num2;
                    if delay_counter = tot_num_clk_cycles_div*2 - 1 then
                        device_state <= DIG3;
                    end if;
                    
                when DIG3 =>
                    an_s <= "1011";
                    delay_counter <= delay_counter +1;
                    num <= num3;
                    if delay_counter = tot_num_clk_cycles_div*3 - 1 then
                        device_state <= DIG4;
                    end if;
                    
                when DIG4 =>
                    an_s <= "0111";
                    delay_counter <= delay_counter +1;
                    num <= num4;
                    if delay_counter = tot_num_clk_cycles_div*4 - 1 then
                        device_state <= DIG1;
                        delay_counter <= 0;
                    end if;
                    
                when others =>
                    num <= "0000";
                    device_state <= RESET;
                    
            end case;
            
        end if;
    
    end process;
    
    an <= an_s;
    seg <= seg_s;
    
end Behavioral;
