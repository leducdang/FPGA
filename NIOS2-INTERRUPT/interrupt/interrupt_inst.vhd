	component interrupt is
		port (
			clk_clk       : in  std_logic := 'X'; -- clk
			reset_reset_n : in  std_logic := 'X'; -- reset_n
			led_export    : out std_logic;        -- export
			button_export : in  std_logic := 'X'  -- export
		);
	end component interrupt;

	u0 : component interrupt
		port map (
			clk_clk       => CONNECTED_TO_clk_clk,       --    clk.clk
			reset_reset_n => CONNECTED_TO_reset_reset_n, --  reset.reset_n
			led_export    => CONNECTED_TO_led_export,    --    led.export
			button_export => CONNECTED_TO_button_export  -- button.export
		);

