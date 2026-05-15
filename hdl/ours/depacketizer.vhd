library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity depacketizer is
    generic (
        TDATA_WIDTH : integer := 8;             -- UART is 1 byte
        HEADER : std_logic_vector := X"69";
        FOOTER : std_logic_vector := X"42";
        CLK_FREQ_HZ : integer := 100000000      -- Use this for remaining_minutes, remaining_seconds
    );
    port (
        aclk   : in std_logic;
        aresetn : in std_logic;

        s_axis_tvalid	: in std_logic;
		s_axis_tdata	: in std_logic_vector(TDATA_WIDTH-1 downto 0);
		s_axis_tready	: out std_logic;

        send_audio : out std_logic;
        remaining_minutes : out std_logic_vector(6 downto 0);   -- MIN is unsigned from 0 to 60 (5 bits) but the binary_to_decimal required 7 bits, keep the last bit at 0
        remaining_seconds : out std_logic_vector(6 downto 0)    -- MIN is unsigned from 0 to 59 (5 bits) but the binary_to_decimal required 7 bits, keep the last bit at 0
    );
end entity depacketizer;

architecture rtl of depacketizer is
    signal send_audio_int : std_logic := '0';
    signal s_axis_tready_int : std_logic := '0';
    
    signal remaining_minutes_tmp : std_logic_vector(6 downto 0);
    signal remaining_seconds_tmp : std_logic_vector(6 downto 0);
    
    signal remaining_minutes_int : std_logic_vector(6 downto 0);
    signal remaining_seconds_int : std_logic_vector(6 downto 0);

    type READ_STATE is (HEADER_STATE, MINUTES_STATE, SECONDS_STATE, FOOTER_STATE);
    signal r_state : READ_STATE := HEADER_STATE;

    signal counter : integer := 0;

begin
    s_axis_tready <= s_axis_tready_int;
    send_audio <= send_audio_int;
    remaining_minutes <= remaining_minutes_int;
    remaining_seconds <= remaining_seconds_int;

    read_axis_data: process(aclk, aresetn)
	begin
		if aresetn = '0' then
            send_audio_int <= '0';
            remaining_minutes_int <= (others => '0');
            remaining_seconds_int <= (others => '0');

			s_axis_tready_int <= '0';
            r_state <= HEADER_STATE;
		elsif rising_edge(aclk) then
            s_axis_tready_int <= '1';

			if s_axis_tvalid = '1' and s_axis_tready_int = '1' then
                case r_state is
                    when HEADER_STATE =>
                        if s_axis_tdata = HEADER then
                            r_state <= MINUTES_STATE;
                        end if;
                    when MINUTES_STATE =>
                        if s_axis_tdata > X"3C" then
                            r_state <= HEADER_STATE;
                        else
                            remaining_minutes_tmp <= s_axis_tdata(remaining_minutes_tmp'length - 1 downto 0);
                            r_state <= SECONDS_STATE;
                        end if;
                    when SECONDS_STATE =>
                        if s_axis_tdata > X"3B"  then
                            r_state <= HEADER_STATE;
                        else
                            remaining_seconds_tmp <= s_axis_tdata(remaining_seconds_tmp'length - 1 downto 0);
                            r_state <= FOOTER_STATE;
                        end if;
                    when FOOTER_STATE =>
                        if send_audio_int = '0' and
                            (unsigned(remaining_minutes_tmp) /= 0 or unsigned(remaining_seconds_tmp) /= 0) then
                                send_audio_int <= '1';
                                remaining_minutes_int <= remaining_minutes_tmp;
                                remaining_seconds_int <= remaining_seconds_tmp;
                                s_axis_tready_int <= '0';
                                counter <= 0;
                        elsif send_audio_int = '1' and 
                            unsigned(remaining_minutes_tmp) = 0 and unsigned(remaining_seconds_tmp) = 0 then
                                send_audio_int <= '0';
                                remaining_minutes_int <= (others => '0');
                                remaining_seconds_int <= (others => '0');
                        end if;
                        r_state <= HEADER_STATE;
                end case;
			end if;

            if send_audio_int = '1' then
                counter <= counter + 1;
                if counter >= CLK_FREQ_HZ - 1 then
                    counter <= 0;
                    if unsigned(remaining_seconds_int) /= 0 then
                        remaining_seconds_int <= std_logic_vector(unsigned(remaining_seconds_int) - 1);
                    elsif unsigned(remaining_minutes_int) = 0 then
                        send_audio_int <= '0';
                    else
                        remaining_seconds_int <= std_logic_vector(to_unsigned(59, remaining_seconds_int'length));
                        remaining_minutes_int <= std_logic_vector(unsigned(remaining_minutes_int) - 1);
                    end if;
                end if;
            end if;
		end if;
	end process;

end architecture;
