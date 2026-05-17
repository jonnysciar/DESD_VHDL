library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

entity balance_controller is
    generic (
        TDATA_WIDTH		: positive := 24;	-- Audio, 3 bytes
        BALANCE_WIDTH	: positive := 10;
        BALANCE_STEP_2	: positive := 6		-- i.e., balance_values_per_step = 2**VOLUME_STEP_2
    );
    Port (
        aclk			: in std_logic;
        aresetn			: in std_logic;

        s_axis_tvalid	: in std_logic;
        s_axis_tdata	: in std_logic_vector(TDATA_WIDTH-1 downto 0);
        s_axis_tready	: out std_logic;
        s_axis_tlast	: in std_logic;

        m_axis_tvalid	: out std_logic;
        m_axis_tdata	: out std_logic_vector(TDATA_WIDTH-1 downto 0);
        m_axis_tready	: in std_logic;
        m_axis_tlast	: out std_logic;

        balance			: in std_logic_vector(BALANCE_WIDTH-1 downto 0)
    );
end balance_controller;

architecture Behavioral of balance_controller is

    component volume_multiplier is
        Generic (
            TDATA_WIDTH      : positive := 24;
            AMP_WIDTH       : positive := 5;
            HIGHER_BOUND	: integer := 2**23-1;
            LOWER_BOUND		: integer := -2**23
        );
        Port (
            aresetn     : in std_logic;
            aclk        : in std_logic;

            s_axis_tvalid	: in std_logic;
            s_axis_tdata	: in std_logic_vector(TDATA_WIDTH-1 downto 0);
            s_axis_tlast	: in std_logic;
            s_axis_tready	: out std_logic;

            m_axis_tvalid	: out std_logic;
            m_axis_tdata	: out std_logic_vector(TDATA_WIDTH-1 downto 0);
            m_axis_tlast	: out std_logic;
            m_axis_tready	: in std_logic;
            
            amp_factor  : in std_logic_vector(AMP_WIDTH-1 downto 0)
        );
    end component;

    signal m_axis_tvalid_mult    : std_logic := '0';
    signal m_axis_tdata_mult     : std_logic_vector(TDATA_WIDTH-1 downto 0) := (others => '0');
    signal m_axis_tlast_mult     : std_logic := '0';
    signal m_axis_tready_mult    : std_logic := '0';

    signal s_axis_tready_int    : std_logic := '0';

    constant AMP_WIDTH          : integer := 5;
    constant base_interval 	    : integer := 2**(BALANCE_WIDTH - BALANCE_STEP_2 - 1);
    signal amp_factor           : std_logic_vector(AMP_WIDTH-1 downto 0) := (others => '0');

begin

    multiplier_inst: volume_multiplier
    generic map (
        TDATA_WIDTH => TDATA_WIDTH,
        AMP_WIDTH => AMP_WIDTH,
        HIGHER_BOUND => 2**23-1,
        LOWER_BOUND => -2**23
    )
    port map (
        aresetn => aresetn,
        aclk => aclk,
        
        s_axis_tvalid => m_axis_tvalid_mult,
        s_axis_tdata => m_axis_tdata_mult,
        s_axis_tlast => m_axis_tlast_mult,
        s_axis_tready => m_axis_tready_mult,

        m_axis_tvalid => m_axis_tvalid,
        m_axis_tdata => m_axis_tdata,
        m_axis_tlast => m_axis_tlast,
        m_axis_tready => m_axis_tready,

        amp_factor => amp_factor
    );

    s_axis_tready <= s_axis_tready_int;

    process(aclk, aresetn)
    variable v_amp_factor : integer := 0;
    begin
        if aresetn = '0' then
            amp_factor <= (others => '0');
            s_axis_tready_int <= '0';
        elsif rising_edge(aclk) then
            s_axis_tready_int <= '1';
            m_axis_tvalid_mult <= '0';
            amp_factor <= (others => '0');
            
            if s_axis_tvalid = '1' and s_axis_tready_int = '1' and m_axis_tready_mult = '1' then
                m_axis_tlast_mult <= s_axis_tlast;
                m_axis_tdata_mult <= s_axis_tdata;
                m_axis_tvalid_mult <= '1';

                if unsigned(balance) > (2**BALANCE_WIDTH - 1) - 2**(BALANCE_STEP_2 - 1) then
                    v_amp_factor := 2**(BALANCE_WIDTH - BALANCE_STEP_2) - base_interval;
                else
                    v_amp_factor := to_integer(shift_right(unsigned(balance) + 2**(BALANCE_STEP_2 - 1), BALANCE_STEP_2)) - base_interval;
                end if;

                if (s_axis_tlast = '0' and v_amp_factor > 0) or (s_axis_tlast = '1' and v_amp_factor < 0) then
                    amp_factor <= std_logic_vector(to_signed(-abs(v_amp_factor), AMP_WIDTH));
                end if;
            end if;
        end if;
    end process;

end Behavioral;
