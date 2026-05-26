library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
-- Come vengono trasferiti i dati audio:
-- Un pacchetto da DUE PAROLE DA 24 BIT OGNUNA;
-- Le due parole rappresentano i canali sinistro e destro dell'audio stereo;
-- Prima viene inviato il canale sinistro e poi il destro, su deu cicli di clock differenti;
-- Le due parole vengono riconosciute tramite l'utilizzo di TLAST:
-- Se TLAST = '0' � il canale sinsistro
-- Se TLAST = '1' � il canale destro


-- Nota: ho chiamato le strutture per memorizzare i dati "FIFO" sebbene siano semplicemente
-- dei buffer circolari. Ho fatto questa scelta solo per brevit� di scrittura.

entity moving_average is
    Generic (
    
    LOG2_LEN : POSITIVE := 5;          --Specifica su quanti campioni faccio la media
    CHANNEL_LENGHT : integer := 24;    --Quanti bit contiene una cella della FIFO
    MEMORY_DEPTH : integer := 32       --Quante celle ha la "FIFO"
    
    );
    
    Port (
    
     --------- SLAVE INTERFACE -----------------------------    
        s_axis_tvalid : in std_logic;
        s_axis_tready : out std_logic;
        s_axis_tdata : in std_logic_vector(CHANNEL_LENGHT-1 downto 0);  
        s_axis_tlast : in std_logic;                                 
        aclk : in std_logic;                                         
        aresetn : in std_logic;
     ----------INPUT PORTS - NON AXIS ----------------------
        enable_filter : in std_logic;
     -------------------------------------------------------
     
     --------- MASRTER INTERFACE ---------------------------
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
                                       WORKING_1,      -- Due stati di "lavorazione" solo
                                       WORKING_2,      -- per far arrivare il modulo a 200 MHz
                                       SEND_OUTPUT_L,
                                       SEND_OUTPUT_R,
                                       OFF);                --Stati per la FSM del progetto
    signal device_state : state_moving_average_type;
    
    type FIFO_type is array (MEMORY_DEPTH-1 downto 0) of std_logic_vector(CHANNEL_LENGHT-1 downto 0);
    signal FIFO_L : FIFO_type := (others => (others => '0'));  --Una "FIFO" per ogni canale
    signal FIFO_R : FIFO_type := (others => (others => '0'));
    signal L_write_index, R_write_index : integer range 0 to MEMORY_DEPTH-1 := 0;
    signal read_index : integer range 0 to MEMORY_DEPTH-1 := 0;  --E' necessario un unico read_index
        
    signal FIFO_input : std_logic_vector (CHANNEL_LENGHT-1 downto 0);
    signal L_final_value : std_logic_vector (CHANNEL_LENGHT-1 downto 0);
    signal R_final_value : std_logic_vector (CHANNEL_LENGHT-1 downto 0);

begin

    with device_state select m_axis_tvalid <=           --Per gestire il tvalid sulla base dello stato
        '0' when WAIT_INPUT_L,
        '0' when WAIT_INPUT_R,
        '0' when WORKING_1,
        '0' when WORKING_2,
        '1' when SEND_OUTPUT_L,
        '1' when SEND_OUTPUT_R,
        '1' when OFF;
    with device_state select s_axis_tready <=           --Per gestire il tready sulla base dello stato
        '1' when WAIT_INPUT_L,
        '1' when WAIT_INPUT_R,
        '0' when WORKING_1,
        '0' when WORKING_2,
        '0' when SEND_OUTPUT_L,
        '0' when SEND_OUTPUT_R,
        '1' when OFF;
    with device_state select m_axis_tdata <=            --Per gestire il tdata sulla base dello stato 
        (others => '-') when WAIT_INPUT_L,
        (others => '-') when WAIT_INPUT_R,
        (others => '-') when WORKING_1,
        (others => '-') when WORKING_2,
        L_final_value when SEND_OUTPUT_L,
        R_final_value when SEND_OUTPUT_R,
        s_axis_tdata when OFF;
    with device_state select m_axis_tlast <=            --Per gestire il tlast sulla base dello stato 
        '-' when WAIT_INPUT_L,
        '-' when WAIT_INPUT_R,
        '-' when WORKING_1,
        '-' when WORKING_2,
        '0' when SEND_OUTPUT_L,
        '1' when SEND_OUTPUT_R,
        s_axis_tlast when OFF;
        
    double_FIFO_process : process (aclk)            --Per gestire il funzionamento delle "FIFO"
    begin
    
        if rising_edge(aclk) then                   
            if aresetn = '0' then
                L_write_index <= 0;
                R_write_index <= 0;
                FIFO_L <= (others => (others => '0'));
                FIFO_R <= (others => (others => '0'));
            else
                if s_axis_tlast = '0' then
                    FIFO_L(L_write_index) <= FIFO_input;
                    if L_write_index = MEMORY_DEPTH-1 then
                        L_write_index <= 0;
                    else
                        L_write_index <= L_write_index+1;
                    end if;
                else
                    FIFO_R(R_write_index) <= FIFO_input;
                        if R_write_index = MEMORY_DEPTH-1 then
                            R_write_index <= 0;
                        else
                            R_write_index <= R_write_index+1;
                        end if;
                end if;
            end if;
        end if;
        
    end process;
    
    
    moving_average_process : process (aclk)
        variable partial_sum_L, partial_sum_R : unsigned(CHANNEL_LENGHT-1 downto 0) := (others => '0');
        variable partial_mean_L, partial_mean_R : unsigned(CHANNEL_LENGHT-1 downto 0):= (others => '0');
    begin
        if rising_edge (aclk) then   --Clock asincrono?
            if enable_filter = '1' then
                if aresetn = '0' then
                    device_state <= WAIT_INPUT_L;
                    L_final_value <= (others => '0');
                    R_final_value <= (others => '0');
                else
                    case device_state is
                    
                        when WAIT_INPUT_L =>                         --Ogni quanto mi mandano dei segnali?
                            if s_axis_tvalid = '1' then
                                FIFO_input <= s_axis_tdata;
                                device_state <= WAIT_INPUT_R;  
                            end if;
                            
                        when WAIT_INPUT_R =>
                            if s_axis_tvalid = '1' then
                                FIFO_input <= s_axis_tdata;
                                device_state <= WORKING_1;
                            end if;
                                
                        when WORKING_1 =>   --How do I handle a possible overflow?
                            partial_sum_L := (others => '0');
                            partial_sum_R := (others => '0');
                            partial_mean_L := (others => '0');
                            partial_mean_R := (others => '0');
                            for read_index in 0 to MEMORY_DEPTH-1 loop
                                partial_sum_L := partial_sum_L + unsigned(FIFO_L(read_index));
                                partial_sum_R := partial_sum_R + unsigned(FIFO_R(read_index));
                            end loop;
                            device_state <= WORKING_2;
                            
                        when WORKING_2 =>
                            partial_mean_L := (partial_sum_L)/(2**LOG2_LEN);
                            partial_mean_R := (partial_sum_R)/(2**LOG2_LEN);
                            L_final_value <= std_logic_vector(partial_mean_L);
                            R_final_value <= std_logic_vector(partial_mean_R);
                            device_state <= SEND_OUTPUT_L;
                            
                        when SEND_OUTPUT_L =>
                            if m_axis_tready = '1' then
                                device_state <= SEND_OUTPUT_R;
                            end if;
                            
                        when SEND_OUTPUT_R =>
                            if m_axis_tready = '1' then
                                device_state <= WAIT_INPUT_L;
                            end if;
                            
                        when others =>
                            null;
                    end case;
                end if;
            else
                device_state <= OFF;
            end if;
        end if;
    end process;



end Behavioral;
