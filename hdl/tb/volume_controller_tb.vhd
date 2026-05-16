library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity volume_controller_tb is
end entity volume_controller_tb;

architecture Behavioral of volume_controller_tb is

    component volume_controller_1 is
    	Generic (
		TDATA_WIDTH		: positive := 24;
		VOLUME_WIDTH	: positive := 10;
		VOLUME_STEP_2	: positive := 6;		-- i.e., volume_values_per_step = 2**VOLUME_STEP_2
		HIGHER_BOUND	: integer := 2**23-1;	-- Inclusive (max value of TDATA at 24 bit signed)
		LOWER_BOUND		: integer := -2**23		-- Inclusive (min value of TDATA at 24 bit signed)
	   );
	   Port (
		aclk			: in std_logic;
		aresetn			: in std_logic;

		s_axis_tvalid	: in std_logic;
		s_axis_tdata	: in std_logic_vector(TDATA_WIDTH-1 downto 0);
		s_axis_tlast	: in std_logic;
		s_axis_tready	: out std_logic;

		m_axis_tvalid	: out std_logic;
		m_axis_tdata	: out std_logic_vector(TDATA_WIDTH-1 downto 0);
		m_axis_tlast	: out std_logic;
		m_axis_tready	: in std_logic;

		volume			: in std_logic_vector(VOLUME_WIDTH-1 downto 0)
	   );
    end component;
    
    constant TDATA_WIDTH	: positive := 24;
    constant VOLUME_WIDTH	: positive := 10;
    constant VOLUME_STEP_2	: positive := 6;		-- i.e., volume_values_per_step = 2**VOLUME_STEP_2
    constant HIGHER_BOUND	: integer := 2**23-1;	-- Inclusive (max value of TDATA at 24 bit signed)
    constant LOWER_BOUND	: integer := -2**23;		-- Inclusive (min value of TDATA at 24 bit signed)
    
    constant VALUE : unsigned := to_unsigned(2**(VOLUME_WIDTH-1) - 1, VOLUME_WIDTH);
    
    signal aclk             : std_logic := '0';
    signal aresetn			: std_logic;

    signal s_axis_tvalid	: std_logic;
    signal s_axis_tdata	    : std_logic_vector(TDATA_WIDTH-1 downto 0);
    signal s_axis_tlast	    : std_logic;
    signal s_axis_tready	: std_logic;

    signal m_axis_tvalid	: std_logic;
    signal m_axis_tdata	    : std_logic_vector(TDATA_WIDTH-1 downto 0);
    signal m_axis_tlast	    : std_logic;
    signal m_axis_tready	: std_logic;

    signal  volume			: std_logic_vector(VOLUME_WIDTH-1 downto 0) := std_logic_vector(VALUE);
    
    signal counter : integer := 0;
    
begin

    aresetn <= '1';
    aclk <= not aclk after 5 ns;
    m_axis_tready <= '1';
    
    s_axis_tdata <= std_logic_vector(to_signed(LOWER_BOUND + 2048, s_axis_tdata'length));
    s_axis_tvalid <= '1';
    s_axis_tlast <= '0';
    
    volume_controller_inst: volume_controller_1
    generic map(
        TDATA_WIDTH	=> TDATA_WIDTH,
        VOLUME_WIDTH => VOLUME_WIDTH,
        VOLUME_STEP_2 => VOLUME_STEP_2,
        HIGHER_BOUND => HIGHER_BOUND,
        LOWER_BOUND => LOWER_BOUND
    )
    port map (
        aclk => aclk,
        aresetn	=> aresetn,
    
        s_axis_tvalid => s_axis_tvalid, 
        s_axis_tdata => s_axis_tdata, 
        s_axis_tlast => s_axis_tlast, 
        s_axis_tready => s_axis_tready, 
    
        m_axis_tvalid => m_axis_tvalid,
        m_axis_tdata => m_axis_tdata,
        m_axis_tlast => m_axis_tlast,
        m_axis_tready => m_axis_tready,
    
        volume => volume
    );
    
    
    
    process(aclk)
    begin
        if rising_edge(aclk) then
            volume <= std_logic_vector(unsigned(volume) - 1);
            if unsigned(volume) <= 0 then
                volume <= std_logic_vector(VALUE);
            end if;
        end if;
    end process;
    
end architecture;