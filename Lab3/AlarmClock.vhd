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
--	
	--clock divider signals
	signal freq : integer := 100000;-- 49999999 for 1s
	signal count : integer := 0;
	signal tick : std_logic := '0';
	
	signal s : integer range 0 to 59 := 0;
	signal m : integer range 0 to 59 := 0;
	signal h : integer range 1 to 12 := 12;
--	signal ispm, ispm_bf : std_logic;
	
	signal s0, s1 : std_logic_vector(3 downto 0) := (others => '0');
	signal m0, m1 : std_logic_vector(3 downto 0) := (others => '0');
	signal h0 : std_logic_vector(3 downto 0) := std_logic_vector(to_unsigned(2,4));
	signal h1 : std_logic_vector(3 downto 0) := std_logic_vector(to_unsigned(1,4));
	
	--debounce stuffs:
	signal key_sync0 : std_logic_vector(3 downto 0) := (others => '1');
	signal key_db : std_logic_vector(3 downto 0) := (others =>  '1');

	begin
		process(clk)
		begin
		if rising_edge(clk) then 
			key_sync0 <= key_sync0(2 downto 0) & keys(0);
			if key_sync0 = "0000" then
				key_db(0) <= '0';  -- stable LOW → debounced LOW
			elsif key_sync0 = "1111" then
				key_db(0) <= '1';  -- stable HIGH → debounced HIGH
			end if;
			if key_db(0) = '0' then
				s <= 0;
				m <= 0;
				h <= 12;
				count <= 0;
				tick <= '0';
			else
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
