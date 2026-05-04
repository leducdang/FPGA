module top(
		input clk_50mhz,
		input reset,
		input key3,
		input SW0,
		input SW1,
		
		output oAUD_MCLK,
		output oAUD_BCLK,
		output oAUD_DACDAT,
		output oAUD_DACLRCK,
		input  iAUD_ADCDAT,
		output oAUD_ADCLRCK,
			
		output I2C_SLCK,
		inout  I2C_SDAT,
		output [15:0] led		// Hien THI DU LIEU DOC DUOC
);


wire clk_12mhz;
wire clk_512khz;
wire clk_100khz;
wire clk_16khz;
wire config_done;
wire signed [15:0] data_pcm;
wire signed [15:0] data_gain;
wire signed [15:0] data_filter_out;
wire pcm_valid;

assign oAUD_MCLK = clk_12mhz;
assign oAUD_BCLK = clk_512khz;
assign oAUD_DACLRCK = clk_16khz;
assign oAUD_ADCLRCK = clk_16khz;
assign led = pcm_valid ? (data_pcm[15] ? (~data_pcm + 1) : data_pcm) : 0;


pll u0(
	.inclk0(clk_50mhz),
	.c0(clk_12mhz),
	.c1(clk_512khz),
	.c2(clk_100khz)
	);

gen_lrclk_16k u1(
	 .BCLK(clk_512khz),       // 1.536 MHz
	 .reset(reset),
	 .LRCLK(clk_16khz)       	// 48 kHz
);

config_mic u2(
		.clock_50mhz(clk_50mhz),
		.clock_100khz(clk_100khz),
		.sda(I2C_SDAT),
		.scl(I2C_SLCK),
		.reset(reset),
		.enable_config(key3),
		.done_config(config_done),
		.o_index()
		);

mic_pcm_capture record_audio(
    .clk_512Khz(clk_512khz),     		// clock hệ thống
    .reset_n(reset),         				// reset active low
    .config_done(config_done),     		// codec đã cấu hình xong
    .clk_16khz(clk_16khz),       		// clock/lrck lấy mẫu
    .iAUD_ADCDAT(iAUD_ADCDAT),     		// data mic nối tiếp
//    .start_run(run_audio),       		// bắt đầu ghi
//    .stop_run(),        					// dừng ghi

    .pcm(),             				// dữ liệu PCM 16-bit
    .pcm_valid(pcm_valid),       		// báo pcm hợp lệ
    .data_out(data_pcm),  	// dữ liệu ghi SRAM
    .rec_active()       					// đang ghi âm
);


audio_player play_audio(
    .clk_512Khz(clk_512khz),
    .reset_n(reset),
    .clk_16khz(clk_16khz),
    .config_done(config_done),			// có thể bỏ qua nếu dữ liệu ko đọc từ Sram
    .run(1'b1),
    .stop(1'b0),
    .data_audio(data_gain),

    .oAUD_DACDAT(oAUD_DACDAT),
    .bit_counter(),
    .play_active()
);
		
gain_volume u3(
    .x_in(data_filter_out),
    .y_out(data_gain)
);		



audio_filter_chain u4(
    .clk(clk_512khz),
    .rst_n(reset),
    .sample_valid(pcm_valid),
	 .select_high_filter(SW0),
	 .select_low_filter(SW1),
	 
    .mic_in(data_pcm),
    .dac_out(data_filter_out)
);

endmodule






