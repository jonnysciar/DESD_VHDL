library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity output_sel is
    Generic (
        TDATA_WIDTH		: positive := 24;		-- 3 byte for audio
        LED_WIDTH		: positive := 8;
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

        toggle			: in std_logic;

        led_r			: out std_logic_vector(LED_WIDTH-1 downto 0);
        led_g			: out std_logic_vector(LED_WIDTH-1 downto 0);
        led_b			: out std_logic_vector(LED_WIDTH-1 downto 0)
    );
end entity output_sel;

architecture rtl of output_sel is

    type out_sel_type is (l_r,mute,l_l,r_r,lpr_lpr,lmr_lmr,lpr_lmr,lmr_lpr);

    signal out_sel 			 : out_sel_type := l_r;

    signal s_axis_tready_int : std_logic := '0';
    signal in_l_data		 : std_logic_vector(TDATA_WIDTH-1 downto 0);
    signal in_r_data		 : std_logic_vector(TDATA_WIDTH-1 downto 0);
    signal out_l_data		 : std_logic_vector(TDATA_WIDTH-1 downto 0);
    signal out_r_data		 : std_logic_vector(TDATA_WIDTH-1 downto 0);

    type CHANNEL_STATE is (READ_LEFT, READ_RIGHT, DELAY, WRITE_LEFT, WRITE_RIGHT);
    signal state : CHANNEL_STATE := READ_LEFT;

begin
    s_axis_tready <= s_axis_tready_int;

    with out_sel select led_r <= 
        (others => '1') when l_r,
        (others => '1') when mute,
        (others => '1') when l_l,
        (others => '1') when r_r,
        (others => '0') when lpr_lpr,
        (others => '0') when lmr_lmr,
        (others => '0') when lpr_lmr,
        (others => '0') when lmr_lpr;

    with out_sel select led_g <= 
        (others => '1') when l_r,
        (others => '1') when mute,
        (others => '0') when l_l,
        (others => '0') when r_r,
        (others => '1') when lpr_lpr,
        (others => '1') when lmr_lmr,
        (others => '0') when lpr_lmr,
        (others => '0') when lmr_lpr;

    with out_sel select led_b <= 
        (others => '1') when l_r,
        (others => '0') when mute,
        (others => '1') when l_l,
        (others => '0') when r_r,
        (others => '1') when lpr_lpr,
        (others => '0') when lmr_lmr,
        (others => '1') when lpr_lmr,
        (others => '0') when lmr_lpr;

    with state select s_axis_tready_int <=
        '1' when READ_LEFT,
        '1' when READ_RIGHT,
        '0' when DELAY,
        '0' when WRITE_LEFT,
        '0' when WRITE_RIGHT;

    toggle_handler: process(aresetn, aclk)
    begin
        if aresetn = '0' then
            out_sel <= l_r;
        elsif rising_edge(aclk) then
            if toggle = '1' then
                case out_sel is
                    when l_r => out_sel <= mute;
                    when mute => out_sel <= l_l;
                    when l_l => out_sel <= r_r ;
                    when r_r => out_sel <= lpr_lpr;
                    when lpr_lpr => out_sel <= lmr_lmr;
                    when lmr_lmr => out_sel <= lpr_lmr;
                    when lpr_lmr => out_sel <= lmr_lpr;
                    when lmr_lpr => out_sel <= l_r;
                end case;
            end if;
        end if;
    end process;

    axis_fsm: process(aresetn, aclk)
    begin
        if aresetn = '0' then
            state <= READ_LEFT;
            m_axis_tvalid <= '0';
        elsif rising_edge(aclk) then
            m_axis_tvalid <= '0';

            case state is
                when READ_LEFT =>
                    if s_axis_tvalid = '1' and s_axis_tlast = '0' then
                        in_l_data <= s_axis_tdata;
                        state <= READ_RIGHT;
                    end if;
                when READ_RIGHT =>
                    if s_axis_tvalid = '1' and s_axis_tlast = '1' then
                        in_r_data <= s_axis_tdata;
                        state <= DELAY;
                    end if;
                when DELAY =>
                    state <= WRITE_LEFT;
                when WRITE_LEFT =>
                    if m_axis_tready = '1' then
                        m_axis_tdata <= out_l_data;
                        m_axis_tvalid <= '1';
                        m_axis_tlast <= '0';
                        state <= WRITE_RIGHT;
                    end if;
                when WRITE_RIGHT =>
                    if m_axis_tready = '1' then
                        m_axis_tdata <= out_r_data;
                        m_axis_tvalid <= '1';
                        m_axis_tlast <= '1';
                        state <= READ_LEFT;
                    end if;
            end case;
        end if;
    end process;

    left_channel_handler: process(aresetn, aclk)
    variable tmp_out_data : signed(TDATA_WIDTH downto 0);
    begin
        if aresetn = '0' then
            out_l_data <= (others => '0');
        elsif rising_edge(aclk) and state = DELAY then
            case out_sel is
                when l_r => out_l_data <= in_l_data;
                when mute => out_l_data <= (others => '0');
                when l_l => out_l_data <= in_l_data;
                when r_r => out_l_data <= in_r_data;
                when lpr_lpr | lpr_lmr =>
                    tmp_out_data := resize(signed(in_l_data), TDATA_WIDTH + 1);
                    tmp_out_data := tmp_out_data + resize(signed(in_r_data), TDATA_WIDTH + 1);
                    tmp_out_data := shift_right(tmp_out_data, 1);
                    out_l_data <= std_logic_vector(resize(tmp_out_data, TDATA_WIDTH));
                when lmr_lmr | lmr_lpr =>
                    tmp_out_data := resize(signed(in_l_data), TDATA_WIDTH + 1);
                    tmp_out_data := tmp_out_data - resize(signed(in_r_data), TDATA_WIDTH + 1);
                    tmp_out_data := shift_right(tmp_out_data, 1);
                    out_l_data <= std_logic_vector(resize(tmp_out_data, TDATA_WIDTH));
            end case;
        end if;
    end process;

    right_channel_handler: process(aresetn, aclk)
    variable tmp_out_data : signed(TDATA_WIDTH downto 0);
    begin
        if aresetn = '0' then
            out_r_data <= (others => '0');
        elsif rising_edge(aclk) and state = DELAY then
            case out_sel is
                when l_r => out_r_data <= in_r_data;
                when mute => out_r_data <= (others => '0');
                when l_l => out_r_data <= in_l_data;
                when r_r => out_r_data <= in_r_data;
                when lpr_lpr | lmr_lpr =>
                    tmp_out_data := resize(signed(in_l_data), TDATA_WIDTH + 1);
                    tmp_out_data := tmp_out_data + resize(signed(in_r_data), TDATA_WIDTH + 1);
                    tmp_out_data := shift_right(tmp_out_data, 1);
                    out_r_data <= std_logic_vector(resize(tmp_out_data, TDATA_WIDTH));
                when lmr_lmr | lpr_lmr =>
                    tmp_out_data := resize(signed(in_l_data), TDATA_WIDTH + 1);
                    tmp_out_data := tmp_out_data - resize(signed(in_r_data), TDATA_WIDTH + 1);
                    tmp_out_data := shift_right(tmp_out_data, 1);
                    out_r_data <= std_logic_vector(resize(tmp_out_data, TDATA_WIDTH));
            end case;
        end if;
    end process;
end architecture;
