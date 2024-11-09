	component step is
		port (
			clk_clk       : in  std_logic := 'X'; -- clk
			reset_reset_n : in  std_logic := 'X'; -- reset_n
			out1_export   : out std_logic;        -- export
			out2_export   : out std_logic;        -- export
			out3_export   : out std_logic;        -- export
			out4_export   : out std_logic         -- export
		);
	end component step;

	u0 : component step
		port map (
			clk_clk       => CONNECTED_TO_clk_clk,       --   clk.clk
			reset_reset_n => CONNECTED_TO_reset_reset_n, -- reset.reset_n
			out1_export   => CONNECTED_TO_out1_export,   --  out1.export
			out2_export   => CONNECTED_TO_out2_export,   --  out2.export
			out3_export   => CONNECTED_TO_out3_export,   --  out3.export
			out4_export   => CONNECTED_TO_out4_export    --  out4.export
		);

