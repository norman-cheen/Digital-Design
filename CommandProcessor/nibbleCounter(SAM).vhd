LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

ENTITY dataConversion IS
  PORT(
    dataReady: in std_logic;
    dataIn: in std_logic_vector(7 downto 0);
    TxDone: in std_logic;
    seqDone: in std_logic;
    rxDone: in std_logic;
    aNNN_ready: in std_logic;
    dataOut: out std_logic_vector(7 downto 0);
    )
END dataConversion;

ARCHITECTURE arc OF dataConversion IS
  SIGNAL convDone: std_logic;   --active HIGH
  TYPE state_type IS (INIT, CONVERSION, SET_FIRST_DIGIT, SEND_FIRST_DIGIT, SEND_SECOND_DIGIT,SET_SECOND_DIGIT,SET_SPACE,SEND_SPACE,WAIT_SEND,ECHO_COMMAND);
  SIGNAL curState, nextState : state_type;
  
BEGIN
nextState:PROCESS(curState,DataReady,convDone, TxDone)
  BEGIN
    CASE curState IS
      WHEN INIT =>
        IF DataReady = '1' THEN
          nextState <= CONVERSION;
        ELSIF rxDone = '1' THEN
          nextState <= ECHO_COMMAND;
        ELSE
          nextState <= INIT;
        END IF;
        
      WHEN ECHO_COMMAND =>
        nextState <= SEND_COMMAND;
        
      WHEN SEND_COMMAND =>
         
        nextState <= INIT; 
          
      WHEN CONVERSION =>
        IF convDone = '1' AND txDone = '1' THEN
          nextState <= SEND_FIRST_DIGIT;
        ELSE
          nextState <= CONVERSION;
        END IF;
        
      WHEN SEND_FIRST_DIGIT =>
        nextState <= SET_SECOND_DIGIT; 
        
      WHEN SET_SECOND_FIGIT =>
        IF txDone = '1' THEN
          nextState <= SEND_SECOND_DIGIT;
        ELSE
          nextState <= SET_SECOND_DIGIT;
        END IF;
           
        
      WHEN SEND_SECOND_DIGIT =>
        nextState <= SET_SPACE;
        
      WHEN SET_SPACE =>
        IF txDone = '1' THEN 
          nextState <= SEND_SPACE;
        ELSE 
          nextState <= SET_SPACE;
        END IF;
          
      WHEN SEND_SPACE =>
        nextState <= WAIT_SEND;
      
      WHEN WAIT_SEND =>
        IF txDone ='1' THEN
          nextState <= INIT;
        ELSE 
          nextState <= WAIT_SEND;
        END IF;
        
    END CASE;
  END PROCESS;


combi_out:PROCESS(curState)
  BEGIN
    CASE curState IS
      WHEN INIT =>
        TxNow <= '0';
        convDone <= '0';
      WHEN 
        

