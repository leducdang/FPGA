
module sdram (
	clk_clk,
	reset_reset_n,
	sdram_clk_clk,
	sdram_address,
	sdram_byteenable_n,
	sdram_chipselect,
	sdram_writedata,
	sdram_read_n,
	sdram_write_n,
	sdram_readdata,
	sdram_readdatavalid,
	sdram_waitrequest,
	wire_addr,
	wire_ba,
	wire_cas_n,
	wire_cke,
	wire_cs_n,
	wire_dq,
	wire_dqm,
	wire_ras_n,
	wire_we_n,
	pll_read,
	pll_write,
	pll_address,
	pll_readdata,
	pll_writedata);	

	input		clk_clk;
	input		reset_reset_n;
	output		sdram_clk_clk;
	input	[24:0]	sdram_address;
	input	[3:0]	sdram_byteenable_n;
	input		sdram_chipselect;
	input	[31:0]	sdram_writedata;
	input		sdram_read_n;
	input		sdram_write_n;
	output	[31:0]	sdram_readdata;
	output		sdram_readdatavalid;
	output		sdram_waitrequest;
	output	[12:0]	wire_addr;
	output	[1:0]	wire_ba;
	output		wire_cas_n;
	output		wire_cke;
	output		wire_cs_n;
	inout	[31:0]	wire_dq;
	output	[3:0]	wire_dqm;
	output		wire_ras_n;
	output		wire_we_n;
	input		pll_read;
	input		pll_write;
	input	[1:0]	pll_address;
	output	[31:0]	pll_readdata;
	input	[31:0]	pll_writedata;
endmodule
