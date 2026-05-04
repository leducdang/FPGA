	component SDCard is
		port (
			clk_clk           : in    std_logic := 'X'; -- clk
			reset_reset_n     : in    std_logic := 'X'; -- reset_n
			sdcard_b_SD_cmd   : inout std_logic := 'X'; -- b_SD_cmd
			sdcard_b_SD_dat   : inout std_logic := 'X'; -- b_SD_dat
			sdcard_b_SD_dat3  : inout std_logic := 'X'; -- b_SD_dat3
			sdcard_o_SD_clock : out   std_logic         -- o_SD_clock
		);
	end component SDCard;

	u0 : component SDCard
		port map (
			clk_clk           => CONNECTED_TO_clk_clk,           --    clk.clk
			reset_reset_n     => CONNECTED_TO_reset_reset_n,     --  reset.reset_n
			sdcard_b_SD_cmd   => CONNECTED_TO_sdcard_b_SD_cmd,   -- sdcard.b_SD_cmd
			sdcard_b_SD_dat   => CONNECTED_TO_sdcard_b_SD_dat,   --       .b_SD_dat
			sdcard_b_SD_dat3  => CONNECTED_TO_sdcard_b_SD_dat3,  --       .b_SD_dat3
			sdcard_o_SD_clock => CONNECTED_TO_sdcard_o_SD_clock  --       .o_SD_clock
		);

