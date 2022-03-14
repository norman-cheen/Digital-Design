library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.common_pack.all;

ENTITY PatternRecog IS 
PORT (
    clk:		in std_logic;
    reset:		in std_logic;
    rxNow:		in std_logic;
    rxData:			in std_logic_vector (7 downto 0);
    rxDone:		out std_logic;
    ovErr:		in std_logic;
    framErr:	in std_logic;
    patternRecogOutput: out std_logic_vector (7 downto 0);     
END;

ARCHITECTURE aNNN of PatternRecog IS  

  COMPONENT UART_RX_CTRL IS
      PORT(
        RxD: in std_logic;                -- serial data in
        sysclk: in std_logic; 		-- system clock
        reset: in std_logic;		--	synchronous reset
        rxDone: in std_logic;		-- data succesfully read (active high)
        rcvDataReg: out std_logic_vector(7 downto 0); -- received data
        dataReady: out std_logic;	        -- data ready to be read
        setOE: out std_logic;		-- overrun error (active high)
        setFE: out std_logic		-- frame error (active high)
      );
    END COMPONENT;
    
    TYPE state_type IS (IDLE, READ_A_a, READ_N1, READ_N2, READ_N3, OUTPUT);
    SIGNAL curState, nextState: state_type;
    SIGNAL clk, reset: std_logic := '0';
    SIGNAL sig_rxDone, sig_rxNow, sig_ovErr, sig_framErr: std_logic;
    SIGNAL sig_rxData: std_logic_vector(7 downto 0);
    
    BEGIN
      
      combi_nextState: PROCESS(curState, rxData, dataReady)
      BEGIN      
        CASE curState IS
          
          WHEN IDLE =>
            IF dataReady = '1' THEN
              
            END IF;
            
          WHEN READ_A_a =>
            IF rxData = "01100001" or "01000001" THEN --in decimal 97(a) and 65(A)
              nextState <= READ_A_a;
            ELSE
              nextState <= IDLE;
            END IF;
