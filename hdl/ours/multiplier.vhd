library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity multiplier is
    Generic (
        DATA_WIDTH      : positive := 24;
        AMP_WIDTH       : positive := 5
    );
    Port (
        aresetn     : in std_logic;
        aclk        : in std_logic;
        
        in_data     : in std_logic_vector(DATA_WIDTH-1 downto 0);
        amp_factor  : in std_logic_vector(AMP_WIDTH-1 downto 0);
        
        out_data    : out std_logic_vector(DATA_WIDTH-1 downto 0)
    );
end multiplier;

architecture Behavioral of multiplier is
begin
    process(aclk, aresetn)
    begin
        if aresetn = '0' then
            out_data <= in_data;
        elsif rising_edge(aclk) then
            out_data <= std_logic_vector(shift_left(unsigned(in_data), to_integer(signed(amp_factor))));
        end if;
    end process;
end Behavioral;
