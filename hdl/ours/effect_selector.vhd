----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04.05.2026 10:52:21
-- Design Name: 
-- Module Name: effect_selector - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


entity effect_selector is

        Port (
            
          -------------- IN_PORTS -------------------------------
            clk : in std_logic;
            resetn : in std_logic;
            effect : in std_logic;
            jstk_X : in std_logic_vector (9 downto 0);
            jstk_y : in std_logic_vector (9 downto 0);
          --------------------------------------------------------
            
          -------------- OUT_PORTS ------------------------------- 
            volume : out std_logic_vector (9 downto 0);
            balance : out std_logic_vector (9 downto 0);
            gain : out std_logic_vector (9 downto 0);
            delay : out std_logic_vector (9 downto 0)
          -------------------------------------------------------- 
            
        );
end effect_selector;

architecture Behavioral of effect_selector is

begin

        effect_selector_process : process (clk, resetn, effect)
        begin
        
            if resetn = '0' then
            
                gain <= (others => '0');
                delay <= (others => '0');
                balance <= (others => '0');
                volume <= (others => '0');
                
            elsif rising_edge(clk) then
                
                case (effect) is
                
                    when '1' =>
                        gain <= jstk_X;
                        delay <= jstk_y;
                    when '0' =>
                        balance <= jstk_X;
                        volume <= jstk_y;
                        
                end case;
                
            end if;
        
        end process;

end Behavioral;
