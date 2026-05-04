	component cpu is
		port (
			clk_clk            : in    std_logic                     := 'X'; -- clk
			reset_reset_n      : in    std_logic                     := 'X'; -- reset_n
			fifo_out_valid     : out   std_logic;                            -- valid
			fifo_out_data      : out   std_logic_vector(31 downto 0);        -- data
			fifo_out_channel   : out   std_logic_vector(7 downto 0);         -- channel
			fifo_out_error     : out   std_logic_vector(7 downto 0);         -- error
			fifo_out_ready     : in    std_logic                     := 'X'; -- ready
			fifo_read_clk_clk  : in    std_logic                     := 'X'; -- clk
			sd_card_b_SD_cmd   : inout std_logic                     := 'X'; -- b_SD_cmd
			sd_card_b_SD_dat   : inout std_logic                     := 'X'; -- b_SD_dat
			sd_card_b_SD_dat3  : inout std_logic                     := 'X'; -- b_SD_dat3
			sd_card_o_SD_clock : out   std_logic                             -- o_SD_clock
		);
	end component cpu;

	u0 : component cpu
		port map (
			clk_clk            => CONNECTED_TO_clk_clk,            --           clk.clk
			reset_reset_n      => CONNECTED_TO_reset_reset_n,      --         reset.reset_n
			fifo_out_valid     => CONNECTED_TO_fifo_out_valid,     --      fifo_out.valid
			fifo_out_data      => CONNECTED_TO_fifo_out_data,      --              .data
			fifo_out_channel   => CONNECTED_TO_fifo_out_channel,   --              .channel
			fifo_out_error     => CONNECTED_TO_fifo_out_error,     --              .error
			fifo_out_ready     => CONNECTED_TO_fifo_out_ready,     --              .ready
			fifo_read_clk_clk  => CONNECTED_TO_fifo_read_clk_clk,  -- fifo_read_clk.clk
			sd_card_b_SD_cmd   => CONNECTED_TO_sd_card_b_SD_cmd,   --       sd_card.b_SD_cmd
			sd_card_b_SD_dat   => CONNECTED_TO_sd_card_b_SD_dat,   --              .b_SD_dat
			sd_card_b_SD_dat3  => CONNECTED_TO_sd_card_b_SD_dat3,  --              .b_SD_dat3
			sd_card_o_SD_clock => CONNECTED_TO_sd_card_o_SD_clock  --              .o_SD_clock
		);

