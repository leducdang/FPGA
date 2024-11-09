	component vga is
		port (
			clk_clk           : in    std_logic                     := 'X';             -- clk
			clk_sdram_clk     : out   std_logic;                                        -- clk
			reset_reset_n     : in    std_logic                     := 'X';             -- reset_n
			sdram_wire_addr   : out   std_logic_vector(12 downto 0);                    -- addr
			sdram_wire_ba     : out   std_logic_vector(1 downto 0);                     -- ba
			sdram_wire_cas_n  : out   std_logic;                                        -- cas_n
			sdram_wire_cke    : out   std_logic;                                        -- cke
			sdram_wire_cs_n   : out   std_logic;                                        -- cs_n
			sdram_wire_dq     : inout std_logic_vector(15 downto 0) := (others => 'X'); -- dq
			sdram_wire_dqm    : out   std_logic_vector(1 downto 0);                     -- dqm
			sdram_wire_ras_n  : out   std_logic;                                        -- ras_n
			sdram_wire_we_n   : out   std_logic;                                        -- we_n
			vga_out_CLK       : out   std_logic;                                        -- CLK
			vga_out_HS        : out   std_logic;                                        -- HS
			vga_out_VS        : out   std_logic;                                        -- VS
			vga_out_BLANK     : out   std_logic;                                        -- BLANK
			vga_out_SYNC      : out   std_logic;                                        -- SYNC
			vga_out_R         : out   std_logic_vector(7 downto 0);                     -- R
			vga_out_G         : out   std_logic_vector(7 downto 0);                     -- G
			vga_out_B         : out   std_logic_vector(7 downto 0);                     -- B
			sdcard_b_SD_cmd   : inout std_logic                     := 'X';             -- b_SD_cmd
			sdcard_b_SD_dat   : inout std_logic                     := 'X';             -- b_SD_dat
			sdcard_b_SD_dat3  : inout std_logic                     := 'X';             -- b_SD_dat3
			sdcard_o_SD_clock : out   std_logic                                         -- o_SD_clock
		);
	end component vga;

	u0 : component vga
		port map (
			clk_clk           => CONNECTED_TO_clk_clk,           --        clk.clk
			clk_sdram_clk     => CONNECTED_TO_clk_sdram_clk,     --  clk_sdram.clk
			reset_reset_n     => CONNECTED_TO_reset_reset_n,     --      reset.reset_n
			sdram_wire_addr   => CONNECTED_TO_sdram_wire_addr,   -- sdram_wire.addr
			sdram_wire_ba     => CONNECTED_TO_sdram_wire_ba,     --           .ba
			sdram_wire_cas_n  => CONNECTED_TO_sdram_wire_cas_n,  --           .cas_n
			sdram_wire_cke    => CONNECTED_TO_sdram_wire_cke,    --           .cke
			sdram_wire_cs_n   => CONNECTED_TO_sdram_wire_cs_n,   --           .cs_n
			sdram_wire_dq     => CONNECTED_TO_sdram_wire_dq,     --           .dq
			sdram_wire_dqm    => CONNECTED_TO_sdram_wire_dqm,    --           .dqm
			sdram_wire_ras_n  => CONNECTED_TO_sdram_wire_ras_n,  --           .ras_n
			sdram_wire_we_n   => CONNECTED_TO_sdram_wire_we_n,   --           .we_n
			vga_out_CLK       => CONNECTED_TO_vga_out_CLK,       --    vga_out.CLK
			vga_out_HS        => CONNECTED_TO_vga_out_HS,        --           .HS
			vga_out_VS        => CONNECTED_TO_vga_out_VS,        --           .VS
			vga_out_BLANK     => CONNECTED_TO_vga_out_BLANK,     --           .BLANK
			vga_out_SYNC      => CONNECTED_TO_vga_out_SYNC,      --           .SYNC
			vga_out_R         => CONNECTED_TO_vga_out_R,         --           .R
			vga_out_G         => CONNECTED_TO_vga_out_G,         --           .G
			vga_out_B         => CONNECTED_TO_vga_out_B,         --           .B
			sdcard_b_SD_cmd   => CONNECTED_TO_sdcard_b_SD_cmd,   --     sdcard.b_SD_cmd
			sdcard_b_SD_dat   => CONNECTED_TO_sdcard_b_SD_dat,   --           .b_SD_dat
			sdcard_b_SD_dat3  => CONNECTED_TO_sdcard_b_SD_dat3,  --           .b_SD_dat3
			sdcard_o_SD_clock => CONNECTED_TO_sdcard_o_SD_clock  --           .o_SD_clock
		);

