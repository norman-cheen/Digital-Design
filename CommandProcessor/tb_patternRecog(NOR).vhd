library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.common_pack.all;


entity tb_patternRecog is 
end;

architecture testbench of tb_patternRecog is 

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
  
  component patternRecog is
    PORT (
    clk:		in std_logic;
    reset:		in std_logic;
    rxNow:		in std_logic;     -- valid (dataReady) signal from Rx
    rxData:			in std_logic_vector (7 downto 0);
    rxDone:		out std_logic;
    ensr: out std_logic;
    aNNN_valid: out std_logic
    );      
  END COMPONENT;
  
    SIGNAL sig_ensr, sig_aNNN_valid : std_logic; 
    signal clk: std_logic := '0';
    signal reset: std_logic;
    signal sig_rxDone, sig_rxNow, sig_ovErr, sig_framErr: std_logic;
    signal sig_rx: std_logic; 
    signal sig_rxData: std_logic_vector(7 downto 0);

begin
  clk <= NOT clk after 5 ns when now <2000 ms else clk;
  reset <= '0', '1' after 2 ns, '0' after 15 ns, '0' after 3600 ns, '0' after 3615 ns;
    
    sig_rx <= '1', '0' after 1 us, '1' after 105 us, '0' after 209 us,  '0' after 313 us,  '0' after 417 us,  
  '0' after 521 us,  '1' after 625 us,  '1' after 729 us,  '0' after 833 us, '1' after 937 us, 
  -- 0: 0, 0000_1100, 1 (start bit - 0, decimal 0 (0011_0000) in order of LSB first, stop bit -1)
  '0' after 1200 us, '0' after 1304 us, '0' after 1408 us, '0' after 1512 us,  '0' after 1616 us,  
  '1' after 1720 us, '1' after 1824 us,  '0' after 1928 us,  '0' after 2032 us,  '1' after 2136 us, 
  -- 1: 0, 10001100, 1 (start bit - 0, decimal 0 (0011_0001) in order of LSB first, stop bit -1)
    '0' after 2500 us, '1' after 2604 us, '0' after 2708 us, '0' after 2812 us, '0' after 2916 us,
    '1' after 3020 us,  '1' after 3124 us,  '0' after 3228 us,  '0' after 3332 us,  '1' after 3436 us,  
  -- 2: 0, 0100_1100, 1 (start bit - 0, decimal 2 (0011_0010) in order of LSB first, stop bit -1)
  '0' after 3800 us, '0' after 3904 us, '1' after 4008 us, '0' after 4112 us, '0' after 4216 us, 
  '1' after 4320 us, '1' after 4424 us, '0' after 4528 us, '0' after 4632 us, '1' after 4736 us;
  -----------------------------
  
  cmdProc1: patternRecog
    port map (
      clk => clk,
      reset => reset,
      rxNow => sig_rxNow,
      rxData => sig_rxData,
      rxDone => sig_rxDone,
      ensr => sig_ensr,
      aNNN_valid => sig_aNNN_valid 
      );
      
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
  	
  	end testbench;