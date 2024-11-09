	component ledMatrix is
		port (
			clk_clk       : in  std_logic := 'X'; -- clk
			reset_reset_n : in  std_logic := 'X'; -- reset_n
			r1_export     : out std_logic;        -- export
			r2_export     : out std_logic;        -- export
			r3_export     : out std_logic;        -- export
			r4_export     : out std_logic;        -- export
			c1_export     : in  std_logic := 'X'; -- export
			c2_export     : in  std_logic := 'X'; -- export
			c3_export     : in  std_logic := 'X'; -- export
			c4_export     : in  std_logic := 'X'  -- export
		);
	end component ledMatrix;

	u0 : component ledMatrix
		port map (
			clk_clk       => CONNECTED_TO_clk_clk,       --   clk.clk
			reset_reset_n => CONNECTED_TO_reset_reset_n, -- reset.reset_n
			r1_export     => CONNECTED_TO_r1_export,     --    r1.export
			r2_export     => CONNECTED_TO_r2_export,     --    r2.export
			r3_export     => CONNECTED_TO_r3_export,     --    r3.export
			r4_export     => CONNECTED_TO_r4_export,     --    r4.export
			c1_export     => CONNECTED_TO_c1_export,     --    c1.export
			c2_export     => CONNECTED_TO_c2_export,     --    c2.export
			c3_export     => CONNECTED_TO_c3_export,     --    c3.export
			c4_export     => CONNECTED_TO_c4_export      --    c4.export
		);

