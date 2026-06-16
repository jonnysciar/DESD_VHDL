library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity binary_to_decimal is
    port (
        clk : in std_logic;

        binary_num   : in  std_logic_vector(6 downto 0);
        decade_digit : out std_logic_vector(3 downto 0);
        unit_digit   : out std_logic_vector(3 downto 0)
    );
end entity;

architecture rtl of binary_to_decimal is
    
    type lut_type is array (0 to 127) of std_logic_vector(7 downto 0);

    function division_lut_inst return lut_type is
        variable lut : lut_type;
        variable decade  : integer;
        variable unit : integer;
    begin
        for i in 0 to 127 loop

            if i > 99 then
                decade  := 9;
                unit := 9;
            else
                decade  := i / 10;
                unit := i mod 10;
            end if;

            lut(i) := std_logic_vector(to_unsigned(decade,4)) & std_logic_vector(to_unsigned(unit,4));

        end loop;

        return lut;
    end function;

    constant lut_num2bin : lut_type := division_lut_inst;

begin

    process(clk)
        variable addr : integer range 0 to 127;
    begin
        if rising_edge(clk) then
            addr := to_integer(unsigned(binary_num));

            decade_digit <= lut_num2bin(addr)(7 downto 4);
            unit_digit   <= lut_num2bin(addr)(3 downto 0);
        end if;
    end process;

end architecture;