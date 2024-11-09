	component esp32 is
		port (
			clk_clk       : in  std_logic := 'X'; -- clk
			reset_reset_n : in  std_logic := 'X'; -- reset_n
			rs232_RXD     : in  std_logic := 'X'; -- RXD
			rs232_TXD     : out std_logic;        -- TXD
			led1_export   : out std_logic;        -- export
			led2_export   : out std_logic;        -- export
			led3_export   : out std_logic         -- export
		);
	end component esp32;

	u0 : component esp32
		port map (
			clk_clk       => CONNECTED_TO_clk_clk,       --   clk.clk
			reset_reset_n => CONNECTED_TO_reset_reset_n, -- reset.reset_n
			rs232_RXD     => CONNECTED_TO_rs232_RXD,     -- rs232.RXD
			rs232_TXD     => CONNECTED_TO_rs232_TXD,     --      .TXD
			led1_export   => CONNECTED_TO_led1_export,   --  led1.export
			led2_export   => CONNECTED_TO_led2_export,   --  led2.export
			led3_export   => CONNECTED_TO_led3_export    --  led3.export
		);

