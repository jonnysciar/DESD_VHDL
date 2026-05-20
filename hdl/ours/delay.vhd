---------------------------------------------------------------------------------- 
-- Module Name: Delay
-- Revision:
-- Revision 0.1 - File Created
-- 
----------------------------------------------------------------------------------

entity delay is
    generic(
        CHANNEL_LENGHT  : integer;
        DELAY_LENGHT    : integer;
        DELAY_INIT      : integer;
        LOG2_DELAY_INCR : integer
    );
    Port (
        
        aclk			: in std_logic;
        aresetn			: in std_logic;
        
        delay_in        : in std_logic_vector(DELAY_LENGHT-1 downto 0);

        data_in	        : in std_logic_vector(CHANNEL_LENGHT-1 downto 0);
        data_in_valid	: in std_logic;

        data_out	    : out std_logic_vector(CHANNEL_LENGHT-1 downto 0)
    );
end delay;

architecture Behavioral of delay is

begin

end Behavioral;