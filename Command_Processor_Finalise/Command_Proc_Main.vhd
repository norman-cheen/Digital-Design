LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use work.common_pack.all;

ENTITY cmdProc IS
  PORT(
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

ARCHITECTURE arc of cmdProc IS
  COMPONENT dataConversion IS
    PORT(
     clk:in std_logic;
     reset:in std_logic;
     dataReady: in std_logic;
     byte: in std_logic_vector(7 downto 0);  --data from data processor
     rxData: in std_logic_vector(7 downto 0); --command received from rx unit
     txDone: in std_logic; 
     rxDone: in std_logic;
     seqDone:in std_logic;
     aNNN_valid: in std_logic;
     txData: out std_logic_vector(7 downto 0); --data sent to tx unit
     txNow : out std_logic;
     start : out std_logic
    );
  END COMPONENT;
  
  COMPONENT commandProc IS
    PORT (
    clk:		in std_logic;
    reset:		in std_logic;
    rxNow:		in std_logic;     -- valid (dataReady) signal from Rx
    rxData:			in std_logic_vector (7 downto 0);
    rxDone:		out std_logic;
    numWords_bcd : out BCD_ARRAY_TYPE(2 downto 0); -- bcd output
    aNNN_valid : out std_logic;
    dataReady: in std_logic
    );     
  END COMPONENT;
  
  FOR nibbleCounter: dataConversion USE ENTITY work.dataConversion(arc);
  FOR PatternRecog: commandProc USE ENTITY work.commandProc(ANNN);
  SIGNAL aNNN_valid_int,rxDone_int: std_logic;
  
  
BEGIN
  rxDone <= rxDone_int;
  
  nibbleCounter:dataConversion 
    PORT MAP(
      clk => clk,
      reset => reset,
      dataReady => dataReady,
      byte => byte,
      rxData => rxData,
      txDone => txDone,
      rxDone => rxDone_int,
      seqDone => seqDone, 
      aNNN_valid => aNNN_valid_int,
      txData => txData,
      txNow => txNow,
      start => start
    );
      
  PatternRecog:commandProc
  PORT MAP(
    clk => clk,
    reset => reset,
    rxNow => rxNow,
    rxData => rxData,
    rxDone => rxDone_int,
    numWords_bcd => numWords_bcd,
    aNNN_valid => aNNN_valid_int,
    dataReady => dataReady
  );
  
    
                              
END arc;

  
  
    

    
