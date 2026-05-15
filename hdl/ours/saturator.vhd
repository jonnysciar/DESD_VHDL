library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity saturator is
    Generic (
        DATA_WIDTH      : positive := 24;
        HIGHER_BOUND	: integer := 2**23-1;
        LOWER_BOUND		: integer := -2**23
    );
    Port (
        aresetn     : in std_logic;
        aclk        : in std_logic;
        
        orig_data   : in std_logic_vector(DATA_WIDTH-1 downto 0);
        amp_data    : in std_logic_vector(DATA_WIDTH-1 downto 0);
        
        out_data    : out std_logic_vector(DATA_WIDTH-1 downto 0)
    );
end saturator;

architecture Behavioral of saturator is
begin
    process(aclk, aresetn)
    begin
        if aresetn = '0' then
            out_data <= orig_data;
        elsif rising_edge(aclk) then
            -- Negative underflow
            if orig_data(orig_data'high) = '1' and amp_data(amp_data'high) = '0' then
                out_data <= std_logic_vector(to_signed(LOWER_BOUND, out_data'length));
            -- Positive overflow
            elsif orig_data(orig_data'high) = '0' and amp_data(amp_data'high) = '1' then
                out_data <= std_logic_vector(to_signed(HIGHER_BOUND, out_data'length));
            else
                out_data <= amp_data;
            end if;
        end if;
    end process;
end Behavioral;
