	component bluetooth is
		port (
			clk_clk       : in  std_logic := 'X'; -- clk
			reset_reset_n : in  std_logic := 'X'; -- reset_n
			rs232_RXD     : in  std_logic := 'X'; -- RXD
			rs232_TXD     : out std_logic         -- TXD
		);
	end component bluetooth;

	u0 : component bluetooth
		port map (
			clk_clk       => CONNECTED_TO_clk_clk,       --   clk.clk
			reset_reset_n => CONNECTED_TO_reset_reset_n, -- reset.reset_n
			rs232_RXD     => CONNECTED_TO_rs232_RXD,     -- rs232.RXD
			rs232_TXD     => CONNECTED_TO_rs232_TXD      --      .TXD
		);

