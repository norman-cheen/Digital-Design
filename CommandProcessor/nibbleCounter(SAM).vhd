LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

ENTITY dataConversion IS
  PORT(
    clk:in std_logic;
    reset:in std_logic;
    dataReady: in std_logic;
    byte: in std_logic_vector(7 downto 0);  --data from data processor
    rxData: in std_logic_vector(7 downto 0); --command received from rx unit
    txDone: in std_logic; 
    rxDone: in std_logic;
    aNNN_valid: in std_logic;
    txData: out std_logic_vector(7 downto 0); --data sent to tx unit
    txNow : out std_logic;
    start : out std_logic
  );
END dataConversion;

ARCHITECTURE arc OF dataConversion IS
  SIGNAL resetCounter,resetRegister, Count_en,R1_en,R2_en,reg_aNNN_valid,reset_aNNN_valid: std_logic;   --active HIGH
  TYPE state_type IS (INIT, CONVERSION, SEND_FIRST_DIGIT, SEND_SECOND_DIGIT,SET_SECOND_DIGIT,SET_SPACE,SEND_SPACE,ECHO_COMMAND,SEND_COMMAND,SET_NEW_LINE,SEND_NEW_LINE,SEND_START);
  SIGNAL curState, nextState : state_type;
  SIGNAL firstDigitASCII, secondDigitASCII, reg_firstDigitASCII, reg_secondDigitASCII : std_logic_vector(7 downto 0); --initialised and values defined in conversion process
  SIGNAL count : integer; --initialised by resetCounter
  
  
  
BEGIN
combi_nextState:PROCESS(curState,DataReady,txDone,rxDone,reg_aNNN_valid,Count)
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
          ELSIF reg_aNNN_valid ='1' THEN
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
          nextState <= SEND_START;
          
        WHEN SEND_START =>
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
          nextState <= SEND_START;
      
        
      END CASE;
    END IF;
  END PROCESS;


combi_out:PROCESS(curState,rxData,reg_firstDigitASCII,reg_secondDigitASCII)
  BEGIN
    CASE curState IS
      WHEN INIT =>
        txNow <= '0';
        resetCounter <='1';
        resetRegister <='1';
        Count_en <= '0';
        R1_en <= '0';
        R2_en <= '0';
        txData <= "00000000";
        start <= '0';
        reset_aNNN_valid <= '1';
        
      WHEN ECHO_COMMAND =>
        txNow <= '0';
        resetCounter <= '0';
        resetRegister <= '0';
        Count_en <= '0';
        R1_en <= '0';
        R2_en <= '0';
        txData <= rxData;
        start <= '0';
        reset_aNNN_valid <= '0';
        
      WHEN SEND_COMMAND =>
        txNow <= '1';
        resetCounter <= '0';
        resetRegister <= '0';
        Count_en <= '0';
        R1_en <= '0';
        R2_en <= '0';
        txData <= rxData;
        start <= '0';
        reset_aNNN_valid <= '0';
        
      WHEN CONVERSION =>
        txNow <= '0';
        resetCounter <= '0';
        resetRegister <= '0';
        Count_en <= '1';
        R1_en <= '1';
        R2_en <= '1';
        txData <= reg_firstDigitASCII;
        start <= '0';
        reset_aNNN_valid <= '0';
        
      WHEN SEND_FIRST_DIGIT =>
        txNow <= '1';
        resetCounter <= '0';
        resetRegister <= '0';
        Count_en <= '0';
        R1_en <= '0';
        R2_en <= '0';
        txData <= reg_firstDigitASCII;
        start <= '0';
        reset_aNNN_valid <= '0';
        
      WHEN SET_SECOND_DIGIT =>
        txNow <= '0';
        resetCounter <= '0';
        resetRegister <= '0';
        Count_en <= '0';
        R1_en <= '0';
        R2_en <= '0';
        txData <= reg_secondDigitASCII;
        start <= '0';
        reset_aNNN_valid <= '0';
        
      WHEN SEND_SECOND_DIGIT =>
        txNow <= '1';
        resetCounter <= '0';
        resetRegister <= '0';
        Count_en <= '0';
        R1_en <= '0';
        R2_en <= '0';
        txData <= reg_secondDigitASCII;
        start <= '0';
        reset_aNNN_valid <= '0';
        
      WHEN SET_SPACE =>
        txNow <= '0';
        resetCounter <= '0';
        resetRegister <= '0';
        Count_en <= '0';
        R1_en <= '0';
        R2_en <= '0';
        txData <= "00100000";  --ASCII code of space
        start <= '0';
        reset_aNNN_valid <= '0';
        
      WHEN SEND_SPACE =>
        txNow <= '1';
        resetCounter <= '0';
        resetRegister <='0';
        Count_en <= '0';
        R1_en <= '0';
        R2_en <= '0';
        txData <= "00100000";
        start <= '0'; --initiate new data retrieval cycle, this can be placed here because the machine stays in "SEND_SPACE" only for 1 clock cycle
        reset_aNNN_valid <= '0';           
         
        
      WHEN SET_NEW_LINE =>
        txNow <= '0';
        resetCounter <= '0';
        resetRegister <='0';
        Count_en <= '0';
        R1_en <= '0';
        R2_en <= '0';
        txData <= "00001010"; --Line feed (\n) ASCII code   --seems like they want carriage return 00001101
        start <= '0';
        reset_aNNN_valid <= '0';
        
      WHEN SEND_NEW_LINE =>
        txNow <= '1';
        resetCounter <= '0';
        resetRegister <='0';
        Count_en <= '0';
        R1_en <= '0';
        R2_en <= '0';
        txData <= "00001010";
        start <= '0';
        reset_aNNN_valid <= '1';
        
      WHEN SEND_START =>
        txNow <= '0';
        resetCounter <= '0';
        resetRegister <='0';
        Count_en <= '0';
        R1_en <= '0';
        R2_en <= '0';
        txData <= "00000000";
        start <= '1';  --Inititate data retrieval process after sending new line or space
        reset_aNNN_valid <= '0';
        
        
      WHEN OTHERS =>
        txNow <= '0';
        resetCounter <= '0';
        resetRegister <='0';
        Count_en <= '0';
        R1_en <= '0';
        R2_en <= '0';
        txData <= "00000000";
        start <= '0';
        reset_aNNN_valid <= '0';
        
    END CASE;
  END PROCESS;
        
        
        
data_conversion:PROCESS(curState,byte)
  VARIABLE firstDigit,secondDigit : std_logic_vector(3 downto 0); --firstDigit is the most significant digit in the hexadecimal number pair (bit 4 to 7), the first digit to be sent
  BEGIN
      IF curState=CONVERSION THEN
      firstDigit := byte(7 downto 4);
      secondDigit := byte(3 downto 0);
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
        WHEN OTHERS => firstDigitASCII <= "00100001"; --print "!" for any other combinations
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
        WHEN OTHERS => secondDigitASCII <= "00100001"; --print "!" for any other combinations
      END CASE;
      
    ELSE 
      firstDigit := "0000";
      secondDigit := "0000";
      firstDigitASCII <= "00000000";
      secondDigitASCII <= "00000000";
    
    END IF;
  END PROCESS;
  
firstDigitRegister: PROCESS(resetRegister,clk)
  BEGIN
    IF resetRegister = '1' THEN
      reg_firstDigitASCII <= "00000000";
    ELSIF clk'event AND clk='1' THEN
      IF R1_en = '1' THEN
        reg_firstDigitASCII <= firstDigitASCII; 
      END IF;
    END IF;
  END PROCESS;      
  
secondDigitRegister: PROCESS(resetRegister,clk)
  BEGIN
    IF resetRegister = '1' THEN
      reg_secondDigitASCII <= "00000000";
    ELSIF clk'event AND clk='1' THEN
      IF R2_en = '1' THEN
        reg_secondDigitASCII <= secondDigitASCII; 
      END IF;
    END IF;
  END PROCESS;      
  
aNNN_valid_Register: PROCESS(reset_aNNN_valid,clk)  --this is to register the aNNN_valid signal when it goes high to prevent it from going undetected when the machine is echoing rxData as it is only checked in the INIT state
  BEGIN
    IF reset_aNNN_valid = '1' THEN
      reg_aNNN_valid <= '0';
    ELSIF clk'event AND clk='1' THEN
      IF aNNN_valid = '1' THEN
        reg_aNNN_valid <= '1'; 
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
END; --end architecture      
      
        

