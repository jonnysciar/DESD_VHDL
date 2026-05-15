library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity volume_controller_1 is
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
end volume_controller_1;

architecture Behavioral of volume_controller_1 is

    component multiplier is
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
    end component;

    component saturator is
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
    end component;

    signal s_axis_tready_int	: std_logic := '0';
    signal amp_data    		    : std_logic_vector(TDATA_WIDTH-1 downto 0) := (others => '0');

    constant AMP_WIDTH          : integer := 5;
    constant base_interval 		: integer := 2**(VOLUME_WIDTH - VOLUME_STEP_2 - 1);
    signal amp_factor             : std_logic_vector(AMP_WIDTH-1 downto 0) := (others => '0');

begin

    multiplier_inst: multiplier
    generic map (
        DATA_WIDTH => TDATA_WIDTH,
        AMP_WIDTH => AMP_WIDTH
    )
    port map (
        aresetn => aresetn,
        aclk => aclk,
        
        in_data => s_axis_tdata,
        amp_factor  => amp_factor,
        
        out_data => amp_data
    );

    saturator_inst: saturator
    generic map (
        DATA_WIDTH => TDATA_WIDTH,
        HIGHER_BOUND => HIGHER_BOUND,
        LOWER_BOUND	=> LOWER_BOUND
    )
    port map (
        aresetn => aresetn,
        aclk => aclk,
        
        orig_data => s_axis_tdata,
        amp_data => amp_data,
        
        out_data => m_axis_tdata
    );
    
    s_axis_tready <= s_axis_tready_int;
    m_axis_tlast <= s_axis_tlast;

    process(aclk, aresetn)
    begin
        if aresetn = '0' then
            s_axis_tready_int <= '0';
        elsif rising_edge(aclk) then
            s_axis_tready_int <= '1';
            m_axis_tvalid <= '0';

            if s_axis_tvalid = '1' and s_axis_tready_int = '1' and m_axis_tready = '1' then
                m_axis_tvalid <= '1';
                if unsigned(volume) > (2**VOLUME_WIDTH - 1) - 2**(VOLUME_STEP_2 - 1) then
                    amp_factor <= std_logic_vector(to_signed(2**(VOLUME_WIDTH - VOLUME_STEP_2) - base_interval, AMP_WIDTH));
                else
                    amp_factor <= std_logic_vector(to_signed(to_integer(shift_right(unsigned(volume) + 2**(VOLUME_STEP_2 - 1), VOLUME_STEP_2)) - base_interval, AMP_WIDTH));
                end if;
            end if;
        end if;
    end process;

end Behavioral;
