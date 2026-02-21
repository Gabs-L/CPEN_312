library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity AlarmClock is
	port(
	clk : in std_logic;
	switches : in std_logic_vector(9 downto 0);
	keys : in std_logic_vector(3 downto 0);
	hex0 : out std_logic_vector(0 to 6);
	hex1 : out std_logic_vector(0 to 6);
	hex2 : out std_logic_vector(0 to 6);
	hex3 : out std_logic_vector(0 to 6);
	hex4 : out std_logic_vector(0 to 6);
	hex5 : out std_logic_vector(0 to 6)
	);
end AlarmClock;

architecture a of AlarmClock is
	component bcd_7seg is --bcd to 7 segment component declaration
		port(
			bcd : in std_logic_vector(3 downto 0);
			display : out std_logic_vector(0 to 6)
		);
	end component;
	
	--clock divider signals
	signal freq : integer := 100000;-- 49999999 for 1s
	signal count : integer := 0;
	signal tick : std_logic := '0';
	
	-- run state signals
	signal s : integer range 0 to 59 := 0;
	signal m : integer range 0 to 59 := 0;
	signal h : integer range 1 to 12 := 12;
--	signal ispm, ispm_bf : std_logic;

	-- alarm state signals
	signal as : integer range 0 to 59 := 0;
	signal am : integer range 0 to 59 := 0;
	signal ah : integer range 1 to 12 := 12;
	
	signal s0, s1 : std_logic_vector(3 downto 0) := (others => '0');
	signal m0, m1 : std_logic_vector(3 downto 0) := (others => '0');
	signal h0, h1 : std_logic_vector(3 downto 0) := (others => '0');
	
	--debounce stuffs:
	type sync_arr is array (3 downto 0) of std_logic_vector(3 downto 0);
	signal key_sync : sync_arr := (others => (others => '1'));
	signal key_db : std_logic_vector(3 downto 0) := (others =>  '1');
	signal key_prev : std_logic_vector(3 downto 0) := (others =>  '1');
--	signal key_press : std_logic_vector(3 downto 0);
	
	type states is (run, set_time, set_alarm);
	signal state : states := run;
	signal state_prev : states := run;
	
begin
	process(clk)
	
	variable sbuff, mbuff, hbuff : integer;
	variable sprev, mprev, hprev : integer;
	
	begin
	
	--
	-- debounce keys with for-loop
	--
		if rising_edge(clk) then 
			key_prev <= key_db;
			for i in 0 to 3 loop
				key_sync(i) <= key_sync(i) (2 downto 0) & keys(i);
				if key_sync(i) = "0000" then
					key_db(i) <= '0';  -- stable LOW → debounced LOW
				elsif key_sync(i) = "1111" then
					key_db(i) <= '1';  -- stable HIGH → debounced HIGH
				end if;
			end loop;
			
			--
			-- detect reset and latching
			--
			if key_db(0) = '0' then
				s <= 0;
				m <= 0;
				h <= 12;
				count <= 0;
				tick <= '0';
				
			--
			-- state selection
			--
			else
				if switches(9) = '1' then
					state <= set_time;
				elsif switches(7) = '1' then
					state <= set_alarm;
				else
					state <= run;
				end if;
				state_prev <= state;
				
				--
				--state logic and display
				--
				case state is
					when run =>
						if state_prev = set_alarm then
							s <= sprev;
							m <= mprev;
							h <= hprev;
						end if;
						
						if count = freq then
							count <= 0;
							tick <= '1';
						else
							count <= count+1;
							tick <= '0';
					end if;
					
					if tick = '1' then
						if s >= 59 then 
							s <= 0;
							if m >= 59 then
								m <= 0;
								if h >= 12 then
									h <= 1;
								else
									h <= h+1;
								end if;
							else
								m <= m+1;
							end if;
						else
							s <= s+1;
						end if;
					end if;
					
				--
				-- set time
				--
				when set_time =>
					if key_db(1) = '0' and key_prev(1) = '1' then
						sbuff := to_integer(unsigned(switches(5 downto 0)));
						if (sbuff >= 0) and (sbuff <= 59) then
							s <= sbuff;
						end if;
					end if;
					if key_db(2) = '0' and key_prev(2) = '1' then
						mbuff := to_integer(unsigned(switches(5 downto 0)));
						if (mbuff >= 0) and (mbuff <= 59) then
							m <= mbuff;
						end if;
					end if;
					if key_db(3) = '0' and key_prev(3) = '1' then
						hbuff := to_integer(unsigned(switches(5 downto 0)));
						if (hbuff >= 1) and (hbuff <= 12) then
							h <= hbuff;
						end if;
					end if;
				--set alarm =>
				when set_alarm =>
					if state_prev /= set_alarm then
						sprev := s;
						mprev := m;
						hprev := h;
					end if;
					if key_db(1) = '0' and key_prev(1) = '1' then
						sbuff := to_integer(unsigned(switches(5 downto 0)));
						if (sbuff >= 0) and (sbuff <= 59) then
							as <= sbuff;
						end if;
					end if;
					if key_db(2) = '0' and key_prev(2) = '1' then
						mbuff := to_integer(unsigned(switches(5 downto 0)));
						if (mbuff >= 0) and (mbuff <= 59) then
							am <= mbuff;
						end if;
					end if;
					if key_db(3) = '0' and key_prev(3) = '1' then
						hbuff := to_integer(unsigned(switches(5 downto 0)));
						if (hbuff >= 1) and (hbuff <= 12) then
							ah <= hbuff;
						end if;
					end if;
					s0 <= std_logic_vector(to_unsigned(as mod 10, 4)); -- update display for alarm set 
					s1 <= std_logic_vector(to_unsigned(as / 10,  4));
					m0 <= std_logic_vector(to_unsigned(am mod 10, 4));
					m1 <= std_logic_vector(to_unsigned(am / 10,  4));
					h0 <= std_logic_vector(to_unsigned(ah mod 10, 4));
					h1 <= std_logic_vector(to_unsigned(ah / 10,  4));
			end case;
		end if;
		s0 <= std_logic_vector(to_unsigned(s mod 10, 4));
		s1 <= std_logic_vector(to_unsigned(s/10, 4));
		m0 <= std_logic_vector(to_unsigned(m mod 10, 4));
		m1 <= std_logic_vector(to_unsigned(m/10, 4));
		h0 <= std_logic_vector(to_unsigned(h mod 10, 4));
		h1 <= std_logic_vector(to_unsigned(h/10, 4));
		end if;
	end process;
					
	hex0_disp: bcd_7seg port map(bcd => s0, display => hex0);
	hex1_disp: bcd_7seg port map(bcd => s1, display => hex1);
	hex2_disp: bcd_7seg port map(bcd => m0, display => hex2);
	hex3_disp: bcd_7seg port map(bcd => m1, display => hex3);
	hex4_disp: bcd_7seg port map(bcd => h0, display => hex4);
	hex5_disp: bcd_7seg port map(bcd => h1, display => hex5);
end a;