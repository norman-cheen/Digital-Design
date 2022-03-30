library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.common_pack.all;

ENTITY cmdProc IS 
PORT (
    clk:		in std_logic;
    reset:		in std_logic;
    rxnow:		in std_logic;
    rxData:			in std_logic_vector (7 downto 0);
    txData:			out std_logic_vector (7 downto 0);
    rxdone:		out std_logic;
    ovErr:		in std_logic;
    framErr:	in std_logic;
    txnow:		out std_logic;
    txdone:		in std_logic;
    start: out std_logic;
    numWords_bcd: out BCD_ARRAY_TYPE(2 downto 0);
    dataReady: in std_logic;
    byte: in std_logic_vector(7 downto 0);
    maxIndex: in BCD_ARRAY_TYPE(2 downto 0);
    dataResults: in CHAR_ARRAY_TYPE(0 to RESULT_BYTE_NUM-1);
    seqDone: in std_logic
    );     
END cmdProc;

ARCHITECTURE aANNN of cmdProc IS  

    TYPE state_type IS (IDLE, READ_A_a, READ_N1, READ_N2, READ_N3, doneIDLE, 
                        doneA, done1, done2, done3, 
                        send_valid, send_start, check_dataReady, receive_byte, 
                        conversion, send_secDigit,
                        INIT, CONVERSION, SEND_FIRST_DIGIT, SEND_SECOND_DIGIT,
                        SET_SECOND_DIGIT,SET_SPACE,SEND_SPACE,ECHO_COMMAND,SEND_COMMAND,
                        SET_NEW_LINE,SEND_NEW_LINE,SEND_START);
                        
    SIGNAL curState, nextState: state_type;
    SIGNAL aNNN_valid : std_logic;
    
    signal sig_rxDone, sig_rxNow, sig_ovErr, sig_framErr: std_logic;
    signal sig_rx: std_logic; 
    signal sig_rxData: std_logic_vector(7 downto 0);
    signal bcd_array : BCD_ARRAY_TYPE(2 downto 0);
    
    signal sig_start, ctrl_genDriv, ctrl_consDriv, sig_dataReady, sig_seqDone: std_logic;
    signal sig_rxDone, sig_rxNow, sig_ovErr, sig_framErr, sig_txNow, sig_txDone: std_logic;
    signal sig_rx, sig_tx, sig_rx_debug: std_logic;
    
    signal sig_rxData, sig_txData, sig_byte: std_logic_vector(7 downto 0);
    signal sig_maxIndex: BCD_ARRAY_TYPE(2 downto 0);
    
    signal sig_dataResults: CHAR_ARRAY_TYPE(0 to 6);
    signal sig_numWords_bcd: BCD_ARRAY_TYPE(2 downto 0);
    signal bcd_array : BCD_ARRAY_TYPE(2 downto 0); 
    
    signal dataOut: std_logic_vector(7 downto 0); 
    
    SIGNAL resetCounter,resetRegister, Count_en,R1_en,R2_en: std_logic;   --active HIGH
    TYPE state_type IS (INIT, CONVERSION, SEND_FIRST_DIGIT, SEND_SECOND_DIGIT,SET_SECOND_DIGIT,SET_SPACE,SEND_SPACE,ECHO_COMMAND,SEND_COMMAND,SET_NEW_LINE,SEND_NEW_LINE,SEND_START);
    SIGNAL curState1, nextState1 : state_type;
    SIGNAL firstDigitASCII, secondDigitASCII, reg_firstDigitASCII, reg_secondDigitASCII : std_logic_vector(7 downto 0); --initialised and values defined in conversion process
    SIGNAL count : integer; --initialised by resetCounter
BEGIN
  
--  echo_to_tx: PROCESS(txdone)
--  BEGIN
--    IF txdone ='1' THEN
--      txnow <= '1';
--      txData <= dataOut;
--    END IF;
--  END PROCESS;
--    
  ctrl_nextState: PROCESS(curState, rxnow, rxData)
  BEGIN  
    
    CASE curState IS 
      WHEN IDLE =>
        nextState <= doneIDLE;
        
      WHEN doneIDLE =>
        IF rxNow = '1' THEN
          nextState <= READ_A_a;
        END IF;
        
      WHEN READ_A_a =>
        IF rxData = X"61" OR rxData = X"41" THEN --in decimal 97(a) and 65(A)
          nextState <= doneA;
        ELSE
          nextState <= IDLE;
        END IF;

      WHEN doneA =>
        IF rxNow = '1' THEN
          nextState <= READ_N1;
        END IF;
        
      WHEN READ_N1 =>
        IF ((rxData = X"30") OR (rxData <= X"39")) THEN
          nextState <= done1;
        ELSIF (rxData = X"61" OR rxData = X"41") THEN
          nextState <= doneA;
        ELSE
          nextState <= IDLE;
        END IF;
        
      WHEN done1 =>
        IF rxNow = '1' THEN
          nextState <= READ_N2;
        END IF;
      
      WHEN READ_N2 =>
        IF ((rxData = X"30") or (rxData <= X"39")) THEN
          nextState <= done2;
        ELSIF rxData = X"61" or rxData = X"41" THEN
          nextState <= doneA;
        ELSE
          nextState <= IDLE;
        END IF;
      
      WHEN done2 =>
        IF rxNow = '1' THEN
          nextState <= READ_N3;
        END IF;
        
      WHEN READ_N3 =>
        IF ((rxData = X"30") or (rxData <= X"39")) THEN
          nextState <= INIT;
        ELSIF rxData = X"61" or rxData = X"41" THEN
          nextState <= doneA;
        ELSE
          nextState <= IDLE;
        END IF;
        ---
        WHEN INIT =>
          IF DataReady = '1' THEN
            nextState <= CONVERSION;
          ELSIF rxNow = '1' THEN
            nextState <= ECHO_COMMAND;
          ELSIF aNNN_valid ='1' THEN
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
          IF Count>=1 AND txDone = '1' THEN
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
          IF seqDone = '1' THEN
            nextState <= IDLE;
          ELSE
            nextState <= SEND_START;
          END IF;
        
      END CASE;
    END IF;
  END PROCESS;
  
--      WHEN SEND_NEW_LINE =>
--        nextState <= SEND_START;
--        
--      WHEN SEND_START =>
--        IF txdone ='1' THEN
--          nextState <= check_dataReady;
--        END IF;
--      
--      WHEN check_dataReady =>
--        IF txdone = '1' THEN
--          IF dataReady
--          nextState <= conversion;
--        END IF;
--          
--      WHEN conversion =>
--        nextState <= send_secDigit;
--        
--      WHEN send_secDigit =>
--        nextState <= send_space;
--        
--      WHEN send_space =>
--        next_state <= check_seqDone;
--        
--      WHEN check_seqDone =>
--        IF seqDone = '1' THEN
--          nextState <= IDLE;
--        ELSE
--          nextState <= SEND_START;
--        END IF;
--        
--      WHEN OTHERS => 
--        nextState <= IDLE;
--    END CASE;
--  END PROCESS;
  
  controlOutput: PROCESS(curState, rxData)
  BEGIN
    start <= '0';
    aNNN_valid <= '0';
    rxDone <= '0';
    txnow <= '0';
    start <= '0';
    txData <= "11111111";
    numWords_bcd <= ("1111","1111","1111");
    
    CASE curState IS 
      WHEN IDLE =>
        bcd_array <= ("1111", "1111", "1111");
        numWords_bcd <= BCD_array;

      WHEN doneIDLE =>
        rxDone <= '1';

      WHEN READ_A_a =>
        bcd_array <= ("1111", "1111", "1111");
        
      WHEN doneA =>
        rxDone <= '1';
        
      WHEN READ_N1 =>  
        BCD_array(2) <= rxData(3 downto 0);
        
      WHEN done1 =>
        rxDone <= '1';
        
      WHEN READ_N2 => 
        IF ((rxData = X"30") or (rxData <= X"39")) THEN
          bcd_array(1) <= rxData(3 downto 0);
        ELSE
          BCD_array(2) <= "1111";
        END IF;
        
      WHEN done2 =>  
        rxDone <= '1';
        
      WHEN READ_N3 =>
        IF ((rxData = X"30") or (rxData <= X"39")) THEN
          bcd_array(0) <= rxData(3 downto 0);
        ELSE
          BCD_array(1) <= "1111";
          BCD_array(2) <= "1111";
        END IF;
        
      WHEN INIT =>
        txNow <= '0';
        resetCounter <='1';
        resetRegister <='1';
        Count_en <= '0';
        R1_en <= '0';
        R2_en <= '0';
        txData <= "00000000";
        start <= '0';
        --reset_aNNN_valid <= '1';
        
      WHEN ECHO_COMMAND =>
        txNow <= '0';
        resetCounter <= '0';
        resetRegister <= '0';
        Count_en <= '0';
        R1_en <= '0';
        R2_en <= '0';
        txData <= rxData;
        start <= '0';
        --reset_aNNN_valid <= '0';
        
      WHEN SEND_COMMAND =>
        txNow <= '1';
        resetCounter <= '0';
        resetRegister <= '0';
        Count_en <= '0';
        R1_en <= '0';
        R2_en <= '0';
        txData <= rxData;
        start <= '0';
        --reset_aNNN_valid <= '0';
        
      WHEN CONVERSION =>
        txNow <= '0';
        resetCounter <= '0';
        resetRegister <= '0';
        Count_en <= '1';
        R1_en <= '1';
        R2_en <= '1';
        txData <= reg_firstDigitASCII;
        start <= '0';
       -- reset_aNNN_valid <= '0';
        
      WHEN SEND_FIRST_DIGIT =>
        txNow <= '1';
        resetCounter <= '0';
        resetRegister <= '0';
        Count_en <= '0';
        R1_en <= '0';
        R2_en <= '0';
        txData <= reg_firstDigitASCII;
        start <= '0';
       -- reset_aNNN_valid <= '0';
        
      WHEN SET_SECOND_DIGIT =>
        txNow <= '0';
        resetCounter <= '0';
        resetRegister <= '0';
        Count_en <= '0';
        R1_en <= '0';
        R2_en <= '0';
        txData <= reg_secondDigitASCII;
        start <= '0';
        --reset_aNNN_valid <= '0';
        
      WHEN SEND_SECOND_DIGIT =>
        txNow <= '1';
        resetCounter <= '0';
        resetRegister <= '0';
        Count_en <= '0';
        R1_en <= '0';
        R2_en <= '0';
        txData <= reg_secondDigitASCII;
        start <= '0';
       -- reset_aNNN_valid <= '0';
        
      WHEN SET_SPACE =>
        txNow <= '0';
        resetCounter <= '0';
        resetRegister <= '0';
        Count_en <= '0';
        R1_en <= '0';
        R2_en <= '0';
        txData <= "00100000";  --ASCII code of space
        start <= '0';
        --reset_aNNN_valid <= '0';
        
      WHEN SEND_SPACE =>
        txNow <= '1';
        resetCounter <= '0';
        resetRegister <='0';
        Count_en <= '0';
        R1_en <= '0';
        R2_en <= '0';
        txData <= "00100000";
        start <= '0'; --initiate new data retrieval cycle, this can be placed here because the machine stays in "SEND_SPACE" only for 1 clock cycle
       -- reset_aNNN_valid <= '0';           
         
        
      WHEN SET_NEW_LINE =>
        txNow <= '0';
        resetCounter <= '0';
        resetRegister <='0';
        Count_en <= '0';
        R1_en <= '0';
        R2_en <= '0';
        txData <= "00001010"; --Line feed (\n) ASCII code   --seems like they want carriage return 00001101
        start <= '0';
       --reset_aNNN_valid <= '0';
        
      WHEN SEND_NEW_LINE =>
        txNow <= '1';
        resetCounter <= '0';
        resetRegister <='0';
        Count_en <= '0';
        R1_en <= '0';
        R2_en <= '0';
        txData <= "00001010";
        start <= '0';
        --reset_aNNN_valid <= '1';
        
      WHEN SEND_START =>
        txNow <= '0';
        resetCounter <= '0';
        resetRegister <='0';
        Count_en <= '0';
        R1_en <= '0';
        R2_en <= '0';
        txData <= "00000000";
        start <= '1';  --Inititate data retrieval process after sending new line or space
        --reset_aNNN_valid <= '0';
               
      WHEN OTHERS =>
        txNow <= '0';
        resetCounter <= '0';
        resetRegister <='0';
        Count_en <= '0';
        R1_en <= '0';
        R2_en <= '0';
        txData <= "00000000";
        start <= '0';
        --reset_aNNN_valid <= '0';
        
    END CASE;
  END PROCESS;
----------------------------------------------------------------------------
--      WHEN SEND_NEW_LINE =>
--        numWords_BCD <= BCD_array;
--        dataOut <= "00001010";
--        
--      WHEN SEND_START =>
--        start <= '1';
--        
--      WHEN check_dataReady =>
--        IF dataReady = '1' THEN
--        
--      WHEN conversion =>
--        txNow <= '1';
--        
--      WHEN send_secDigit =>
--        txNow <= '1';
--        
--      WHEN send_space =>
--        txNow <= '1';   
--        
--      WHEN check_seqDone =>
        
        

        
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
      
           