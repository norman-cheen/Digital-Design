LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use work.common_pack.all;

ENTITY dataConversion IS
  PORT(
    clk:in std_logic;
    reset:in std_logic;
    dataReady: in std_logic; --dataReady from dataProc
    byte: in std_logic_vector(7 downto 0);  --data from data processor
    rxData: in std_logic_vector(7 downto 0); --command
    txDone: in std_logic;
    seqDone: in std_logic;
    rxNow: in std_logic;
    txData: out std_logic_vector(7 downto 0); -- send data to Tx (dataOut)
    txNow : out std_logic
  );
END dataConversion;

ARCHITECTURE arc OF dataConversion IS
  
  component UART_TX_CTRL is
    port ( 
      SEND : in  STD_LOGIC;
      DATA : in  STD_LOGIC_VECTOR (7 downto 0);
      CLK : in  STD_LOGIC;
      READY : out  STD_LOGIC;
      UART_TX : out  STD_LOGIC
    );
  end component;  
  
  component UART_RX_CTRL is
    port(
      RxD: in std_logic;                -- serial data in
      sysclk: in std_logic; 		-- system clock
      reset: in std_logic;		--	synchronous reset
      rxDone: in std_logic;		-- data succesfully read (active high)
      rcvDataReg: out std_logic_vector(7 downto 0); -- received data
      dataReady: out std_logic;	        -- data ready to be read
      setOE: out std_logic;		-- overrun error (active high)
      setFE: out std_logic		-- frame error (active high)
    );
  end component; 
  
  component dataGen is
    port (
      clk:		in std_logic;
      reset:		in std_logic; -- synchronous reset
      ctrlIn: in std_logic;
      ctrlOut: out std_logic;
      data: out std_logic_vector(7 downto 0)
    );
  end component;
  
  component dataConsume is
    port (
      clk:		in std_logic;
      reset:		in std_logic; -- synchronous reset
      start: in std_logic;
      numWords_bcd: in BCD_ARRAY_TYPE(2 downto 0);
      ctrlIn: in std_logic;
      ctrlOut: out std_logic;
      data: in std_logic_vector(7 downto 0);
      dataReady: out std_logic;
      byte: out std_logic_vector(7 downto 0);
      seqDone: out std_logic;
      maxIndex: out BCD_ARRAY_TYPE(2 downto 0);
      dataResults: out CHAR_ARRAY_TYPE(0 to 6) 
    );
  end component;
  
  COMPONENT commandProc is
    PORT (
    clk:		in std_logic;
    reset:		in std_logic;
    rxNow:		in std_logic;     -- valid (dataReady) signal from Rx
    rxData:			in std_logic_vector (7 downto 0);
    rxDone:		out std_logic;
    aNNN_valid: out std_logic;
    start: out std_logic;
    numWords_bcd : out BCD_ARRAY_TYPE(2 downto 0) -- bcd output
    );     
  END COMPONENT;
  
  SIGNAL resetCounter,resetRegister, Count_en,R1_en,R2_en: std_logic;   --active HIGH
  
  TYPE state_type IS (INIT, CONVERSION, SEND_FIRST_DIGIT, SEND_SECOND_DIGIT,SET_SECOND_DIGIT,SET_SPACE,SEND_SPACE,ECHO_COMMAND,SEND_COMMAND,SET_NEW_LINE,SEND_NEW_LINE);
  SIGNAL curState, nextState : state_type; 
  SIGNAL firstDigitASCII, secondDigitASCII, reg_firstDigitASCII, reg_secondDigitASCII : std_logic_vector(7 downto 0); --initialised and values defined in conversion process
  SIGNAL count : integer; --initialised by resetCounter
  SIGNAL aNNN_valid : std_logic;
  
  signal sig_start, ctrl_genDriv, ctrl_consDriv, sig_dataReady, sig_seqDone: std_logic;
  signal sig_rxDone, sig_rxNow, sig_ovErr, sig_framErr, sig_txNow, sig_txDone: std_logic;
  signal sig_rx, sig_tx, sig_rx_debug: std_logic;
  
  signal sig_rxData, sig_txData, sig_byte: std_logic_vector(7 downto 0);
  
  signal sig_dataResults: CHAR_ARRAY_TYPE(0 to 6);
  signal sig_numWords_bcd: BCD_ARRAY_TYPE(2 downto 0);
  signal sig_data: std_logic_vector(7 downto 0);
  signal sig_maxIndex: BCD_ARRAY_TYPE(2 downto 0);
  
  
BEGIN
  combi_nextState:PROCESS(curState,DataReady,txDone,rxNow,aNNN_valid,Count)
  BEGIN
    IF reset = '1' THEN
      nextState <= INIT;
    ELSE
      CASE curState IS
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
        
      WHEN ECHO_COMMAND =>
        txNow <= '0';
        resetCounter <= '0';
        resetRegister <= '0';
        Count_en <= '0';
        R1_en <= '0';
        R2_en <= '0';
        txData <= rxData;
        
      WHEN SEND_COMMAND =>
        txNow <= '1';
        resetCounter <= '0';
        resetRegister <= '0';
        Count_en <= '0';
        R1_en <= '0';
        R2_en <= '0';
        txData <= rxData;
        
      WHEN CONVERSION =>
        txNow <= '0';
        resetCounter <= '0';
        resetRegister <= '0';
        Count_en <= '1';
        R1_en <= '1';
        R2_en <= '1';
        txData <= reg_firstDigitASCII;
        
      WHEN SEND_FIRST_DIGIT =>
        txNow <= '1';
        resetCounter <= '0';
        resetRegister <= '0';
        Count_en <= '0';
        R1_en <= '0';
        R2_en <= '0';
        txData <= reg_firstDigitASCII;
        
      WHEN SET_SECOND_DIGIT =>
        txNow <= '0';
        resetCounter <= '0';
        resetRegister <= '0';
        Count_en <= '0';
        R1_en <= '0';
        R2_en <= '0';
        txData <= reg_secondDigitASCII;
        
      WHEN SEND_SECOND_DIGIT =>
        txNow <= '1';
        resetCounter <= '0';
        resetRegister <= '0';
        Count_en <= '0';
        R1_en <= '0';
        R2_en <= '0';
        txData <= reg_secondDigitASCII;
        
      WHEN SET_SPACE =>
        txNow <= '0';
        resetCounter <= '0';
        resetRegister <= '0';
        Count_en <= '0';
        R1_en <= '0';
        R2_en <= '0';
        txData <= "00100000";  --ASCII code of space
        
      WHEN SEND_SPACE =>
        txNow <= '1';
        resetCounter <= '0';
        resetRegister <='0';
        Count_en <= '0';
        R1_en <= '0';
        R2_en <= '0';
        txData <= "00100000"; 
        
      WHEN SET_NEW_LINE =>
        txNow <= '0';
        resetCounter <= '0';
        resetRegister <='0';
        Count_en <= '0';
        R1_en <= '0';
        R2_en <= '0';
        txData <= "00001010"; --Line feed (\n) ASCII code
        
      WHEN SEND_NEW_LINE =>
        txNow <= '1';
        resetCounter <= '0';
        resetRegister <='0';
        Count_en <= '0';
        R1_en <= '0';
        R2_en <= '0';
        txData <= "00001010";
        
      WHEN OTHERS =>
        txNow <= '0';
        resetCounter <= '0';
        resetRegister <='0';
        Count_en <= '0';
        R1_en <= '0';
        R2_en <= '0';
        txData <= "00000000";
        
    END CASE;
  END PROCESS;
        
        
        
  data_conversion:PROCESS(curState,byte)
  --VARIABLE firstDigit,secondDigit : std_logic_vector(3 downto 0); --firstDigit is the most significant digit in the hexadecimal number pair (bit 4 to 7), the first digit to be sent
  BEGIN
    IF curState = CONVERSION THEN   
      IF byte(7 downto 4) = "0000" THEN
        firstDigitASCII <= "00110000";
      ELSIF byte(7 downto 4) = "0001" THEN
        firstDigitASCII <= "00110001";
      ELSIF byte(7 downto 4) = "0010" THEN
        firstDigitASCII <= "00110010";
      ELSIF byte(7 downto 4) = "0011" THEN
        firstDigitASCII <= "00110011";
      ELSIF byte(7 downto 4) = "0100" THEN
        firstDigitASCII <= "00110100";
      ELSIF byte(7 downto 4) = "0101" THEN
        firstDigitASCII <= "00110101";
      ELSIF byte(7 downto 4) = "0110" THEN
        firstDigitASCII <= "00110110";
      ELSIF byte(7 downto 4) = "0111" THEN
        firstDigitASCII <= "00110111";
      ELSIF byte(7 downto 4) = "1000" THEN
        firstDigitASCII <= "00111000";
      ELSIF byte(7 downto 4) = "1001" THEN
        firstDigitASCII <= "00111001";
      ELSIF byte(7 downto 4) = "1010" THEN
        firstDigitASCII <= "01000001";
      ELSIF byte(7 downto 4) = "1011" THEN
        firstDigitASCII <= "01000010";
      ELSIF byte(7 downto 4) = "1100" THEN
        firstDigitASCII <= "01000011";
      ELSIF byte(7 downto 4) = "1101" THEN
        firstDigitASCII <= "01000100";
      ELSIF byte(7 downto 4) = "1110" THEN
        firstDigitASCII <= "01000101";
      ELSIF byte(7 downto 4) = "1111" THEN
        firstDigitASCII <= "01000110";
      ELSE
        firstDigitASCII <= "00000000";
      END IF;
        
        
      IF byte(3 downto 0) = "0000" THEN
        secondDigitASCII <= "00110000";
      ELSIF byte(3 downto 0) = "0001" THEN
        secondDigitASCII <= "00110001";
      ELSIF byte(3 downto 0) = "0010" THEN
        secondDigitASCII <= "00110010";
      ELSIF byte(3 downto 0) = "0011" THEN
        secondDigitASCII <= "00110011";
      ELSIF byte(3 downto 0) = "0100" THEN
        secondDigitASCII <= "00110100";
      ELSIF byte(3 downto 0) = "0101" THEN
        secondDigitASCII <= "00110101";
      ELSIF byte(3 downto 0) = "0110" THEN
        secondDigitASCII <= "00110110";
      ELSIF byte(3 downto 0) = "0111" THEN
        secondDigitASCII <= "00110111";
      ELSIF byte(3 downto 0) = "1000" THEN
        secondDigitASCII <= "00111000";
      ELSIF byte(3 downto 0) = "1001" THEN
        secondDigitASCII <= "00111001";
      ELSIF byte(3 downto 0) = "1010" THEN
        secondDigitASCII <= "01000001";
      ELSIF byte(3 downto 0) = "1011" THEN
        secondDigitASCII <= "01000010";
      ELSIF byte(3 downto 0) = "1100" THEN
        secondDigitASCII <= "01000011";
      ELSIF byte(3 downto 0) = "1101" THEN
        secondDigitASCII <= "01000100";
      ELSIF byte(3 downto 0) = "1110" THEN
        secondDigitASCII <= "01000101";
      ELSIF byte(3 downto 0) = "1111" THEN
        secondDigitASCII <= "01000110";
      ELSE
        secondDigitASCII <= "00000000";
      END IF;
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

--  tx: UART_TX_CTRL
--    port map (
--      SEND => sig_txNow,
--      DATA => sig_txData,
--      CLK => clk,
--      READY => sig_txDone,
--      UART_TX => sig_tx
--    );    	
--  	
--  rx : UART_RX_CTRL
--   port map(
--     RxD => sig_rx, -- input serial line
--     sysclk => clk,
--     reset => reset, 
--     rxDone => sig_rxdone,
--     rcvDataReg => sig_rxData,
--     dataReady => sig_rxNow,
--     setOE => sig_ovErr,
--     setFE =>  sig_framerr
--   );   	
--   
--  dataGen1: dataGen
--    port map (
--      clk => clk,
--      reset => reset,
--      ctrlIn => ctrl_consDriv,
--      ctrlOut => ctrl_genDriv,
--      data => sig_data
--    );
--    
--  dataConsume1: dataConsume
--    port map (
--      clk => clk,
--      reset => reset,
--      start => sig_start,
--      numWords_bcd => sig_numWords_bcd,
--      ctrlIn => ctrl_genDriv,
--      ctrlOut => ctrl_consDriv,
--      dataReady => sig_dataReady,
--      byte => sig_byte,
--      data => sig_data,
--      seqDone => sig_seqDone,
--      maxIndex => sig_maxIndex,
--      dataResults => sig_dataResults
--    );
--    
--  cmdProc1: commandProc
--    port map (
--      clk => clk,
--      reset => reset,
--      rxNow => sig_rxNow,
--      rxData => sig_rxData,
--      rxDone => sig_rxDone,
--      start => sig_start,
--      numWords_bcd => sig_numWords_bcd
--    );
      	

END;

