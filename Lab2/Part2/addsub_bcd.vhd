library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity addsub_bcd is
	port(
	clck : in std_logic;
	sw : in std_logic_vector(9 downto 0); --switch inputs
	keys : in std_logic_vector(1 downto 0); --latching keys
	hex0 : out std_logic_vector(0 to 6); --7seg display 0
	hex1 : out std_logic_vector(0 to 6); --7seg display 1
	hex2 : out std_logic_vector(0 to 6); --7seg display 2
	hex3 : out std_logic_vector(0 to 6); --7seg display 3
	hex4 : out std_logic_vector(0 to 6); --7seg display 4
	hex5 : out std_logic_vector(0 to 6); --7seg display 5
	ledr3 : out std_logic --overflow indicator
	);
end addsub_bcd;

architecture a of addsub_bcd is

	component bcd_7seg is
	port(
		bcd : in std_logic_vector(3 downto 0);
		display : out std_logic_vector(0 to 6)
		);
	end component;
	
	component addsubber is
	port(
		a : in std_logic_vector(3 downto 0);
		b : in std_logic_vector(3 downto 0);
		sub : in std_logic;
		c_in : in  std_logic;
		c : out std_logic;
		sum : out std_logic_vector(3 downto 0)
		);
	end component;
	
	signal a1 : std_logic_vector(3 downto 0);
	signal a0 : std_logic_vector(3 downto 0);
	signal b1 : std_logic_vector(3 downto 0);
	signal b0 : std_logic_vector(3 downto 0);
	signal r1 : std_logic_vector(3 downto 0);
	signal r0 : std_logic_vector(3 downto 0);
	signal temp_r0 : std_logic_vector(3 downto 0);
	signal temp_r1 : std_logic_vector(3 downto 0);
	signal sub_mode : std_logic;
	signal o : std_logic;
	signal carry_lsb : std_logic;
	signal carry_msb : std_logic;

	signal key0_prev : std_logic := '1';
	signal key1_prev : std_logic := '1';
	
begin
	process(clck)
	begin
		if rising_edge(clck) then
			if key1_prev = '1' and keys(1) = '0' then
				a0 <= sw(3 downto 0);
				a1 <= sw(7 downto 4);
			end if;
			key1_prev <= keys(1);
			if key0_prev = '1' and keys(0) = '0' then
				b0 <= sw(3 downto 0);
				b1 <= sw(7 downto 4);
			end if;
			key0_prev <= keys(0);
			sub_mode <= sw(9);
		end if;
	end process;
	
	add_lsb: addsubber port map(
	a => a0,
	b => b0,
	sub => sub_mode,
	c_in => sub_mode,
	c => carry_lsb,
	sum => temp_r0
	);
	
	add_msb: addsubber port map(
	a => a1,
	b => b1,
	sub => sub_mode,
	c_in => carry_lsb,
	c => carry_msb,
	sum => temp_r1
	);

	process(clck)
		variable result_val : integer;
		variable temp_val : integer;
	begin
		if rising_edge(clck) then
			r1 <= temp_r1;
			r0 <= temp_r0;
			o <= '0';
			if sub_mode = '1' then
				if carry_msb = '0' then
					temp_val := to_integer(unsigned(temp_r1)) * 10 + to_integer(unsigned(temp_r0));
					result_val := 100 - temp_val;
					r1 <= std_logic_vector(to_unsigned(result_val / 10, 4));
					r0 <= std_logic_vector(to_unsigned(result_val mod 10, 4));
					o <= '0';
				end if;
			else
				if carry_msb = '1' then
					o <= '1';
					r1 <= temp_r1;
					r0 <= temp_r0;
				end if;
			end if;
		end if;
	end process;

	ledr3 <= o;
	hex5_disp: bcd_7seg port map(bcd => a1, display => hex5);
	hex4_disp: bcd_7seg port map(bcd => a0, display => hex4);
	hex3_disp: bcd_7seg port map(bcd => b1, display => hex3);
	hex2_disp: bcd_7seg port map(bcd => b0, display => hex2);
	hex1_disp: bcd_7seg port map(bcd => r1, display => hex1);
	hex0_disp: bcd_7seg port map(bcd => r0, display => hex0);
end a;