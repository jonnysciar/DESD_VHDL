---------------------------------------------------------------------------------- 
-- Module Name: Reverb
-- Revision:
-- Revision 0.1 - File Created
-- Revision 0.2 - Skull of the module + Comments
-- Revision 0.3 - Reboot
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

    --- Components declarations ---------------------------------------------------

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

    --- FSM states declarations ---------------------------------------------------

    type axis_fsm_t is (DISABLE, SAMPLE_L, SAMPLE_R, PROCESSING, WRITE_L, WRITE_R);
    signal axis_state : axis_fsm_t := SAMPLE_L;

    -- type reverb_fsm_t is (IDLE, DELAY, MULTIPLY, GAIN, SUM, SAT);
    -- signal left_ch_state : reverb_fsm_t := IDLE;
    -- signal right_ch_state : reverb_fsm_t := IDLE;

    --- Registers -----------------------------------------------------------------

    s_axis_tready_int : std_logic;
    m_axis_tvalid_int : std_logic;
    m_axis_tdata_int : std_logic_vector(CHANNEL_LENGHT-1 downto 0);

    y_out_delayed  : std_logic_vector(CHANNEL_LENGHT-1 downto 0);

    x_in_l  : std_logic_vector(CHANNEL_LENGHT-1 downto 0);
    x_in_r : std_logic_vector(CHANNEL_LENGHT-1 downto 0);


begin

    --- Left instance -----------------------------------------------------
    delay_left: delay
    generic map(
        CHANNEL_LENGHT  => CHANNEL_LENGHT,
        DELAY_LENGHT    => DELAY_LENGHT,
        DELAY_INIT      => DELAY_INIT,
        LOG2_DELAY_INCR => LOG2_DELAY_INCR
    )
    port map( aclk => aclk, aresetn => aresetn, delay_in => delay_in, data_in => m_axis_tdata_int, 
              data_in_valid => m_axis_tvalid_int, data_out => delay_out );

    delay_right: delay
    generic map(
        CHANNEL_LENGHT  => CHANNEL_LENGHT,
        DELAY_LENGHT    => DELAY_LENGHT,
        DELAY_INIT      => DELAY_INIT,
        LOG2_DELAY_INCR => LOG2_DELAY_INCR
    )
    port map( aclk => aclk, aresetn => aresetn, delay_in => delay_in, data_in => m_axis_tdata_int, 
              data_in_valid => m_axis_tvalid_int, data_out => delay_out );

    --- AXIS signals ---------------------------------------------------------------
    with axis_state select s_axis_tready_int <=
        '1' when SAMPLE_L | SAMPLE_R,
        '0' when PROCESSING | WRITE_L | WRITE_R;

    with axis_state select m_axis_tvalid_int <=
        '1' when WRITE_L | WRITE_R,
        '0' when SAMPLE_L | SAMPLE_R | PROCESSING;

    axis_fsm: process(aclk, aresetn)
    begin
        if aresetn = '0' then
            s_axis_tready_int <= '0';

        elsif rising_edge(aclk) then

            if enable_reverb = '0' then
                -- short circuit
                -- do I check for handshake?
                m_axis_tdata <= s_axis_tdata;
                m_axis_tvalid <= s_axis_tvalid;
                m_axis_tlast <= s_axis_tlast;
                s_axis_tready_int <= m_axis_tready;

            elsif enable_reverb = '1' then

                case axis_state is
                    when SAMPLE_L =>
                        if s_axis_tvalid = '1' then
                            -- Sample input signals
                            delay_in_reg <= delay_in;
                            x_in_l <= s_axis_tdata;

                            -- Go to next state
                            axis_state <= SAMPLE_R;
                        end if;
                        
                    when SAMPLE_R =>
                        if s_axis_tvalid = '1' then
                            -- Sample input signals
                            delay_in_reg <= delay_in;
                            x_in_r   <= s_axis_tdata;

                            -- Go to next state
                            axis_state <= PROCESSING;
                        end if;

                    when PROCESSING =>
                        
                        mul_res_l       := gain_in * delay_out;
                        data_gain_l     := shift_right(mul_res_l, GAIN_LENGHT);
                        sum_res_l       := x_in_l + data_gain_l;

                        -- Saturation algorithm
                        if unsigned(sum_res) > (2**VOLUME_WIDTH - 1) - 2**(VOLUME_STEP_2 - 1) then
                            
                        else
                        
                        end if;

                        mul_res_r       := gain_in * delay_out_r;
                        data_gain_r     := shift_right(mul_res_r, GAIN_LENGHT);
                        sum_res_l       := x_in_r + data_gain_r;

                        -- Saturation algorithm

                        
                    when WRITE_L =>
                        if m_axis_tready = '1' then
                            m_axis_tdata_int    <= ;
                            axis_state          <= WRITE_R;

                            -- Go to next state
                            axis_state          <= WRITE_R;
                        end if;

                    when WRITE_R =>
                        if m_axis_tready = '1' then
                            m_axis_tdata_int    <= 

                            -- Go to next state
                            axis_state          <= SAMPLE_L;
                        end if;
                        

                end case;
        end if;

    end process;

      
end Behavioral;
