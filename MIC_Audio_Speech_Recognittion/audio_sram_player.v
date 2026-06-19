module audio_sram_player (
    input  wire        clk_512Khz,
    input  wire        reset_n,
    input  wire        clk_16khz,
    input  wire        read_sram,			// có thể bỏ qua nếu dữ liệu ko đọc từ Sram
    input  wire        run,
    input  wire        stop,
    input  wire [15:0] data_audio,

    output wire        oAUD_DACDAT,
    output reg  [4:0]  bit_counter,
    output reg         play_active
);

    reg lrclk_d;
    reg [15:0] sample_reg;

    assign oAUD_DACDAT = (play_active && read_sram && (bit_counter < 5'd16))
                       ? sample_reg[15 - bit_counter] : 1'b0;

always @(posedge clk_512Khz or negedge reset_n) 
	begin
        if (!reset_n) begin
            lrclk_d     <= 1'b0;
            bit_counter <= 5'd0;
            sample_reg  <= 16'd0;
            play_active <= 1'b0;
        end
        else begin
            if (run)
                play_active <= 1'b1;
            else if (stop)
                play_active <= 1'b0;

            lrclk_d <= clk_16khz;

            if (play_active && read_sram) 
					begin
						if (lrclk_d != clk_16khz) begin
							bit_counter <= 5'd0;
							sample_reg  <= data_audio;
						end
						else if (bit_counter < 5'd16) begin
							bit_counter <= bit_counter + 5'd1;
						end
					end
            else begin
               bit_counter <= 5'd0;
            end
        end
   end

endmodule



//assign oAUD_DACDAT = (read_sram && SW0) ? readdata_sram[15-ROM_output_mux_counter] : 0;
//reg lrclk_d;
//
//always @(posedge clk_1536Mhz)
//begin
//    lrclk_d <= clk_48khz;
//
//    if(lrclk_d != clk_48khz)
//        ROM_output_mux_counter <= 0;
//    else if(read_sram)
//        ROM_output_mux_counter <= ROM_output_mux_counter + 5'd1;
//end