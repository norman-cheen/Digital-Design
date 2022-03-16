library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.common_pack.all;

ENTITY PatternRecog IS 
PORT (
    clk:		in std_logic;
    reset:		in std_logic;
    rxNow:		out std_logic;
    rxData:			in std_logic_vector (7 downto 0);
    rxDone:		out std_logic;
    dataReady: in std_logic);     
END;

ARCHITECTURE aNNN of PatternRecog IS  

  COMPONENT UART_RX_CTRL IS
      PORT(
        RxD: in std_logic;                -- serial data in
        sysclk: in std_logic; 		-- system clock
        reset: in std_logic;		--	synchronous reset
        rxDone: in std_logic;		-- data succesfully read (active high)
        rcvDataReg: out std_logic_vector(7 downto 0); -- received data
        dataReady: out std_logic;	        -- data ready to be read (valid)
        setOE: out std_logic;		-- overrun error (active high)
        setFE: out std_logic		-- frame error (active high)
      );
    END COMPONENT;
    
    TYPE state_type IS (IDLE, READ_A_a, READ_N1, READ_N2, READ_N3);
    SIGNAL curState, nextState: state_type;
    SIGNAL ensr : std_logic;
    
    
    
    signal sig_rxDone, sig_rxNow, sig_ovErr, sig_framErr: std_logic;
    signal sig_rx: std_logic; 
    signal sig_rxData: std_logic_vector(7 downto 0);
      
BEGIN
  
  combi_nextState: PROCESS(curState, rxData, dataReady)
  BEGIN      
    CASE curState IS
      
      WHEN IDLE =>
        rxNow <= '0';
        ensr <= '0';
        IF dataReady = '1' THEN
          IF rxData = X"61" or rxData = X"41" THEN --in decimal 97(a) and 65(A)
            nextState <= READ_A_a;
            rxDone<= '1';
          ELSE
            nextState <= IDLE;
            rxDone<= '1';
          END IF;
        END IF;
        
      WHEN READ_A_a =>
        rxNow <= '0';
        ensr <= '0';
        IF dataReady = '1' THEN
          IF ((rxData >= X"30") and (rxData <= X"39")) THEN
            nextState <= READ_N1;
            rxDone<= '1';
          ELSIF (rxData = X"61" or rxData = X"41") THEN
            nextState <= READ_A_a;
            rxDone<= '1';
          ELSE
            nextState <= IDLE;
            rxDone<= '1';
          END IF;
        END IF;
          
      WHEN READ_N1 =>
        rxNow <= '0';
        IF dataReady = '1' THEN
          IF ((rxData >= X"30") and (rxData <= X"39")) THEN
            nextState <= READ_N1;
            rxDone<= '1';
            ensr <= '1';
          ELSIF rxData = X"61" or rxData = X"41" THEN
            nextState <= READ_A_a;
            rxDone<= '1';
          ELSE
            nextState <= IDLE;
            rxDone<= '1';
          END IF;
        END IF;
            
      WHEN READ_N2 =>
        rxNow <= '0';
        IF dataReady = '1' THEN
          IF ((rxData >= X"30") and (rxData <= X"39")) THEN
            nextState <= READ_N1;
            rxDone<= '1';
            ensr <= '1';
          ELSIF rxData = X"61" or rxData = X"41" THEN
            nextState <= READ_A_a;
            rxDone<= '1';
          ELSE
            nextState <= IDLE;
            rxDone<= '1';
          END IF;
        END IF;  
        
      WHEN READ_N3 =>
        rxNow <= '1';
        IF dataReady = '1' THEN
          IF ((rxData >= X"30") and (rxData <= X"39")) THEN
            nextState <= IDLE;
            rxDone<= '1';
            ensr <= '1';
          ELSIF rxData = X"61" or rxData = X"41" THEN
            nextState <= READ_A_a;
            rxDone<= '1';
          ELSE
            nextState <= IDLE;
            rxDone<= '1';
          END IF;
        END IF;   
        
    END CASE;
  END PROCESS;
  
  state_reg: PROCESS(clk, reset)
  BEGIN
    IF reset = '0' THEN
      curState <= IDLE;
    ELSIF clk'event AND clk='1' THEN
      curState <= nextState;
      END IF;
  END PROCESS; -- state_reg
  
  rx : UART_RX_CTRL
   port map(
     RxD => sig_rx, -- input serial line
     sysclk => clk,
     reset => reset, 
     rxDone => sig_rxdone,
     rcvDataReg => sig_rxData,
     dataReady => sig_rxNow,
     setOE => sig_ovErr,
     setFE =>  sig_framerr
   );   	
   
END;
