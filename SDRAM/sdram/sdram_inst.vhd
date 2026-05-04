	component sdram is
		port (
			sdram_1_address       : in    std_logic_vector(24 downto 0) := (others => 'X'); -- address
			sdram_1_byteenable_n  : in    std_logic_vector(3 downto 0)  := (others => 'X'); -- byteenable_n
			sdram_1_chipselect    : in    std_logic                     := 'X';             -- chipselect
			sdram_1_writedata     : in    std_logic_vector(31 downto 0) := (others => 'X'); -- writedata
			sdram_1_read_n        : in    std_logic                     := 'X';             -- read_n
			sdram_1_write_n       : in    std_logic                     := 'X';             -- write_n
			sdram_1_readdata      : out   std_logic_vector(31 downto 0);                    -- readdata
			sdram_1_readdatavalid : out   std_logic;                                        -- readdatavalid
			sdram_1_waitrequest   : out   std_logic;                                        -- waitrequest
			wire_addr             : out   std_logic_vector(12 downto 0);                    -- addr
			wire_ba               : out   std_logic_vector(1 downto 0);                     -- ba
			wire_cas_n            : out   std_logic;                                        -- cas_n
			wire_cke              : out   std_logic;                                        -- cke
			wire_cs_n             : out   std_logic;                                        -- cs_n
			wire_dq               : inout std_logic_vector(31 downto 0) := (others => 'X'); -- dq
			wire_dqm              : out   std_logic_vector(3 downto 0);                     -- dqm
			wire_ras_n            : out   std_logic;                                        -- ras_n
			wire_we_n             : out   std_logic;                                        -- we_n
			clk_clk               : in    std_logic                     := 'X';             -- clk
			reset_reset_n         : in    std_logic                     := 'X';             -- reset_n
			sdram_clk_clk         : out   std_logic;                                        -- clk
			pll_read              : in    std_logic                     := 'X';             -- read
			pll_write             : in    std_logic                     := 'X';             -- write
			pll_address           : in    std_logic_vector(1 downto 0)  := (others => 'X'); -- address
			pll_readdata          : out   std_logic_vector(31 downto 0);                    -- readdata
			pll_writedata         : in    std_logic_vector(31 downto 0) := (others => 'X')  -- writedata
		);
	end component sdram;

	u0 : component sdram
		port map (
			sdram_1_address       => CONNECTED_TO_sdram_1_address,       --   sdram_1.address
			sdram_1_byteenable_n  => CONNECTED_TO_sdram_1_byteenable_n,  --          .byteenable_n
			sdram_1_chipselect    => CONNECTED_TO_sdram_1_chipselect,    --          .chipselect
			sdram_1_writedata     => CONNECTED_TO_sdram_1_writedata,     --          .writedata
			sdram_1_read_n        => CONNECTED_TO_sdram_1_read_n,        --          .read_n
			sdram_1_write_n       => CONNECTED_TO_sdram_1_write_n,       --          .write_n
			sdram_1_readdata      => CONNECTED_TO_sdram_1_readdata,      --          .readdata
			sdram_1_readdatavalid => CONNECTED_TO_sdram_1_readdatavalid, --          .readdatavalid
			sdram_1_waitrequest   => CONNECTED_TO_sdram_1_waitrequest,   --          .waitrequest
			wire_addr             => CONNECTED_TO_wire_addr,             --      wire.addr
			wire_ba               => CONNECTED_TO_wire_ba,               --          .ba
			wire_cas_n            => CONNECTED_TO_wire_cas_n,            --          .cas_n
			wire_cke              => CONNECTED_TO_wire_cke,              --          .cke
			wire_cs_n             => CONNECTED_TO_wire_cs_n,             --          .cs_n
			wire_dq               => CONNECTED_TO_wire_dq,               --          .dq
			wire_dqm              => CONNECTED_TO_wire_dqm,              --          .dqm
			wire_ras_n            => CONNECTED_TO_wire_ras_n,            --          .ras_n
			wire_we_n             => CONNECTED_TO_wire_we_n,             --          .we_n
			clk_clk               => CONNECTED_TO_clk_clk,               --       clk.clk
			reset_reset_n         => CONNECTED_TO_reset_reset_n,         --     reset.reset_n
			sdram_clk_clk         => CONNECTED_TO_sdram_clk_clk,         -- sdram_clk.clk
			pll_read              => CONNECTED_TO_pll_read,              --       pll.read
			pll_write             => CONNECTED_TO_pll_write,             --          .write
			pll_address           => CONNECTED_TO_pll_address,           --          .address
			pll_readdata          => CONNECTED_TO_pll_readdata,          --          .readdata
			pll_writedata         => CONNECTED_TO_pll_writedata          --          .writedata
		);

