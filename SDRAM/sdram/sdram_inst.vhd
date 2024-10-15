	component sdram is
		port (
			phy_clk            : out   std_logic;                                        -- clk
			reset_phy_clk_n    : out   std_logic;                                        -- reset_n
			status_cal_fail    : out   std_logic;                                        -- local_cal_fail
			status_cal_success : out   std_logic;                                        -- local_cal_success
			status_init_done   : out   std_logic;                                        -- local_init_done
			global_reset_n     : in    std_logic                     := 'X';             -- reset_n
			reset_request_n    : out   std_logic;                                        -- reset_n
			local_ready        : out   std_logic;                                        -- waitrequest_n
			local_write_req    : in    std_logic                     := 'X';             -- write
			local_read_req     : in    std_logic                     := 'X';             -- read
			local_address      : in    std_logic_vector(23 downto 0) := (others => 'X'); -- address
			local_be           : in    std_logic_vector(1 downto 0)  := (others => 'X'); -- byteenable
			local_wdata        : in    std_logic_vector(15 downto 0) := (others => 'X'); -- writedata
			local_size         : in    std_logic_vector(2 downto 0)  := (others => 'X'); -- burstcount
			local_burstbegin   : in    std_logic                     := 'X';             -- beginbursttransfer
			local_rdata        : out   std_logic_vector(15 downto 0);                    -- readdata
			local_rdata_valid  : out   std_logic;                                        -- readdatavalid
			mem_addr           : out   std_logic_vector(12 downto 0);                    -- mem_a
			mem_ba             : out   std_logic_vector(1 downto 0);                     -- mem_ba
			mem_cas_n          : out   std_logic;                                        -- mem_cas_n
			mem_cke            : out   std_logic;                                        -- mem_cke
			mem_clk            : inout std_logic                     := 'X';             -- mem_ck
			mem_clk_n          : inout std_logic                     := 'X';             -- mem_ck_n
			mem_cs_n           : out   std_logic;                                        -- mem_cs_n
			mem_dm             : out   std_logic;                                        -- mem_dm
			mem_dq             : inout std_logic_vector(7 downto 0)  := (others => 'X'); -- mem_dq
			mem_dqs            : inout std_logic                     := 'X';             -- mem_dqs
			mem_dqs_n          : inout std_logic                     := 'X';             -- mem_dqs_n
			mem_odt            : out   std_logic;                                        -- mem_odt
			mem_ras_n          : out   std_logic;                                        -- mem_ras_n
			mem_we_n           : out   std_logic;                                        -- mem_we_n
			aux_full_rate_clk  : out   std_logic;                                        -- clk
			aux_half_rate_clk  : out   std_logic;                                        -- clk
			pll_ref_clk        : in    std_logic                     := 'X'              -- clk
		);
	end component sdram;

	u0 : component sdram
		port map (
			phy_clk            => CONNECTED_TO_phy_clk,            --           phy_clk.clk
			reset_phy_clk_n    => CONNECTED_TO_reset_phy_clk_n,    --         phy_reset.reset_n
			status_cal_fail    => CONNECTED_TO_status_cal_fail,    --            status.local_cal_fail
			status_cal_success => CONNECTED_TO_status_cal_success, --                  .local_cal_success
			status_init_done   => CONNECTED_TO_status_init_done,   --                  .local_init_done
			global_reset_n     => CONNECTED_TO_global_reset_n,     --      global_reset.reset_n
			reset_request_n    => CONNECTED_TO_reset_request_n,    --     reset_request.reset_n
			local_ready        => CONNECTED_TO_local_ready,        --               avl.waitrequest_n
			local_write_req    => CONNECTED_TO_local_write_req,    --                  .write
			local_read_req     => CONNECTED_TO_local_read_req,     --                  .read
			local_address      => CONNECTED_TO_local_address,      --                  .address
			local_be           => CONNECTED_TO_local_be,           --                  .byteenable
			local_wdata        => CONNECTED_TO_local_wdata,        --                  .writedata
			local_size         => CONNECTED_TO_local_size,         --                  .burstcount
			local_burstbegin   => CONNECTED_TO_local_burstbegin,   --                  .beginbursttransfer
			local_rdata        => CONNECTED_TO_local_rdata,        --                  .readdata
			local_rdata_valid  => CONNECTED_TO_local_rdata_valid,  --                  .readdatavalid
			mem_addr           => CONNECTED_TO_mem_addr,           --               mem.mem_a
			mem_ba             => CONNECTED_TO_mem_ba,             --                  .mem_ba
			mem_cas_n          => CONNECTED_TO_mem_cas_n,          --                  .mem_cas_n
			mem_cke            => CONNECTED_TO_mem_cke,            --                  .mem_cke
			mem_clk            => CONNECTED_TO_mem_clk,            --                  .mem_ck
			mem_clk_n          => CONNECTED_TO_mem_clk_n,          --                  .mem_ck_n
			mem_cs_n           => CONNECTED_TO_mem_cs_n,           --                  .mem_cs_n
			mem_dm             => CONNECTED_TO_mem_dm,             --                  .mem_dm
			mem_dq             => CONNECTED_TO_mem_dq,             --                  .mem_dq
			mem_dqs            => CONNECTED_TO_mem_dqs,            --                  .mem_dqs
			mem_dqs_n          => CONNECTED_TO_mem_dqs_n,          --                  .mem_dqs_n
			mem_odt            => CONNECTED_TO_mem_odt,            --                  .mem_odt
			mem_ras_n          => CONNECTED_TO_mem_ras_n,          --                  .mem_ras_n
			mem_we_n           => CONNECTED_TO_mem_we_n,           --                  .mem_we_n
			aux_full_rate_clk  => CONNECTED_TO_aux_full_rate_clk,  -- aux_full_rate_clk.clk
			aux_half_rate_clk  => CONNECTED_TO_aux_half_rate_clk,  -- aux_half_rate_clk.clk
			pll_ref_clk        => CONNECTED_TO_pll_ref_clk         --       pll_ref_clk.clk
		);

