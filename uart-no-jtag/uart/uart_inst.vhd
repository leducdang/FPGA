	component uart is
		port (
			clk_clk       : in  std_logic := 'X'; -- clk
			reset_reset_n : in  std_logic := 'X'; -- reset_n
			rs232_rxd     : in  std_logic := 'X'; -- rxd
			rs232_txd     : out std_logic;        -- txd
			led1_export   : out std_logic;        -- export
			led2_export   : out std_logic         -- export
		);
	end component uart;

	u0 : component uart
		port map (
			clk_clk       => CONNECTED_TO_clk_clk,       --   clk.clk
			reset_reset_n => CONNECTED_TO_reset_reset_n, -- reset.reset_n
			rs232_rxd     => CONNECTED_TO_rs232_rxd,     -- rs232.rxd
			rs232_txd     => CONNECTED_TO_rs232_txd,     --      .txd
			led1_export   => CONNECTED_TO_led1_export,   --  led1.export
			led2_export   => CONNECTED_TO_led2_export    --  led2.export
		);

