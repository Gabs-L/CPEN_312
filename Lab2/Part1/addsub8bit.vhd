library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--entity declaration
entity addsub8bit is
	port
	(
		sw : in std_logic_vector(9 downto 0);
		key : in std_logic_vector(1 downto 0);
		ledr0 : out std_logic_vector(7 downto 0)
	);
end addsub8bit;

--architecture declaration
architecture behaviour of addsub8bit is
 signal a, b : unsigned(7 downto 0);
	 signal bMinus : unsigned(7 downto 0); --if sw9 is set to subtract, add this instead of b
	 signal carry : std_logic;
	 signal sum : unsigned(8 downto 0);
begin

--latch a from key1 press
process (key(1))
begin
	if falling_edge(key(1)) then
		a <= unsigned(sw(7 downto 0));
	end if;
end process;

--latch b from key0 press
process (key(0))
begin
	if falling_edge(key(0)) then
		b <= unsigned(sw(7 downto 0));
	end if;
end process;

--add/suntract selection from sw9 state
bMinus <= b when sw(9) = '0' else not b;
carry <= sw(9);
sum <= ('0'&a) + ('0'&bMinus) + unsigned'("0000000" & carry);

--displaying result
ledr0 <= std_logic_vector(sum(7 downto 0));
end architecture behaviour;
