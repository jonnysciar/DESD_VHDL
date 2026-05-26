---------------------------------------------------------------------------------- 
-- Module Name: Reverb
-- Revision:
-- Revision 0.4 - We are getting there...
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

    --- Delay component declarations ----------------------------------------------

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
    -------------------------------------------------------------------------------

    type datapath_fsm_t is (IDLE, COMPUTE, SAT, DONE);
    signal datapath_state : datapath_fsm_t := SAMPLE;

    type output_fsm_t is (IDLE, WRITE_L, WRITE_R);
    signal output_state : output_fsm_t := IDLE;

    type input_fsm_t is (IDLE, SAMPLE_L, SAMPLE_R);
    signal input_state  : input_fsm_t := IDLE;

    --- Registers -----------------------------------------------------------------
    -------------------------------------------------------------------------------

    -- Signals to collect from s_axis bus
    signal x_in_l : signed(CHANNEL_LENGHT-1 downto 0);
    signal x_in_r : signed(CHANNEL_LENGHT-1 downto 0);
    
    -- Results coming out of Delay instances
    signal delay_out_l : signed(CHANNEL_LENGHT-1 downto 0);
    signal delay_out_r : signed(CHANNEL_LENGHT-1 downto 0);

    -- Intermediate computation results
    -- signal mul_res_l    : signed(CHANNEL_LENGHT+DELAY_LENGHT-2 downto 0);
    -- signal mul_res_r    : signed(CHANNEL_LENGHT+DELAY_LENGHT-2 downto 0);

    -- signal data_gain_l  : signed(CHANNEL_LENGHT-1 downto 0);
    -- signal data_gain_r  : signed(CHANNEL_LENGHT-1 downto 0);

    signal sum_res_l    : signed(CHANNEL_LENGHT downto 0);      -- It is 1 bit larger to account for overflow
    signal sum_res_r    : signed(CHANNEL_LENGHT downto 0);

    -- The following are used to save temporary results until commit on m_axis bus.
    -- They are also stored for feedback into the Delay module.
    --
    -- **Note:** tvalid signals are also used by the output_logic to establish when to commit.

    signal res_left_tvalid : std_logic;
    signal res_left_tdata  : std_logic_vector(CHANNEL_LENGHT-1 downto 0);

    signal res_right_tvalid : std_logic;
    signal res_right_tdata  : std_logic_vector(CHANNEL_LENGHT-1 downto 0);

begin

    -------------------------------------------------------------------------------
    --- Input Logic ---------------------------------------------------------------
    -------------------------------------------------------------------------------

    with input_state select s_axis_tready <=
        '1' when SAMPLE_L | SAMPLE_R;
        '0' when Others;

    input_logic : process(aclk, aresetn)
    begin
        if aresetn = '0' then

        elsif rising_edge(clk) then
            
            case input_state is
                when IDLE =>
                    -- should I wait for something??

                when SAMPLE_L =>
                    if s_axis_tvalid = '1' and s_axis_tlast = '0' then
                        -- Save data
                        x_in_l <= s_axis_tdata;
                        -- Next state
                        input_state <= SAMPLE_R;
                    end if;

                when SAMPLE_R =>
                    if s_axis_tvalid = '1' s_axis_tlast = '1' then
                        -- Save data
                        x_in_r <= s_axis_tdata
                        -- Next state
                        input_state <= IDLE;
                    end if;

            end case;
        end if;

    end process;

    -------------------------------------------------------------------------------
    --- Output Logic --------------------------------------------------------------
    -------------------------------------------------------------------------------

    with output_state select m_axis_tvalid <=
        '1' when WRITE_L | WRITE_R,
        '0' when Others;

    with output_state select m_axis_tlast <=
        '1' when WRITE_R, 
        '0' when Others;

    with output_state select m_axis_tdata <=
        res_left_tdata  when WRITE_L,
        res_right_tdata when WRITE_R;
        "-"             when Others;

    output_logic : process(alck, aresetn)
    begin
        if aresetn = '0' then
            output_state <= IDLE;

        elsif rising_edge(aclk) then
            case output_state is

                when IDLE =>
                    if res_left_tvalid = '1' then
                        output_state <= WRITE_L;
                    end if;
                
                when WRITE_L =>    
                    -- Wait in this state until transaction goes through
                    -- IS RES_RIGHT_TVALID NECESSARY?
                    if m_axis_tready = '1' and res_right_tvalid = '1' then
                        output_state <= WRITE_R;
                    end if;

                when WRITE_R =>
                    -- Wait in this state until transaction goes through.
                    -- Data is selected in dataflow.
                    if m_axis_tready = '1' then
                        output_state <= IDLE;
                    end if;
                end case;
        end if;
    end process;

    -------------------------------------------------------------------------------
    --- Datapath ------------------------------------------------------------------
    -------------------------------------------------------------------------------

    delay_left: delay
    generic map(
        CHANNEL_LENGHT  => CHANNEL_LENGHT,
        DELAY_LENGHT    => DELAY_LENGHT,
        DELAY_INIT      => DELAY_INIT,
        LOG2_DELAY_INCR => LOG2_DELAY_INCR
    )
    port map( aclk => aclk, aresetn => aresetn, delay_in => delay_in, data_in => res_left_tdata, 
              data_in_valid => res_left_tvalid, data_out => delay_out_l );

    delay_right: delay
    generic map(
        CHANNEL_LENGHT  => CHANNEL_LENGHT,
        DELAY_LENGHT    => DELAY_LENGHT,
        DELAY_INIT      => DELAY_INIT,
        LOG2_DELAY_INCR => LOG2_DELAY_INCR
    )
    port map( aclk => aclk, aresetn => aresetn, delay_in => delay_in, data_in => res_right_tdata, 
              data_in_valid => res_right_tvalid, data_out => delay_out_r );

    datapath_logic: process(aclk, aresetn)
        variable mul_res_l : signed(CHANNEL_LENGHT+DELAY_LENGHT-2 downto 0);
        variable data_gain_l  : signed(CHANNEL_LENGHT-1 downto 0);
        -- variable sum_res_l    : signed(CHANNEL_LENGHT downto 0);

        variable mul_res_r : signed(CHANNEL_LENGHT+DELAY_LENGHT-2 downto 0);
        variable data_gain_r  : signed(CHANNEL_LENGHT-1 downto 0);        

    begin
        if aresetn = '0' then
            datapath_state <= IDLE;
            -- WHAT ELSE?

        elsif rising_edge(aclk) then

            case datapath_state is

                when COMPUTE =>
                    mul_res_l   := signed(gain_in) * signed(delay_out_l);
                    -- Shift and resize
                    data_gain_l := resize(shift_right(mul_res_l, GAIN_LENGHT), CHANNEL_LENGHT);
                    sum_res_l   <= x_in_l + data_gain_l;

                    mul_res_r   := signed(gain_in) * signed(delay_out_r);
                    -- Shift and resize
                    data_gain_r := resize(shift_right(mul_res_r, GAIN_LENGHT), CHANNEL_LENGHT);
                    sum_res_r   <= x_in_r + data_gain_r;

                    datapath_state <= SAT;

                when SAT =>

                    if sum_res_l > HIGHER_BOUND then
                        res_left_tdata <= HIGHER_BOUND;
                    elsif sum_res_l < LOWER_NOUND then
                        res_left_tdata <= LOWER_BOUND;
                    else
                        res_left_tdata <= resize(sum_res_l, CHANNEL_LENGHT);
                    end if;

                    datapath_state <= DONE;
                
                when DONE =>

                    

            end case;
        end if;
    end process;

end Behavioral;
