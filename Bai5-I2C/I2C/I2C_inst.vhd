	component I2C is
		port (
			clk_clk       : in  std_logic := 'X'; -- clk
			i2c_sda_in    : in  std_logic := 'X'; -- sda_in
			i2c_scl_in    : in  std_logic := 'X'; -- scl_in
			i2c_sda_oe    : out std_logic;        -- sda_oe
			i2c_scl_oe    : out std_logic;        -- scl_oe
			reset_reset_n : in  std_logic := 'X'  -- reset_n
		);
	end component I2C;

	u0 : component I2C
		port map (
			clk_clk       => CONNECTED_TO_clk_clk,       --   clk.clk
			i2c_sda_in    => CONNECTED_TO_i2c_sda_in,    --   i2c.sda_in
			i2c_scl_in    => CONNECTED_TO_i2c_scl_in,    --      .scl_in
			i2c_sda_oe    => CONNECTED_TO_i2c_sda_oe,    --      .sda_oe
			i2c_scl_oe    => CONNECTED_TO_i2c_scl_oe,    --      .scl_oe
			reset_reset_n => CONNECTED_TO_reset_reset_n  -- reset.reset_n
		);

