	component I2C is
		port (
			clk_clk       : in  std_logic                    := 'X'; -- clk
			i2c_sda_in    : in  std_logic                    := 'X'; -- sda_in
			i2c_scl_in    : in  std_logic                    := 'X'; -- scl_in
			i2c_sda_oe    : out std_logic;                           -- sda_oe
			i2c_scl_oe    : out std_logic;                           -- scl_oe
			led1_export   : out std_logic_vector(6 downto 0);        -- export
			led2_export   : out std_logic_vector(6 downto 0);        -- export
			led3_export   : out std_logic_vector(6 downto 0);        -- export
			led4_export   : out std_logic_vector(6 downto 0);        -- export
			led5_export   : out std_logic_vector(6 downto 0);        -- export
			led6_export   : out std_logic_vector(6 downto 0);        -- export
			reset_reset_n : in  std_logic                    := 'X'; -- reset_n
			rs232_RXD     : in  std_logic                    := 'X'; -- RXD
			rs232_TXD     : out std_logic                            -- TXD
		);
	end component I2C;

	u0 : component I2C
		port map (
			clk_clk       => CONNECTED_TO_clk_clk,       --   clk.clk
			i2c_sda_in    => CONNECTED_TO_i2c_sda_in,    --   i2c.sda_in
			i2c_scl_in    => CONNECTED_TO_i2c_scl_in,    --      .scl_in
			i2c_sda_oe    => CONNECTED_TO_i2c_sda_oe,    --      .sda_oe
			i2c_scl_oe    => CONNECTED_TO_i2c_scl_oe,    --      .scl_oe
			led1_export   => CONNECTED_TO_led1_export,   --  led1.export
			led2_export   => CONNECTED_TO_led2_export,   --  led2.export
			led3_export   => CONNECTED_TO_led3_export,   --  led3.export
			led4_export   => CONNECTED_TO_led4_export,   --  led4.export
			led5_export   => CONNECTED_TO_led5_export,   --  led5.export
			led6_export   => CONNECTED_TO_led6_export,   --  led6.export
			reset_reset_n => CONNECTED_TO_reset_reset_n, -- reset.reset_n
			rs232_RXD     => CONNECTED_TO_rs232_RXD,     -- rs232.RXD
			rs232_TXD     => CONNECTED_TO_rs232_TXD      --      .TXD
		);

