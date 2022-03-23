LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

ENTITY dataConversion IS
  PORT(
    clk:in std_logic;
    reset:in std_logic;
    dataReady: in std_logic;
    dataIn: in std_logic_vector(7 downto 0);  --data from data processor
    command: in std_logic_vector(7 downto 0);
    txDone: in std_logic;
    seqDone: in std_logic;
    rxDone: in std_logic;
    aNNN_ready: in std_logic;
    dataOut: out std_logic_vector(7 downto 0);
    txNow : out std_logic
  );
END dataConversion;

ARCHITECTURE arc OF dataConversion IS
  SIGNAL resetCounter,resetRegister, Count_en,R1_en,R2_en: std_logic;   --active HIGH
  TYPE state_type IS (INIT, CONVERSION, SET_FIRST_DIGIT, SEND_FIRST_DIGIT, SEND_SECOND_DIGIT,SET_SECOND_DIGIT,SET_SPACE,SEND_SPACE,ECHO_COMMAND,SEND_COMMAND,SET_NEW_LINE,SEND_NEW_LINE);
  SIGNAL curState, nextState : state_type;
  SIGNAL firstDigitASCII, secondDigitASCII, reg_firstDigitASCII, reg_secondDigitASCII : std_logic_vector(7 downto 0); --initialised and values defined in conversion process
  SIGNAL count : integer; --initialised by resetCounter
  
  
  
BEGIN
combi_nextState:PROCESS(curState,DataReady,txDone,rxDone,aNNN_ready,Count)
  BEGIN
    IF reset = '1' THEN
      nextState <= INIT;
    ELSE
      CASE curState IS
        WHEN INIT =>
          IF DataReady = '1' THEN
            nextState <= CONVERSION;
          ELSIF rxDone = '1' THEN
            nextState <= ECHO_COMMAND;
          ELSIF aNNN_ready ='1' THEN
            nextState <= SET_NEW_LINE;
          ELSE
            nextState <= INIT;
          END IF;
        
        WHEN ECHO_COMMAND =>
          IF txDone ='1' THEN
            nextState <= SEND_COMMAND;
          ELSE
            nextState <= ECHO_COMMAND;
          END IF;
        
        WHEN SEND_COMMAND =>
          nextState <= INIT;
      
        WHEN SET_NEW_LINE =>
          IF txDone='1' THEN
            nextState <= SEND_NEW_LINE;
          ELSE
            nextState <= SET_NEW_LINE;
          END IF;
        
        WHEN SEND_NEW_LINE =>
          nextState <= INIT;
          
        WHEN CONVERSION =>
          IF Count>=2 AND txDone = '1' THEN
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
            nextState <= SEND_SPACE;
          ELSE 
            nextState <= SET_SPACE;
          END IF;
          
        WHEN SEND_SPACE =>  --Anytime we need to send something and the next state is INIT we just use SEND, to reduce the number of total states
          nextState <= INIT;
      
        
      END CASE;
    END IF;
  END PROCESS;


combi_out:PROCESS(curState,command,reg_firstDigitASCII,reg_secondDigitASCII)
  BEGIN
    CASE curState IS
      WHEN INIT =>
        txNow <= '0';
        resetCounter <='1';
        resetRegister <='1';
        Count_en <= '0';
        R1_en <= '0';
        R2_en <= '0';
        dataOut <= TO_UNSIGNED(0,8);
        
      WHEN ECHO_COMMAND =>
        txNow <= '0';
        resetCounter <= '0';
        resetRegister <= '0';
        Count_en <= '0';
        R1_en <= '0';
        R2_en <= '0';
        dataOut <= command;
        
      WHEN SEND_COMMAND =>
        txNow <= '1';
        resetCounter <= '0';
        resetRegister <= '0';
        Count_en <= '0';
        R1_en <= '0';
        R2_en <= '0';
        dataOut <= command;
        
      WHEN CONVERSION =>
        txNow <= '0';
        resetCounter <= '0';
        resetRegister <= '0';
        Count_en <= '1';
        R1_en <= '1';
        R2_en <= '1';
        dataOut <= reg_firstDigitASCII;
        
      WHEN SEND_FIRST_DIGIT =>
        txNow <= '1';
        resetCounter <= '0';
        resetRegister <= '0';
        Count_en <= '0';
        R1_en <= '0';
        R2_en <= '0';
        dataOut <= reg_firstDigitASCII;
        
      WHEN SET_SECOND_DIGIT =>
        txNow <= '0';
        resetCounter <= '0';
        resetRegister <= '0';
        Count_en <= '0';
        R1_en <= '0';
        R2_en <= '0';
        dataOut <= reg_secondDigitASCII;
        
      WHEN SEND_SECOND_DIGIT =>
        txNow <= '1';
        resetCounter <= '0';
        resetRegister <= '0';
        Count_en <= '0';
        R1_en <= '0';
        R2_en <= '0';
        dataOut <= reg_secondDigitASCII;
        
      WHEN SET_SPACE =>
        txNow <= '0';
        resetCounter <= '0';
        resetRegister <= '0';
        Count_en <= '0';
        R1_en <= '0';
        R2_en <= '0';
        dataOut <= "00100000";  --ASCII code of space
        
      WHEN SEND_SPACE =>
        txNow <= '1';
        resetCounter <= '0';
        resetRegister <='0';
        Count_en <= '0';
        R1_en <= '0';
        R2_en <= '0';
        dataOut <= "00100000"; 
        
      WHEN SET_NEW_LINE =>
        txNow <= '0';
        resetCounter <= '0';
        resetRegister <='0';
        Count_en <= '0';
        R1_en <= '0';
        R2_en <= '0';
        dataOut <= "00001010"; --Line feed (\n) ASCII code
        
      WHEN SEND_NEW_LINE =>
        txNow <= '1';
        resetCounter <= '0';
        resetRegister <='0';
        Count_en <= '0';
        R1_en <= '0';
        R2_en <= '0';
        dataOut <= "00001010";
        
      WHEN OTHERS =>
        txNow <= '0';
        resetCounter <= '0';
        resetRegister <='0';
        Count_en <= '0';
        R1_en <= '0';
        R2_en <= '0';
        dataOut <= TO_UNSIGNED(0,8);
        
    END CASE;
  END PROCESS;
        
        
        
data_conversion:PROCESS(curState,dataIn)
  VARIABLE firstDigit,secondDigit : std_logic_vector(3 downto 0); --firstDigit is the most significant digit in the hexadecimal number pair (bit 4 to 7), the first digit to be sent
  BEGIN
      IF curState=CONVERSION THEN
      firstDigit := dataIn(7 downto 4);
      secondDigit := dataIn(3 downto 0);
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
      firstDigit := TO_UNSIGNED(0,4);
      secondDigit := TO_UNSIGNED(0,4);
      firstDigitASCII <= TO_UNSIGNED(0,8);
      secondDigitASCII <= TO_UNSIGNED(0,8);
    
    END IF;
  END PROCESS;
  
firstDigitRegister: PROCESS(resetRegister,clk)
  BEGIN
    IF resetRegister = '1' THEN
      reg_firstDigitASCII <= TO_UNSIGNED(0,8);
    ELSIF clk'event AND clk='1' THEN
      IF R1_en = '1' THEN
        reg_firstDigitASCII <= firstDigitASCII; 
      END IF;
    END IF;
  END PROCESS;      
  
secondDigitRegister: PROCESS(resetRegiser,clk)
  BEGIN
    IF resetRegister = '1' THEN
      reg_secondDigitASCII <= TO_UNSIGNED(0,8);
    ELSIF clk'event AND clk='1' THEN
      IF R2_en = '1' THEN
        reg_secondDigitASCII <= secondDigitASCII; 
      END IF;
    END IF;
  END PROCESS;      
      
counter:PROCESS(resetCounter,clk)  --counter is to make sure the FSM stays in the conversion state for at least 2 clock cycles so that the converted numbers could be registered
  BEGIN                            --2 cycles is needed as the conversion could only be completed a couple delta delays after entering the conversion state 
		IF resetCounter = '1'  THEN    --This means that the register whose input is only transparent to the output at the rising edge would not be able to catch the converted numbers
		  Count <= 0;                  --if it only stays a single clock cycle. 
		ELSIF clk'EVENT and clk='1' THEN
		  IF Count_en='1' THEN -- enable
		    Count <= Count + 1;
		  END IF;
		END IF;
  END PROCESS;
  
seq_state : PROCESS(clk)  --sequential state updating
  BEGIN
    IF clk'EVENT and clk='1' THEN
      curState <= nextState;
    END IF;
  END PROCESS;
      
      
        

