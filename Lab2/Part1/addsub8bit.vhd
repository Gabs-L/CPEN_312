library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity addsub8bit is --entity declaration
	port(
	sw : in std_logic_vector(9 downto 0);
	key : in std_logic_vector(1 downto 0);
	ledr0 : out std_logic_vector(7 downto 0)
	);
end addsub8bit;

architecture behaviour of addsub8bit is --architecture declaration
	signal a : signed(7 downto 0);
	signal b : signed(7 downto 0);
	signal output : signed(8 downto 0); --extra bit for carry

begin
	process (key) --latch a and b from key1 and key0 press
	begin
		if key(1) = '0' then
			a <= signed(sw(7 downto 0));
		end if;
		if key(0) = '0' then
			b <= signed(sw(7 downto 0));
		end if;
	end process;
output <= ('0' & a) + ('0' & (not b) + 1) when sw(9) = '1' else ('0' & a) + ('0' & b);
ledr0 <= std_logic_vector(abs(output(7 downto 0))); --displaying absolute value of result
end architecture behaviour;