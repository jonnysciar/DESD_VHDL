library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


entity effect_selector is
        Generic(
            JOYSTICK_LENGHT  : integer := 10    -- 10 bit for X and Y axis
        );
        Port (
            
          -------------- IN_PORTS -------------------------------
            clk : in std_logic;
            resetn : in std_logic;
            effect : in std_logic;
            jstck_X : in std_logic_vector (JOYSTICK_LENGHT-1 downto 0);
            jstck_y : in std_logic_vector (JOYSTICK_LENGHT-1 downto 0);
          --------------------------------------------------------
            
          -------------- OUT_PORTS ------------------------------- 
            volume : out std_logic_vector (JOYSTICK_LENGHT-1 downto 0);
            balance : out std_logic_vector (JOYSTICK_LENGHT-1 downto 0);
            gain : out std_logic_vector (JOYSTICK_LENGHT-1 downto 0);
            delay : out std_logic_vector (JOYSTICK_LENGHT-1 downto 0)
          -------------------------------------------------------- 
            
        );
end effect_selector;

architecture Behavioral of effect_selector is

begin

        effect_selector_process : process (clk, resetn)
        begin
        
            if resetn = '0' then
            
                gain <= (others => '0');
                delay <= (others => '0');
                balance <= (others => '0');
                volume <= (others => '0');
                
            elsif rising_edge(clk) then
                
                case effect is
                    when '1' =>
                        gain <= jstck_X;
                        delay <= jstck_y;
                    when '0' =>
                        balance <= jstck_X;
                        volume <= jstck_y;         
                end case;
                
            end if;
        
        end process;

end Behavioral;
