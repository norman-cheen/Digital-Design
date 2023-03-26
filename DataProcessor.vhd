library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned."+";
use ieee.std_logic_unsigned."-";
use ieee.std_logic_unsigned."=";
use work.common_pack.all;

entity dataConsume is
	port (
	  	clk:		in std_logic;
		reset:		in std_logic; -- synchronous reset
		start: in std_logic; -- goes high to signal data transfer
		numWords_bcd: in BCD_ARRAY_TYPE(2 downto 0);
		ctrlIn: in std_logic;
		ctrlOut: out std_logic:= '0';
		data: in std_logic_vector(7 downto 0);
		dataReady: out std_logic;
		byte: out std_logic_vector(7 downto 0);
		seqDone: out std_logic;
		maxIndex: out BCD_ARRAY_TYPE(2 downto 0);
		dataResults: out CHAR_ARRAY_TYPE(0 to RESULT_BYTE_NUM-1) -- index 3 holds the peak
	);
end dataConsume;


ARCHITECTURE bahav OF dataConsume IS
  --------------Comparator-----------------------------------  
  component comparator is
	  port (
		   data1: in std_logic_vector(7 downto 0);
		   data2: in std_logic_vector(7 downto 0);
		   grtThan: out std_logic;
		   equal: out std_logic
	     );
    end component;
  -----------------------------------------------------------
  
  TYPE state_type IS (init,first,second,third,wait_state,fourth,fifth); 
  SIGNAL curState, nextState: state_type; 
  
  
  SIGNAL bcd_counter      : BCD_ARRAY_TYPE(2 DOWNTO 0) := ("0000", "0000", "0000");
  SIGNAL array1           : CHAR_ARRAY_TYPE(6 DOWNTO 0) := ("00000000","00000000","00000000","00000000","00000000","00000000","00000000");
  SIGNAL array2           : CHAR_ARRAY_TYPE(6 DOWNTO 0) := ("00000000","00000000","00000000","00000000","00000000","00000000","00000000");
  SIGNAL array3           : CHAR_ARRAY_TYPE(6 DOWNTO 0) := ("00000000","00000000","00000000","00000000","00000000","00000000","00000000");
  SIGNAL dataThreshold    : std_logic_vector(7 DOWNTO 0) := ("00000000");
  SIGNAL CtrlIn_Reg       : std_logic;
  SIGNAL grtthan,equals   : std_logic; 
  SIGNAL max_index_sig    : BCD_ARRAY_TYPE(2 DOWNTO 0);
  
  -- Registers:
  SIGNAL reg_data         : std_logic_vector(7 DOWNTO 0); 
  SIGNAL ctrl_out_sig     : std_logic := '0';
  
  -- Enables and Resets:
  SIGNAL bcd_counter_en   : std_logic;
  SIGNAL bcd_counter_reset: std_logic;
  SIGNAL shifter_en       : std_logic;
  SIGNAL array1_reset     : std_logic;
  
BEGIN
  
  ----------two-phase protocol signal assignment---------------------
  ctrlOut <= ctrl_out_sig; 
  
  ----------Comparator Port Mapping ---------------------------------
  Comp1: comparator port map(data,dataThreshold,grtthan,equals);  
  
  ----------BCD counter----------------------------------------------
  bcdCounter: PROCESS (clk, reset)
    VARIABLE digit1, digit10, digit100 : std_logic_vector(3 DOWNTO 0);
  BEGIN
    IF clk'EVENT AND clk='1' THEN 
      IF reset = '1' or bcd_counter_reset = '1' THEN
        digit1   := "0000";
        digit10  := "0000";
        digit100 := "0000";
        
      ELSIF bcd_counter_en = '1' THEN
        IF digit1 < "1001" THEN        --if count less than 9
          digit1  := digit1 + 1;
        ELSE 
          digit1  := "0000";           --if count >=9, carry out
          digit10 := digit10 + 1;
        END IF;
        
        IF digit10 > "1001" THEN       --if count less than 90
          digit10  := "0000";          --if count >=90, carry out
          digit100 := digit100 + 1;
        END IF;
      END IF;
      
      bcd_counter(0) <= digit1;
      bcd_counter(1) <= digit10;
      bcd_counter(2) <= digit100;
      
    END IF;
  END PROCESS;  --counter_bcd
  
  ----------Shifter--------------------------------------------------
  shifter: PROCESS (CLK)
    VARIABLE reg_shift : CHAR_ARRAY_TYPE(6 DOWNTO 0) := ("00000000","00000000","00000000","00000000","00000000","00000000","00000000");
  BEGIN
    IF array1_reset = '1' THEN
      reg_shift := ("00000000","00000000","00000000","00000000","00000000","00000000","00000000");
    ELSIF clk'EVENT AND clk='1' AND shifter_en='1' THEN
      FOR i in 6 downto 1 LOOP
        reg_shift(i) := reg_shift(i-1);
      END LOOP;
      reg_shift(0) := reg_data;    
    ELSE NULL;  
    END IF;
    
    array1 <= reg_shift;
    
  END PROCESS; -- shifter
  
  ----------pendingResult-----------------------------------------
  pendingResult: PROCESS (CLK)
  BEGIN
    IF reset = '1' THEN 
      array2 <= ("00000000","00000000","00000000","00000000","00000000","00000000","00000000");
    
    -- copy the elements in array1 into array2 when the peak byte is at the middle of array1:        
    ELSIF dataThreshold = array1(3) THEN
        array2 <= array1;
        
        -- invert the sequence of the elements in array2 to array3
        -- to match the test bench hence resolving the timing error arrised
        -- array3 will be the "pending result" and will be sent to the command processor
        -- alongside with the dataReady signal  
        FOR i in  0 to 6 LOOP               
            array3(i) <= array2 (6-i);
        END LOOP;        
    END IF;
  END PROCESS; -- pendingResult
  
 ----------Two Phase Protocol----------------------------------------------  
 Two_phase_protocol: PROCESS(curState)   
 BEGIN
    IF curState = first THEN
        ctrl_out_sig <= NOT ctrl_out_sig;
    ELSE
        ctrl_out_sig <= ctrl_out_sig;
    END IF;
  END PROCESS;
----------register for the Two Phase Protocol------------------------------ 
 Reg_Ctrl_in : PROCESS(clk)
    BEGIN 
    IF rising_edge(clk) THEN
       CtrlIn_Reg <= ctrlIn;
    END IF;
    END PROCESS;
  
  -----------State Register----------------------------------------------     
  next_state_clk: PROCESS(clk,reset)
     BEGIN 
       IF reset = '1' THEN 
         curState <= init;
       ELSIF clk'event AND clk ='1' THEN
         curState <= nextState;
       END IF; 
      END PROCESS;  
  
  -----------Next State Logic----------------------------------------------
  next_state_logic: PROCESS(curState,start,bcd_counter,ctrlIn)
    BEGIN
      CASE curState IS 
        WHEN init =>
          -- This is the initial state where the Comand Processor has its first contact with the Data Processor
          -- The start signal lets the dataprocessor when to start the transition.
            IF start = '1' THEN
              nextState <= first;
            ELSE 
              nextState <= init;
            END IF;   
            
        WHEN first =>
          -- This state checks if there is a transition and the setting of a transition in the value of the ctrl signal. 
          
          IF (CtrlIn_Reg XOR ctrlIn) = '0' THEN
             nextState <= first;
          ELSE
             nextState <= second;   
          END IF;  
          
        WHEN second =>
          -- The receive data state from the dat generator 
          nextState <= third;
        
       	WHEN third => 
              IF bcd_counter = numWords_bcd THEN 
                  nextState <= fourth;
              ELSE
                  nextState <= wait_state; 
              END IF;
              
        WHEN wait_state =>
          IF start = '1' THEN
              nextState <= first;
          ELSE 
              nextState <= wait_state;
          END IF;
              
        WHEN fourth =>
               nextState <= fifth;
                         
        WHEN fifth =>
              nextState <= init;	      
      END CASE;
      END PROCESS;
      
    ----------Output State Logic-------------------------------------------------   
      out_state: PROCESS(curState)
    BEGIN
       IF curState = init THEN 
         bcd_counter_reset <= '1';
         array1_reset <= '1';
         seqDone <= '0';
         maxIndex <= ("0000", "0000", "0000");
         
         
       ELSIF curState = first THEN  
         bcd_counter_reset <= '0';
         array1_reset <= '0';
        
       ELSIF curState = second THEN 
         byte <= data; 
         dataReady <= '1'; 
         bcd_counter_en <='1';
         shifter_en <= '1';
         reg_data <= data;
         IF grtthan = '1' THEN 
            dataThreshold <= data;
            max_index_sig <= bcd_counter;
         ELSE 
           dataThreshold <=  dataThreshold;  
           max_index_sig <= max_index_sig; 
         END IF; 
         
       ELSIF  curState = third THEN
           shifter_en <= '0';
           bcd_counter_en <= '0';
           dataReady <= '0';
           
		   ELSIF curState = fourth THEN
		     dataResults <= array3;
		     maxIndex <= max_index_sig;
		     
		   ELSIF curState = fifth THEN
		      seqDone <= '1';
		      dataThreshold <= "00000000";
		   END IF; 
    END PROCESS;    
  
END; -- end architecture
