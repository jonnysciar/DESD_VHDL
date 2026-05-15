----------------------------------------------------------------------------------
-- Author: Gianmaria Napolitano 
-- 
-- Create Date: 13.05.2025
-- Design Name: 
-- Module Name: led_level_controller
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity led_level_controller is
    generic(
        NUM_LEDS : positive := 16;
        CHANNEL_LENGHT  : positive := 24;   -- 3 Byte for AXIS audio I2S
        refresh_time_ms : positive := 1;    -- refresh the LEDS every refresh_time_ms
        clock_period_ns : positive := 10    -- base time
    );
    Port (
        
        aclk			: in std_logic;
        aresetn			: in std_logic;
        
        led    : out std_logic_vector(NUM_LEDS-1 downto 0);

        s_axis_tvalid	: in std_logic;
        s_axis_tdata	: in std_logic_vector(CHANNEL_LENGHT-1 downto 0);
        s_axis_tlast    : in std_logic;
        s_axis_tready	: out std_logic

    );
end led_level_controller;

architecture Behavioral of led_level_controller is

begin

    -- Faccio sampling dei dati in ingresso ogni refresh_time_ms
    -- grazie ad una FSM che gestisce anche il protocollo AXIS.

    -- Da volume_controller mi arrivano pacchetti di dati con o senza tlast, 
    -- a seconda che questo sia destinato ad un canale o all'altro.

    -- Io ne prendo due alla volta, faccio la media dei due canali
    -- e aggiorno i LED di conseguenza.

    -- Devo capire con quale funzione mappare i valori di volume ai LED (0-16).

    -- Devo guardare il protocollo I2S per capire cosa mi arriva in ingresso e come interpretarlo.
    -- (vedi channel lenght, tlast, ecc.)

    -- Final value to be displayed on the LEDs, calculated as the average of the two channels
    signal average_value : unsigned(CHANNEL_LENGHT-1 downto 0) := (others => '0');

    process(aclk, aresetn)
    begin
        if aresetn = '0' then
            
        elsif rising_edge(aclk) then
            
        end if;
    end process; 
    

end Behavioral;
