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
  SIGNAL firstDigitASCII, secondDigitASCII : std_logic_vector(7 downto 0);
  
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
        nextState <= SEND;
        
      
          
      WHEN CONVERSION =>
        IF convDone = '1' AND txDone = '1' THEN
          nextState <= SEND_FIRST_DIGIT;
        ELSE
          nextState <= CONVERSION;
        END IF;
        
      WHEN SEND_FIRST_DIGIT =>
        nextState <= SET_SECOND_DIGIT; 
        
      WHEN SET_SECOND_DIGIT =>
        IF txDone = '1' THEN
          nextState <= SEND_SECOND_DIGIT;
        ELSE
          nextState <= SET_SECOND_DIGIT;
        END IF;
           
        
      WHEN SEND_SECOND_DIGIT =>
        nextState <= SET_SPACE;
        
      WHEN SET_SPACE =>
        IF txDone = '1' THEN 
          nextState <= SEND;
        ELSE 
          nextState <= SET_SPACE;
        END IF;
          
      WHEN SEND =>  --Anytime we need to send something and the next state is INIT we just use SEND, to reduce the number of total states
        nextState <= INIT;
      
        
    END CASE;
  END PROCESS;


combi_out:PROCESS(curState)
  BEGIN
    CASE curState IS
      WHEN INIT =>
        TxNow <= '0';
        convDone <= '0';
      WHEN 
        
        
data_conversion:PROCESS(curState,dataIn)
  SIGNAL firstDigit,secondDigit : std_logic_vector(3 downto 0); --firstDigit is the most significant digit in the hexadecimal number pair (bit 4 to 7), the first digit to be sent
  BEGIN
    IF curState=CONVERSION THEN
      firstDigit <= dataIn(7 downto 4);
      secondDigit <= dataIn(3 downto 0);
      CASE firstDigit IS
        WHEN "0000" => firstDigitASCII <= "00110000";
        WHEN "0001" => firstDigitASCII <= "00110001";
        WHEN "0010" => firstDigitASCII <= "00110010";
        WHEN "0011" => firstDigitASCII <= "00110011";
        WHEN "0100" => firstDigitASCII <= "00110100";
        WHEN "0101" => firstDigitASCII <= "00110101";
        WHEN "0110" => firstDigitASCII <= "00110110";
        WHEN "0111" => firstDigitASCII <= "00110111";
        WHEN "1000" => firstDigitASCII <= "00111000";
        WHEN "1001" => firstDigitASCII <= "00111001";
        WHEN "1010" => firstDigitASCII <= "01000001";
        WHEN "1011" => firstDigitASCII <= "01000010";
        WHEN "1100" => firstDigitASCII <= "01000011";
        WHEN "1101" => firstDigitASCII <= "01000100";
        WHEN "1110" => firstDigitASCII <= "01000101";
        WHEN "1111" => firstDigitASCII <= "01000110";
      END CASE;
      
      CASE secondDigit IS
        WHEN "0000" => secondDigitASCII <= "00110000";
        WHEN "0001" => secondDigitASCII <= "00110001";
        WHEN "0010" => secondDigitASCII <= "00110010";
        WHEN "0011" => secondDigitASCII <= "00110011";
        WHEN "0100" => secondDigitASCII <= "00110100";
        WHEN "0101" => secondDigitASCII <= "00110101";
        WHEN "0110" => secondDigitASCII <= "00110110";
        WHEN "0111" => secondDigitASCII <= "00110111";
        WHEN "1000" => secondDigitASCII <= "00111000";
        WHEN "1001" => secondDigitASCII <= "00111001";
        WHEN "1010" => secondDigitASCII <= "01000001";
        WHEN "1011" => secondDigitASCII <= "01000010";
        WHEN "1100" => secondDigitASCII <= "01000011";
        WHEN "1101" => secondDigitASCII <= "01000100";
        WHEN "1110" => secondDigitASCII <= "01000101";
        WHEN "1111" => secondDigitASCII <= "01000110";
      END CASE;
      
  ELSE 
    firstDigit <= TO_UNSIGNED(3 downto 0);
    secondDigit <= TO_UNSIGNED (3 downto 0);
    firstDigitASCII <= TO_UNSIGNED(7 downto 0);
    secondDigitASCII <= TO_UNSIGNED(7 downto 0);
    
  END IF;
