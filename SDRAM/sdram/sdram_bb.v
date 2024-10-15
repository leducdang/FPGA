
module sdram (
	phy_clk,
	reset_phy_clk_n,
	status_cal_fail,
	status_cal_success,
	status_init_done,
	global_reset_n,
	reset_request_n,
	local_ready,
	local_write_req,
	local_read_req,
	local_address,
	local_be,
	local_wdata,
	local_size,
	local_burstbegin,
	local_rdata,
	local_rdata_valid,
	mem_addr,
	mem_ba,
	mem_cas_n,
	mem_cke,
	mem_clk,
	mem_clk_n,
	mem_cs_n,
	mem_dm,
	mem_dq,
	mem_dqs,
	mem_dqs_n,
	mem_odt,
	mem_ras_n,
	mem_we_n,
	aux_full_rate_clk,
	aux_half_rate_clk,
	pll_ref_clk);	

	output		phy_clk;
	output		reset_phy_clk_n;
	output		status_cal_fail;
	output		status_cal_success;
	output		status_init_done;
	input		global_reset_n;
	output		reset_request_n;
	output		local_ready;
	input		local_write_req;
	input		local_read_req;
	input	[23:0]	local_address;
	input	[1:0]	local_be;
	input	[15:0]	local_wdata;
	input	[2:0]	local_size;
	input		local_burstbegin;
	output	[15:0]	local_rdata;
	output		local_rdata_valid;
	output	[12:0]	mem_addr;
	output	[1:0]	mem_ba;
	output		mem_cas_n;
	output		mem_cke;
	inout		mem_clk;
	inout		mem_clk_n;
	output		mem_cs_n;
	output		mem_dm;
	inout	[7:0]	mem_dq;
	inout		mem_dqs;
	inout		mem_dqs_n;
	output		mem_odt;
	output		mem_ras_n;
	output		mem_we_n;
	output		aux_full_rate_clk;
	output		aux_half_rate_clk;
	input		pll_ref_clk;
endmodule
