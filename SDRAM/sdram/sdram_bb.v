
module sdram (
	wire_addr,
	wire_ba,
	wire_cas_n,
	wire_cke,
	wire_cs_n,
	wire_dq,
	wire_dqm,
	wire_ras_n,
	wire_we_n,
	sdram_clk_clk,
	clk_clk,
	reset_reset,
	sdram_1_address,
	sdram_1_byteenable_n,
	sdram_1_chipselect,
	sdram_1_writedata,
	sdram_1_read_n,
	sdram_1_write_n,
	sdram_1_readdata,
	sdram_1_readdatavalid,
	sdram_1_waitrequest);	

	output	[12:0]	wire_addr;
	output	[1:0]	wire_ba;
	output		wire_cas_n;
	output		wire_cke;
	output		wire_cs_n;
	inout	[31:0]	wire_dq;
	output	[3:0]	wire_dqm;
	output		wire_ras_n;
	output		wire_we_n;
	output		sdram_clk_clk;
	input		clk_clk;
	input		reset_reset;
	input	[24:0]	sdram_1_address;
	input	[3:0]	sdram_1_byteenable_n;
	input		sdram_1_chipselect;
	input	[31:0]	sdram_1_writedata;
	input		sdram_1_read_n;
	input		sdram_1_write_n;
	output	[31:0]	sdram_1_readdata;
	output		sdram_1_readdatavalid;
	output		sdram_1_waitrequest;
endmodule
