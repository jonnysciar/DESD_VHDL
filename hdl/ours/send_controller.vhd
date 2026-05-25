library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity send_controller is
    generic(
        DATA_LENGHT  : positive := 16   -- 2 byte of TDATA in FLOAT COMPRESSOR
    );
    port (
        aclk   : in std_logic;
        aresetn : in std_logic;

        s_axis_tvalid	: in std_logic;
        s_axis_tdata	: in std_logic_vector(DATA_LENGHT-1 downto 0);
        s_axis_tlast    : in std_logic;
        s_axis_tready	: out std_logic;

        m_axis_tvalid	: out std_logic;
        m_axis_tdata	: out std_logic_vector(DATA_LENGHT-1 downto 0);
        m_axis_tready	: in std_logic;

        send_audio    : in std_logic
    );
end entity send_controller;

architecture rtl of send_controller is
    
    --state machine to follow the flow
    type state_type is (IDLE, SEND);
    signal state : state_type := IDLE;

    signal s_axis_tready_int : std_logic := '0';

begin
    
    --starting the fsm machine different state
    process(aclk, aresetn)
    begin
        if aresetn = '0' then
            state     <= IDLE;
            m_axis_tdata <= (others => '0');
            m_axis_tvalid <= '0';
            s_axis_tready_int <= '0';

        elsif rising_edge(aclk) then

            s_axis_tready_int <= '1';
            m_axis_tvalid <= '0';

            case state is
                --waiting state before doing something with the input
                when IDLE =>
                    if send_audio = '1' then
                        state <= SEND;
                    end if;

                --sending the data to the output
                when SEND =>
                    if s_axis_tvalid = '1' and s_axis_tready_int = '1'and m_axis_tready = '1' then 
                        if send_audio = '0' and s_axis_tlast = '1' then
                            state <= IDLE;
                        end if;
                        
                        m_axis_tdata <= s_axis_tdata;
                        m_axis_tvalid <= '1';
                    end if;
            end case;
        end if;
    end process;


    s_axis_tready <= s_axis_tready_int;


end architecture;
