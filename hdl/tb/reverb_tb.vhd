library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity reverb_tb is
end entity reverb_tb;

architecture rtl of reverb_tb is

    component reverb is
    generic(
        LOG2_DELAY_INCR : integer :=1;              -- CONSTANT DO NOT TOUCH
        CHANNEL_LENGHT  : integer := 24;            -- 3 byte for audio
        DELAY_LENGHT  : integer := 10;              -- JSTK axis dimension
        DELAY_INIT : integer := 882;                -- 20 ms                    INIT VALUE  DO NOT TOUCH
        GAIN_LENGHT : integer := 10;                -- JSTK axis dimension
        GAIN_INIT_FRAC : integer := 614;            --614/(2^10) ~= 0.6         INIT VALUE  DO NOT TOUCH
        HIGHER_BOUND	: integer := 2**23-1;	    -- Inclusive (max value of TDATA at 24 bit signed)
        LOWER_BOUND		: integer := -2**23		    -- Inclusive (min value of TDATA at 24 bit signed)
    );
    Port (
            aclk			: in std_logic;
            aresetn			: in std_logic;
            
            enable_reverb   : in std_logic;

            delay_in        : in std_logic_vector(DELAY_LENGHT-1 downto 0);

            gain_in         : in std_logic_vector(GAIN_LENGHT-1 downto 0);
    
            s_axis_tvalid	: in std_logic;
            s_axis_tdata	: in std_logic_vector(CHANNEL_LENGHT-1 downto 0);
            s_axis_tlast    : in std_logic;
            s_axis_tready	: out std_logic;
    
            m_axis_tvalid	: out std_logic;
            m_axis_tdata	: out std_logic_vector(CHANNEL_LENGHT-1 downto 0);
            m_axis_tlast	: out std_logic;
            m_axis_tready	: in std_logic
        );
    end component;

    component reverb_1 is
    generic(
        LOG2_DELAY_INCR : integer :=1;              -- CONSTANT DO NOT TOUCH
        CHANNEL_LENGHT  : integer := 24;            -- 3 byte for audio
        DELAY_LENGHT  : integer := 10;              -- JSTK axis dimension
        DELAY_INIT : integer := 882;                -- 20 ms                    INIT VALUE  DO NOT TOUCH
        GAIN_LENGHT : integer := 10;                -- JSTK axis dimension
        GAIN_INIT_FRAC : integer := 614;            --614/(2^10) ~= 0.6         INIT VALUE  DO NOT TOUCH
        HIGHER_BOUND	: integer := 2**23-1;	    -- Inclusive (max value of TDATA at 24 bit signed)
        LOWER_BOUND		: integer := -2**23		    -- Inclusive (min value of TDATA at 24 bit signed)
    );
    Port (
            aclk			: in std_logic;
            aresetn			: in std_logic;
            
            enable_reverb   : in std_logic;

            delay_in        : in std_logic_vector(DELAY_LENGHT-1 downto 0);

            gain_in         : in std_logic_vector(GAIN_LENGHT-1 downto 0);
    
            s_axis_tvalid	: in std_logic;
            s_axis_tdata	: in std_logic_vector(CHANNEL_LENGHT-1 downto 0);
            s_axis_tlast    : in std_logic;
            s_axis_tready	: out std_logic;
    
            m_axis_tvalid	: out std_logic;
            m_axis_tdata	: out std_logic_vector(CHANNEL_LENGHT-1 downto 0);
            m_axis_tlast	: out std_logic;
            m_axis_tready	: in std_logic
        );
    end component;

    constant LOG2_DELAY_INCR : integer :=1;
    constant CHANNEL_LENGHT  : integer := 24;
    constant DELAY_LENGHT    : integer := 10;
    constant DELAY_INIT      : integer := 882;
    constant GAIN_LENGHT     : integer := 10;
    constant GAIN_INIT_FRAC  : integer := 614;
    constant HIGHER_BOUND	 : integer := 2**23-1;
    constant LOWER_BOUND	 : integer := -2**23;

    signal aclk   : std_logic := '0';
    signal aresetn : std_logic;

    signal enable_reverb : std_logic;
    signal delay_in      : std_logic_vector(DELAY_LENGHT-1 downto 0);
    signal gain_in       : std_logic_vector(GAIN_LENGHT-1 downto 0);

    signal s_axis_tvalid : std_logic := '0';
    signal s_axis_tdata	 : std_logic_vector(CHANNEL_LENGHT-1 downto 0);
    signal s_axis_tlast  : std_logic := '1';

    signal s_axis_tready_prof	: std_logic;
    signal s_axis_tready_our	: std_logic;
        
    signal m_axis_tvalid_prof : std_logic;
    signal m_axis_tdata_prof  : std_logic_vector(CHANNEL_LENGHT-1 downto 0);
    signal m_axis_tlast_prof  : std_logic;

    signal m_axis_tvalid_our  : std_logic;
    signal m_axis_tdata_our	  : std_logic_vector(CHANNEL_LENGHT-1 downto 0);
    signal m_axis_tlast_our   : std_logic;

    signal m_axis_tready	: std_logic;

begin
    reverb_inst: reverb
     generic map(
        LOG2_DELAY_INCR => LOG2_DELAY_INCR,
        CHANNEL_LENGHT => CHANNEL_LENGHT,
        DELAY_LENGHT => DELAY_LENGHT,
        DELAY_INIT => DELAY_INIT,
        GAIN_LENGHT => GAIN_LENGHT,
        GAIN_INIT_FRAC => GAIN_INIT_FRAC,
        HIGHER_BOUND => HIGHER_BOUND,
        LOWER_BOUND => LOWER_BOUND
    )
     port map(
            aclk => aclk,			
            aresetn => aresetn,			
            enable_reverb => enable_reverb,   
            delay_in => delay_in,        
            gain_in => gain_in,         
            s_axis_tvalid => s_axis_tvalid,	
            s_axis_tdata => s_axis_tdata,	
            s_axis_tlast => s_axis_tlast,    
            s_axis_tready => s_axis_tready_prof,	
            m_axis_tvalid => m_axis_tvalid_prof,	
            m_axis_tdata => m_axis_tdata_prof,	
            m_axis_tlast => m_axis_tlast_prof,	
            m_axis_tready => m_axis_tready

    );

    reverb_1_inst: reverb_1
     generic map(
        LOG2_DELAY_INCR => LOG2_DELAY_INCR,
        CHANNEL_LENGHT => CHANNEL_LENGHT,
        DELAY_LENGHT => DELAY_LENGHT,
        DELAY_INIT => DELAY_INIT,
        GAIN_LENGHT => GAIN_LENGHT,
        GAIN_INIT_FRAC => GAIN_INIT_FRAC,
        HIGHER_BOUND => HIGHER_BOUND,
        LOWER_BOUND => LOWER_BOUND
    )
     port map(
            aclk => aclk,			
            aresetn => aresetn,			
            enable_reverb => enable_reverb,   
            delay_in => delay_in,        
            gain_in => gain_in,         
            s_axis_tvalid => s_axis_tvalid,	
            s_axis_tdata => s_axis_tdata,	
            s_axis_tlast => s_axis_tlast,    
            s_axis_tready => s_axis_tready_our,	
            m_axis_tvalid => m_axis_tvalid_our,	
            m_axis_tdata => m_axis_tdata_our,	
            m_axis_tlast => m_axis_tlast_our,	
            m_axis_tready => m_axis_tready

    );

    aresetn<='1';
    aclk<= not aclk after 5 ns;
    m_axis_tready<='1';

    enable_reverb <= '1';
    delay_in <= std_logic_vector(to_unsigned(2**9, DELAY_LENGHT));
    gain_in <= std_logic_vector(to_unsigned(2**9, GAIN_LENGHT));

    s_axis_tlast <= not s_axis_tlast after 10 ns;
    
    process
    begin

        wait until rising_edge(aclk);
        s_axis_tvalid <= '1';
        s_axis_tdata <= std_logic_vector(to_unsigned(2**20, CHANNEL_LENGHT));

    end process;

end architecture;