library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.">"; -- overload the < operator for std_logic_vectors
use ieee.std_logic_unsigned."="; -- overload the = operator for std_logic_vectors
use work.common_pack.all;

entity comparator is
	port (
		data1: in std_logic_vector(7 downto 0);
		data2: in std_logic_vector(7 downto 0);
		grtThan: out std_logic;
		equal: out std_logic
	 );
end comparator;

architecture unsigned_int of comparator is
begin
  process (data1, data2)
    begin
      grtThan <= '0';
      equal <= '0';
      if data1>data2 then
        grtThan <='1';
      elsif data1=data2 then
        equal <= '1';
      end if  ;
    end process;
end unsigned_int;

