---------------------------------------------------------------------------------- 
-- Module Name: Reverb
-- Revision:
-- Revision 0.1 - File Created
-- Revision 0.2 - Skull of the module + Comments
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

    type reverb_fsm_t is (IDLE, DELAY, MULTIPLY, GAIN, SUM, SAT);
    signal left_ch_state : reverb_fsm_t := IDLE;
    signal right_ch_state : reverb_fsm_t := IDLE;

    --- Flags ---------------------------------------------------------------------
    signal start_left   : std_logic := '0'; 
    signal end_left     : std_logic := '0';
    signal start_right  : std_logic := '0';
    signal end_right    : std_logic := '0';   

    --- Registers -----------------------------------------------------------------

    signal s_axis_tready_int    : std_logic := '0';
    signal m_axis_tdata_tmp     : std_logic_vector(CHANNEL_LENGHT-1 downto 0);
    signal m_axis_tvalid_tmp    : std_logic;

    signal y_out_delay          : std_logic_vector(CHANNEL_LENGHT-1 downto 0);
    
    signal gain_in1             : std_logic_vector(GAIN_LENGHT-1 downto 0);
    signal gain_in2             : std_logic_vector(GAIN_LENGHT-1 downto 0);
    signal gain_in3             : std_logic_vector(GAIN_LENGHT-1 downto 0);
    signal gain_in4             : std_logic_vector(GAIN_LENGHT-1 downto 0);

    signal x_in1                : std_logic_vector(CHANNEL_LENGHT-1 downto 0);
    signal x_in2                : std_logic_vector(CHANNEL_LENGHT-1 downto 0);
    signal x_in3                : std_logic_vector(CHANNEL_LENGHT-1 downto 0);

    signal mul_res              : std_logic_vector(CHANNEL_LENGHT+GAIN_LENGHT-2 downto 0);

    -- signal data_gain            : std_logic_vector();

    -- signal sum_res              : std_logic_vector();


begin

    --- Delay module instance -----------------------------------------------------
    delay_inst: delay
    generic map(
        CHANNEL_LENGHT  => CHANNEL_LENGHT,
        DELAY_LENGHT    => DELAY_LENGHT,
        DELAY_INIT      => DELAY_INIT,
        LOG2_DELAY_INCR => LOG2_DELAY_INCR
    )
    port map( aclk => aclk, aresetn => aresetn, delay_in => delay_in, data_in => m_axis_tdata_tmp, 
              data_in_valid => m_axis_tvalid_tmp, data_out => y_out_delay );

    --- AXIS tvalid/tready control logic ------------------------------------------
    with axis_state select s_axis_tready_int <=
        '1' when SAMPLE_L | SAMPLE_R,
        '0' when PROCESSING | WRITE_L | WRITE_R;

    with axis_state select m_axis_tvalid <=
        '1' when WRITE_L | WRITE_R,
        '0' when SAMPLE_L | SAMPLE_R | PROCESSING;

    axis_fsm: process(aclk, aresetn)
    begin
        if aresetn = '0' then
            s_axis_tready_int <= '0';

        elsif rising_edge(aclk) then

            if enable_reverb = '0' then
                -- short circuit
                m_axis_tdata <= s_axis_tdata;
                m_axis_tvalid <= s_axis_tvalid;
                m_axis_tlast <= s_axis_tlast;
                s_axis_tready_int <= m_axis_tready;
            else enable_reverb = '1' then
                case axis_state is

                    when SAMPLE_L =>
                        if s_axis_tvalid = '1' then
                            x_in1 <= s_axis_tdata;

                            left_ready <= '1';

                            axis_state <= SAMPLE_R;
                        end if;
                        
                    when SAMPLE_R =>
                        if s_axis_tvalid = '1' then
                            x_in2 <= x_in1;
                            x_in1 <= s_axis_tdata;

                            axis_state <= PROCESSING;
                            left_ch_state <= DELAY;
                        end if;

                    when PROCESSING =>
                        

                    when WRITE_L =>
                        m_axis_tdata_tmp    <= m_axis_tdata_tmp;
                        m_axis_tvalid_tmp   <= '1';
                        axis_state          <= WRITE_R;

                    when WRITE_R =>
                        m_axis_tdata_tmp    <= 
                        axis_state          <= SAMPLE_L;

                end case;
        end if;

    end process;

    left_channel: process(aclk, aresetn)
    begin
        if aresetn = '0' then
            left_ch_state <= IDLE;
        
        elsif rising_edge(clk) and left_ready = '1' then

            case left_ch_state is
                -- useless
                -- when IDLE =>
                -- Wait for ready signal
                --      

                when DELAY =>
                -- signals in input of delay module are written

                when MULTIPLY =>
                    mul_res <= gain_in1 * y_out_delay;

                when GAIN => 
                    data_gain   <= shift_right(to_signed(mul_res), GAIN_LENGHT);


                when SUM =>
                    sum_res     <= data_gain + x_in3;
                    left_valid  <= '1';


            end case;

        end if;

    end process;


    right_channel: process(aclk, aresetn)
    begin
        if aresetn = '0' then
            -- Reset procedure

        elsif rising_edge(aclk) then

            -- We will always accept (IS IT TRUE?)
            s_axis_tready <= '1';

            -- Handle enable_reverb = '0'
            -- Do I create a bypass?

            if s_axis_tvalid = '1' and m_axis_tready = '1' then
    
                -- Stage 1: Delay Stage -----------------------------------------------
                -- y_out_delay <= delay();
                x_in1       <= s_axis_tdata;
                gain_in1    <= gain_in;

                -- Stage 2: Multiply Stage --------------------------------------------
                mul_res     <= gain_in1 * y_out_delay;
                gain_in2    <= gain_in1;
                x_in2       <= x_in1;

                -- Stage 3: Gain Stage ------------------------------------------------
                data_gain   <= shift_right(to_signed(mul_res), GAIN_LENGHT);
                gain_in3    <= gain_in2;
                x_in3       <= x_in2;

                -- Stage 4: Sum Stage -------------------------------------------------
                sum_res     <= data_gain + x_in3;
                gain_in4    <= gain_in3;

                -- Stage 5: Saturation Stage ------------------------------------------
                m_axis_tdata_tmp    <= sat();
                m_axis_tvalid_tmp   <= '1';

                -- Stage 6: Output Stage ----------------------------------------------
                m_axis_tdata        <= m_axis_tdata_tmp;
                m_axis_tvalid       <= m_axis_tvalid_tmp;
                -- Note: actually the output has to stay fixed at DELAY_INIT 
                -- for the first 5 clock cycles, otherwise it will be U.

            else
                -- If preceding master (I2S IP) has not sent valid data, the pipeline stalls
                -- but no data is lost. The Moving Average will see the same stable value in
                -- output.

                -- If the following slave (Moving Average) is not ready (which should not
                -- happen anyways), the pipeline stalls and input data is lost.

                -- In other words, there are no FIFOs to handle hazards, and the module 
                -- in expected to work in lockstep.

                m_axis_tvalid_tmp <= '0';

                -- Setting m_axis_tvalid_tmp low prevents misbehavior on the Delay module:
                -- the output of delay will only change if tvalid = '1', otherwise the 
                -- preceding value will stay stable. This is particularly useful because 
                -- the Delay module samples also non-ready values from the input AXI stream.
                -- But we know the pipeline only advances if input and ouput devices are
                -- are valid and ready respectively.

                -- Another approach (probably more correct, but adds 1 cc latency) would be
                -- registering the inputs of the Reverb module, and only changing the input
                -- of Delay if they are actually valid.

            end if;
        end if;
    end process;  



        

end Behavioral;
