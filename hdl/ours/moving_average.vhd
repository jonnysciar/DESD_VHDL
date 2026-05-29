library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
-- Come vengono trasferiti i dati audio:
-- Un pacchetto da DUE PAROLE DI 24 BIT OGNUNA;
-- Le due parole rappresentano i canali sinistro e destro dell'audio stereo;
-- Prima viene inviato il canale sinistro e poi il destro, su fronti di clock differenti;
-- Le due parole vengono riconosciute tramite l'utilizzo di TLAST:
-- Se TLAST = '0' si tratta del canale sinistro
-- Se TLAST = '1' si tratta del canale destro

entity moving_average is
    Generic (
    LOG2_LEN : POSITIVE := 5;          --Specifica su quanti campioni faccio la media
    CHANNEL_LENGHT : integer := 24;    --Quanti bit contiene una cella della FIFO
    MEMORY_DEPTH : integer := 32       --Quante celle ha la "FIFO"
    );
    Port (
        aclk : in std_logic;                                         
        aresetn : in std_logic;
     --------- SLAVE INTERFACE -----------------------------    
        s_axis_tvalid : in std_logic;
        s_axis_tready : out std_logic;
        s_axis_tdata : in std_logic_vector(CHANNEL_LENGHT-1 downto 0);  
        s_axis_tlast : in std_logic;                                 
     ----------INPUT PORTS - NON AXIS ----------------------
        enable_filter : in std_logic;
     -------------------------------------------------------
     
     --------- MASTER INTERFACE ---------------------------
        m_axis_tready : in std_logic;
        m_axis_tvalid : out std_logic;
        m_axis_tdata : out std_logic_vector(CHANNEL_LENGHT-1 downto 0);
        m_axis_tlast : out std_logic
     -------------------------------------------------------
     
    );
end moving_average;

architecture Behavioral of moving_average is

    type state_moving_average_type is (WAIT_INPUT_L,
                                       WAIT_INPUT_R,
                                       MOVE_INDEX,
                                       COMPUTE,
                                       SEND_OUTPUT_L,
                                       SEND_OUTPUT_R,
                                       OFF);
    signal device_state : state_moving_average_type;
    
    type FIFO_type is array (0 to MEMORY_DEPTH-1) of signed(CHANNEL_LENGHT-1 downto 0);
    signal FIFO_L : FIFO_type := (others => (others => '0'));
    signal FIFO_R : FIFO_type := (others => (others => '0'));
    signal write_index : integer range 0 to MEMORY_DEPTH-1 := 0;
            
    signal sum_L : signed(CHANNEL_LENGHT+LOG2_LEN-1 downto 0) := (others => '0');
    signal sum_R : signed(CHANNEL_LENGHT+LOG2_LEN-1 downto 0) := (others => '0');
    
    -- Registri intermedi per spezzare il critical path
    signal delta_L : signed(CHANNEL_LENGHT downto 0) := (others => '0');
    signal delta_R : signed(CHANNEL_LENGHT downto 0) := (others => '0');
    
    signal old_L : signed(CHANNEL_LENGHT-1 downto 0) := (others => '0');
    signal old_R : signed(CHANNEL_LENGHT-1 downto 0) := (others => '0');

    signal out_data_L : std_logic_vector(CHANNEL_LENGHT-1 downto 0);
    signal out_data_R : std_logic_vector(CHANNEL_LENGHT-1 downto 0);

begin

    with device_state select m_axis_tvalid <=
        '0' when WAIT_INPUT_L,
        '0' when WAIT_INPUT_R,
        '0' when MOVE_INDEX,
        '0' when COMPUTE,
        '1' when SEND_OUTPUT_L,
        '1' when SEND_OUTPUT_R,
        s_axis_tvalid when OFF;     -- Quando è OFF si comporta da bypass
        
    with device_state select s_axis_tready <=
        '1' when WAIT_INPUT_L,
        '1' when WAIT_INPUT_R,
        '0' when MOVE_INDEX,
        '0' when COMPUTE,
        '0' when SEND_OUTPUT_L,
        '0' when SEND_OUTPUT_R,
        m_axis_tready when OFF;     -- Bypass
        
    with device_state select m_axis_tdata <=
        (others => '-') when WAIT_INPUT_L,
        (others => '-') when WAIT_INPUT_R,
        (others => '-') when MOVE_INDEX,
        (others => '-') when COMPUTE,
        out_data_L when SEND_OUTPUT_L,
        out_data_R when SEND_OUTPUT_R,
        s_axis_tdata when OFF;      -- Bypass
        
    with device_state select m_axis_tlast <=
        '-' when WAIT_INPUT_L,
        '-' when WAIT_INPUT_R,
        '-' when MOVE_INDEX,
        '-' when COMPUTE,
        '0' when SEND_OUTPUT_L,
        '1' when SEND_OUTPUT_R,
        s_axis_tlast when OFF;      -- Bypass

    -- Estrazione dato dalla running sum (divisione per MEMORY_DEPTH)
    out_data_L <= std_logic_vector(sum_L(CHANNEL_LENGHT+LOG2_LEN-1 downto LOG2_LEN));
    out_data_R <= std_logic_vector(sum_R(CHANNEL_LENGHT+LOG2_LEN-1 downto LOG2_LEN));
    
    moving_average_process : process (aclk, aresetn)
    begin
        if aresetn = '0' then
            device_state <= WAIT_INPUT_L;
            -- Inizializzo l'indice
            write_index <= 0;
            -- Inizializzo le somme parziali e i pre-fetch
            sum_L <= (others => '0');
            sum_R <= (others => '0');
            delta_L <= (others => '0');
            delta_R <= (others => '0');
            old_L <= (others => '0');
            old_R <= (others => '0');
            -- Inizializzo le FIFO
            FIFO_L <= (others => (others => '0'));
            FIFO_R <= (others => (others => '0'));
        
        elsif rising_edge (aclk) then
            if enable_filter = '0' then
                device_state <= OFF;
                write_index <= 0;
                sum_L <= (others => '0');
                sum_R <= (others => '0');
                delta_L <= (others => '0');
                delta_R <= (others => '0');
                old_L <= (others => '0');
                old_R <= (others => '0');
                FIFO_L <= (others => (others => '0'));
                FIFO_R <= (others => (others => '0'));
            else    -- enable_filter = '1'
                case device_state is
                
                    when OFF =>
                        device_state <= WAIT_INPUT_L;
                        
                    when WAIT_INPUT_L =>
                        if s_axis_tvalid = '1' and s_axis_tlast = '0' then
                            FIFO_L(write_index) <= signed(s_axis_tdata);
                            delta_L <= resize(signed(s_axis_tdata), CHANNEL_LENGHT+1) - resize(old_L, CHANNEL_LENGHT+1);
                            device_state <= WAIT_INPUT_R;  
                        end if;
                        
                    when WAIT_INPUT_R =>
                        if s_axis_tvalid = '1' and s_axis_tlast = '1' then
                            FIFO_R(write_index) <= signed(s_axis_tdata);
                            delta_R <= resize(signed(s_axis_tdata), CHANNEL_LENGHT+1) - resize(old_R, CHANNEL_LENGHT+1);
                            
                            device_state <= MOVE_INDEX;
                        end if;

                    when MOVE_INDEX =>
                        -- Il write index è comune, mi basta fare un singolo check
                        if write_index = MEMORY_DEPTH-1 then
                            write_index <= 0;
                            -- Salvo il prossimo dato da scartare (migliora le performance)
                            old_L <= FIFO_L(0);
                            old_R <= FIFO_R(0);
                        else
                            write_index <= write_index + 1;
                            old_L <= FIFO_L(write_index + 1);
                            old_R <= FIFO_R(write_index + 1);
                        end if;
                        
                        device_state <= COMPUTE;
                        
                    when COMPUTE =>
                        sum_L <= sum_L + delta_L;
                        sum_R <= sum_R + delta_R;
                        device_state <= SEND_OUTPUT_L;
                        
                    when SEND_OUTPUT_L =>
                        if m_axis_tready = '1' then
                            device_state <= SEND_OUTPUT_R;
                        end if;
                        
                    when SEND_OUTPUT_R =>
                        if m_axis_tready = '1' then
                            device_state <= WAIT_INPUT_L;
                        end if;
                        
                end case;
            end if;
        end if;
    end process;

end Behavioral;
