module top(
		input clk_50mhz,
		input reset,
		input key3,
		
		inout 	SD_cmd,
		inout 	SD_dat,
		inout 	SD_dat3,
		output 	SD_clock,
		
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
wire pcm_valid;

assign oAUD_MCLK = clk_12mhz;
assign oAUD_BCLK = clk_512khz;
assign oAUD_DACLRCK = clk_16khz;
assign oAUD_ADCLRCK = clk_16khz;
//assign led = pcm_valid ? (data_pcm[15] ? (~data_pcm + 1) : data_pcm) : 0;
assign led = sample_l[15] ? (~sample_l + 1) : sample_l;

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

wire [4:0] bit_counter;
audio_player play_audio(
    .clk_512Khz(clk_512khz),
    .reset_n(reset),
    .clk_16khz(clk_16khz),
    .config_done(config_done),			// có thể bỏ qua nếu dữ liệu ko đọc từ Sram
    .run(1'b1),
    .stop(1'b0),
    .data_audio(sample_l),

    .oAUD_DACDAT(oAUD_DACDAT),
    .bit_counter(bit_counter),
    .play_active()
);


wire	[15:0] 	sample_l;
wire	[15:0]	sample_r;

    cpu u3 (
        .clk_clk            (clk_50mhz),            //           clk.clk
        .reset_reset_n      (reset),      //         reset.reset_n
        .fifo_out_valid     (fifo_out_valid),     //      fifo_out.valid
        .fifo_out_data      (fifo_out_data),      //              .data
        .fifo_out_channel   (),   //              .channel
        .fifo_out_error     (),     //              .error
        .fifo_out_ready     (fifo_out_ready),     //              .ready
        .fifo_read_clk_clk  (clk_16khz),  // fifo_read_clk.clk
        .sd_card_b_SD_cmd   (SD_cmd),   //       sd_card.b_SD_cmd
        .sd_card_b_SD_dat   (SD_dat),   //              .b_SD_dat
        .sd_card_b_SD_dat3  (SD_dat3),  //              .b_SD_dat3
        .sd_card_o_SD_clock (SD_clock)  //              .o_SD_clock
    );


wire [31:0] fifo_out_data;
wire        fifo_out_valid;
wire        fifo_out_ready;
wire        fifo_read_clk;
wire [31:0] dbg_data;
wire [7:0]  dbg_count;

fifo_read_test u4 (
    .fifo_read_clk  	(clk_50mhz),
    .reset_n        	(reset),
	 .bit_counter		(bit_counter),
    .fifo_out_data  	(fifo_out_data),
    .fifo_out_valid 	(fifo_out_valid),
    .fifo_out_ready 	(fifo_out_ready),
    .dbg_data       	(dbg_data),
	 .sample_l(sample_l),
	 .sample_r(sample_r),
    .dbg_count      	(dbg_count)
);


endmodule






