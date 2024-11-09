	component mcu is
		port (
			clk_clk        : in  std_logic                    := 'X';             -- clk
			reset_reset_n  : in  std_logic                    := 'X';             -- reset_n
			led_don_export : out std_logic;                                       -- export
			o_reg_export   : out std_logic_vector(7 downto 0);                    -- export
			sw_reg_export  : in  std_logic_vector(2 downto 0) := (others => 'X'); -- export
			bt_export      : in  std_logic                    := 'X'              -- export
		);
	end component mcu;

	u0 : component mcu
		port map (
			clk_clk        => CONNECTED_TO_clk_clk,        --     clk.clk
			reset_reset_n  => CONNECTED_TO_reset_reset_n,  --   reset.reset_n
			led_don_export => CONNECTED_TO_led_don_export, -- led_don.export
			o_reg_export   => CONNECTED_TO_o_reg_export,   --   o_reg.export
			sw_reg_export  => CONNECTED_TO_sw_reg_export,  --  sw_reg.export
			bt_export      => CONNECTED_TO_bt_export       --      bt.export
		);

