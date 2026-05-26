---------------------------------------------------------------------------------- 
-- Module Name: Reverb
-- Revision:
-- Revision 1.1 alpha - Reboot v2 & Initial Release
-- 
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity reverb is
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
end reverb;

architecture Behavioral of reverb is

    --- Delay component declaration -----------------------------------------------
    -------------------------------------------------------------------------------

    component delay is      -- provided in the solution
        generic(
            CHANNEL_LENGHT  : integer;
            DELAY_LENGHT  : integer;
            DELAY_INIT : integer;
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
    end component;

    type state_type is (WAIT_L, WAIT_R, COMPUTE, SEND_L, SEND_R);
    signal state : state_type := WAIT_L;

    signal x_l, x_r : signed(CHANNEL_LENGHT-1 downto 0);
    signal y_l, y_r : std_logic_vector(CHANNEL_LENGHT-1 downto 0);

    signal delay_out_l : std_logic_vector(CHANNEL_LENGHT-1 downto 0);
    signal delay_out_r : std_logic_vector(CHANNEL_LENGHT-1 downto 0);
    signal delay_valid_l : std_logic;
    signal delay_valid_r : std_logic;

begin

    -------------------------------------------------------------------------------
    --- Delay instances -----------------------------------------------------------
    -------------------------------------------------------------------------------

    delay_left: delay
    generic map(
        CHANNEL_LENGHT  => CHANNEL_LENGHT,
        DELAY_LENGHT    => DELAY_LENGHT,
        DELAY_INIT      => DELAY_INIT,
        LOG2_DELAY_INCR => LOG2_DELAY_INCR
    )
    port map( aclk => aclk, aresetn => aresetn, delay_in => delay_in, data_in => y_l, 
              data_in_valid => delay_valid_l, data_out => delay_out_l );

    delay_right: delay
    generic map(
        CHANNEL_LENGHT  => CHANNEL_LENGHT,
        DELAY_LENGHT    => DELAY_LENGHT,
        DELAY_INIT      => DELAY_INIT,
        LOG2_DELAY_INCR => LOG2_DELAY_INCR
    )
    port map( aclk => aclk, aresetn => aresetn, delay_in => delay_in, data_in => y_r, 
              data_in_valid => delay_valid_r, data_out => delay_out_r );

    -------------------------------------------------------------------------------
    --- AXI Handshake & Signals ---------------------------------------------------
    -------------------------------------------------------------------------------

    with state select s_axis_tready <=
        '1' when WAIT_L | WAIT_R,
        '0' when Others;

    with state select m_axis_tvalid <=
        '1' when SEND_L | SEND_R,
        '0' when Others;
        
    with state select m_axis_tdata <=
        y_l when SEND_L,
        y_r when SEND_R,
        (others => '0') when Others;

    with state select m_axis_tlast <=
        '0' when SEND_L,
        '1' when SEND_R,
        '0' when Others;

    -------------------------------------------------------------------------------
    --- Synchronous process -------------------------------------------------------
    -------------------------------------------------------------------------------

    process(aclk, aresetn)
        variable mul_res_l : signed(CHANNEL_LENGHT+GAIN_LENGHT downto 0);
        variable data_gain_l : signed(CHANNEL_LENGHT downto 0);
        variable sum_res_l : signed(CHANNEL_LENGHT downto 0);
        
        variable mul_res_r : signed(CHANNEL_LENGHT+GAIN_LENGHT downto 0);
        variable data_gain_r : signed(CHANNEL_LENGHT downto 0);
        variable sum_res_r : signed(CHANNEL_LENGHT downto 0);
    begin
        if aresetn = '0' then
            state <= WAIT_L;
            -- Initialize signals
            delay_valid_l <= '0';
            delay_valid_r <= '0';
            x_l <= (others => '0');
            x_r <= (others => '0');
            y_l <= (others => '0');
            y_r <= (others => '0');
        elsif rising_edge(aclk) then
            -- Default pulse signals
            delay_valid_l <= '0';
            delay_valid_r <= '0';
            
            case state is
                when WAIT_L =>
                    if s_axis_tvalid = '1' and s_axis_tlast = '0' then
                        x_l <= signed(s_axis_tdata);
                        state <= WAIT_R;
                    end if;
                    
                when WAIT_R =>
                    if s_axis_tvalid = '1' and s_axis_tlast = '1' then
                        x_r <= signed(s_axis_tdata);
                        state <= COMPUTE;
                    end if;

                when COMPUTE =>
                    if enable_reverb = '1' then
                        -- Left channel reverb computation
                        mul_res_l := signed("0" & gain_in) * signed(delay_out_l);
                        data_gain_l := resize(shift_right(mul_res_l, GAIN_LENGHT), CHANNEL_LENGHT+1);
                        sum_res_l := resize(x_l, CHANNEL_LENGHT+1) + data_gain_l;
                        
                        -- Left channel sat algorithm
                        if sum_res_l > HIGHER_BOUND then
                            y_l <= std_logic_vector(to_signed(HIGHER_BOUND, CHANNEL_LENGHT));
                        elsif sum_res_l < LOWER_BOUND then
                            y_l <= std_logic_vector(to_signed(LOWER_BOUND, CHANNEL_LENGHT));
                        else
                            y_l <= std_logic_vector(resize(sum_res_l, CHANNEL_LENGHT));
                        end if;
                        
                        -- Right channel reverb computation
                        mul_res_r := signed("0" & gain_in) * signed(delay_out_r);
                        data_gain_r := resize(shift_right(mul_res_r, GAIN_LENGHT), CHANNEL_LENGHT+1);
                        sum_res_r := resize(x_r, CHANNEL_LENGHT+1) + data_gain_r;
                        
                        -- Right channel sat algorithm
                        if sum_res_r > HIGHER_BOUND then
                            y_r <= std_logic_vector(to_signed(HIGHER_BOUND, CHANNEL_LENGHT));
                        elsif sum_res_r < LOWER_BOUND then
                            y_r <= std_logic_vector(to_signed(LOWER_BOUND, CHANNEL_LENGHT));
                        else
                            y_r <= std_logic_vector(resize(sum_res_r, CHANNEL_LENGHT));
                        end if;
                    else
                        -- Bypass Effect
                        y_l <= std_logic_vector(x_l);
                        y_r <= std_logic_vector(x_r);
                    end if;
                    
                    state <= SEND_L;
                    
                when SEND_L =>
                    if m_axis_tready = '1' then
                        delay_valid_l <= '1';
                        state <= SEND_R;
                    end if;
                    
                when SEND_R =>
                    if m_axis_tready = '1' then
                        delay_valid_r <= '1';
                        state <= WAIT_L;
                    end if;
            end case;
        end if;
    end process;

end Behavioral;
