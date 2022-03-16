LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

ENTITY dataConversion IS
  PORT(
    dataReady: in std_logic;
    dataIn: in std_logic_vector(7 downto 0);
    TxDone: in std_logic;
    seqDone: in std_logic;
    dataOut: out std_logic_vector(7 downto 0);
    )
END dataConversion;

ARCHITECTURE arc OF dataConversion IS
  SIGNAL convDone: std_logic;   --active HIGH
  TYPE state_type IS (INIT, CONVERSION, SEND);
  SIGNAL curState, nextState : state_type;
  
BEGIN
nextState:PROCESS(curState,DataReady,convDone, TxDone)
  BEGIN
    CASE curState IS
      WHEN INIT =>
        IF DataReady = '1' THEN
          nextState <= CONVERSION;
        ELSE
          nextState <= INIT;
        END IF;
          
      WHEN CONVERSION =>
        IF convDone = '1' THEN
          nextState <= SEND;
        ELSE
          nextState <= CONVERSION;
        END IF;
        
      WHEN SEND =>
        IF TxDone = '0' THEN
          nextState <= SEND;
        ELSE
          nextState <= INIT;
        END IF 
        
    END CASE;
  END PROCESS;


combi_out:PROCESS(curState)
  BEGIN
    CASE curState IS
      WHEN INIT =>
        TxNow <= '0';
        convDone <= '0';
      WHEN 
        
    
    
  
    
  
    
    

