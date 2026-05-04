module audio_filter_chain (
    input clk,
    input rst_n,
    input sample_valid,
	 input select_high_filter,
	 input select_low_filter,
	 
    input signed [15:0] mic_in,
    output signed [15:0] dac_out
);

wire signed [15:0] hpf_out;
wire signed [15:0] lpf_out;

high_pass_filter u_hpf (
    .clk(clk),
    .rst_n(rst_n),
    .sample_valid(sample_valid),
    .x_in(mic_in),
    .y_out(hpf_out)
);

low_pass_filter u_lpf (
    .clk(clk),
    .rst_n(rst_n),
    .sample_valid(sample_valid),
    .x_in(mic_in),
    .y_out(lpf_out)
);

assign dac_out = select_high_filter ? hpf_out :
                 select_low_filter  ? lpf_out :
                                      mic_in;

endmodule

