----------------------------------------------------------------------------
-- BCD number register
-- author: Nik Shimah
-- 1. Receive the data from Rx, take the BCD(LSB) put it in an array, MSB first 
-- i.e BCD(2) <= rxData(3 downto 0) 
-- 2. Store the NNN byte by byte into the BCD_array(2 downto 0)
-- 3. assign start <= '1' once the array has complete. 

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.common_pack.all;

entity BCD_register is
  port (
        rxData:			in std_logic_vector (7 downto 0); -- data from Rx
        clk : in std_logic; -- CLOCK
        reset: in std_logic;
        start : out std_logic; -- start signal for DataProc
        numWords_bcd : out BCD_ARRAY_TYPE(2 downto 0) --send numWords to DataProc
        );
end;

architecture BCD_arch of BCD_register is 

  --SIGNALS
  type state_type is (idle, firstN, secondN, thirdN);	
  signal curState, nextState: state_type;
  signal ensr : std_logic; -- enable from pattern recogniser
  
begin

  NextState_logic: process (curState, ensr)
  begin  
    case curState is
     when idle =>
       numWords_bcd(0) <= "0000";
       numWords_bcd(1) <= "0000";
       numWords_bcd(2) <= "0000";
       if ensr = '1' then
         nextState <= firstN;
       else 
         nextState <= idle;
       end if;
        
     when firstN =>
       numWords_bcd(2) <= rxData(3 downto 0);
       if ensr = '1' then
         nextState <= secondN;
       else 
         nextState <= idle;
       end if;
       
     when secondN =>
       numWords_bcd(1) <= rxData(3 downto 0);
       if ensr = '1' then
         nextState <= thirdN;
       else 
         nextState <= idle;
       end if;
           
     when thirdN =>
       numWords_bcd(0) <= rxData(3 downto 0);
       start <= '1';
       if ensr = '1' then
         numWords_bcd(0) <= "0000";
         numWords_bcd(1) <= "0000";
         numWords_bcd(2) <= "0000";
         nextState <= firstN;
       else 
         nextState <= idle;
       end if;
       
      when OTHERS => 
        nextState <= idle;
        
      end case;
    end process;
      
  -- State Registers
  seq_state: process (clk, reset)
  begin
    if reset = '0' then
      curState <= idle;
    elsif clk'EVENT and clk='1' then
      curState <= nextState;
    end if;
  end process; -- seq
  
end;
