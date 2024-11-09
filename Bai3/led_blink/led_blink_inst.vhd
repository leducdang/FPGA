	component led_blink is
		port (
			button_export  : in    std_logic                    := 'X';             -- export
			clk_clk        : in    std_logic                    := 'X';             -- clk
			lcd1602_DATA   : inout std_logic_vector(7 downto 0) := (others => 'X'); -- DATA
			lcd1602_ON     : out   std_logic;                                       -- ON
			lcd1602_BLON   : out   std_logic;                                       -- BLON
			lcd1602_EN     : out   std_logic;                                       -- EN
			lcd1602_RS     : out   std_logic;                                       -- RS
			lcd1602_RW     : out   std_logic;                                       -- RW
			led_out_export : out   std_logic_vector(7 downto 0);                    -- export
			reset_reset_n  : in    std_logic                    := 'X'              -- reset_n
		);
	end component led_blink;

	u0 : component led_blink
		port map (
			button_export  => CONNECTED_TO_button_export,  --  button.export
			clk_clk        => CONNECTED_TO_clk_clk,        --     clk.clk
			lcd1602_DATA   => CONNECTED_TO_lcd1602_DATA,   -- lcd1602.DATA
			lcd1602_ON     => CONNECTED_TO_lcd1602_ON,     --        .ON
			lcd1602_BLON   => CONNECTED_TO_lcd1602_BLON,   --        .BLON
			lcd1602_EN     => CONNECTED_TO_lcd1602_EN,     --        .EN
			lcd1602_RS     => CONNECTED_TO_lcd1602_RS,     --        .RS
			lcd1602_RW     => CONNECTED_TO_lcd1602_RW,     --        .RW
			led_out_export => CONNECTED_TO_led_out_export, -- led_out.export
			reset_reset_n  => CONNECTED_TO_reset_reset_n   --   reset.reset_n
		);

