	component bai1 is
		port (
			clk_clk       : in  std_logic                    := 'X'; -- clk
			led_export    : out std_logic_vector(7 downto 0);        -- export
			reset_reset_n : in  std_logic                    := 'X'; -- reset_n
			bt1_export    : in  std_logic                    := 'X'  -- export
		);
	end component bai1;

	u0 : component bai1
		port map (
			clk_clk       => CONNECTED_TO_clk_clk,       --   clk.clk
			led_export    => CONNECTED_TO_led_export,    --   led.export
			reset_reset_n => CONNECTED_TO_reset_reset_n, -- reset.reset_n
			bt1_export    => CONNECTED_TO_bt1_export     --   bt1.export
		);

