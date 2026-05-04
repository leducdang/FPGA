/* 
	MODE USB:   MCLK 	12MHZ
					BCLK 	1.536 MHz (= 48k × 32)
					LRCLK 48KHZ
	
	USB mode =  MCLK = 250 × Fs
					48k × 250 = 12 MHz ✅
					16 bit stereo → 32bit (2mic right-left) => BCLK / frame → 1.536 MHz 
							
	MIC AUDIO RECODER
	
	*******************************************
	SRAM
		WRITE: 	write_sram <= 1;	read_sram <= 0;
		READ: 	write_sram <= 0;	read_sram <= 1;
		IDLE:		write_sram <= 0;	read_sram <= 0;

	Các bước thực hành:
		- nhấn key0 để reset
		- nhấn key3 để config mic
		- nhấn key2 đẻ ghi âm (10s)
		- nhan key1 để phát lại âm thanh vừa ghi
*/
module top(
			input clk_50mhz,
			input reset,				// key0
			output oAUD_MCLK,
			output oAUD_BCLK,
			output oAUD_DACDAT,
			output oAUD_DACLRCK,
			input  iAUD_ADCDAT,
			output oAUD_ADCLRCK,
			
			output I2C_SLCK,
			inout  I2C_SDAT,
			
			input key3,					// config WM8731
			input key2,					// ghi âm
			input key1,					// phát lai
			
			output [15:0] led,		// Hien THI DU LIEU DOC DUOC
			output led_done,			// BAO HOAN THANH CONFIG IC
			output clk_256,			// CHECK TÍN HIEU XUNG - DO XUNG DAU VAO, DAU RA
			output clk_8,				// CHECK TIN HIEU XUNG - DO XUNG DAU VAO, DAU RA
			
			output data_input_wm8731,	// CHECK XUNG DATA WM8731 PHAN HOI
			output reg led_record,		// LED BAO DIA CHI SRAM DA DOC HOAC GHI DU
			output reg led_write,		// BAO SRAM CHE DO WRITE
			output reg led_read,			// BAO SRAM CHE DO READ
			
			inout   [15:0] SRAM_DQ,       // external_interface.DQ
			output  [19:0] SRAM_ADDR,     //                   .ADDR
			output        SRAM_LB_N,     //                   .LB_N
			output        SRAM_UB_N,     //                   .UB_N
			output        SRAM_CE_N,     //                   .CE_N
			output        SRAM_OE_N,     //                   .OE_N
			output        SRAM_WE_N     //                   .WE_N
);

//************ SRAM ****************//	khai bao in-out cac chan SRAM

reg 	[18:0] 	address_sram;       	//  avalon_sram_slave.address
//reg 	[1:0]  	byteenable_sram;    	//                   .byteenable
reg        		read_sram;          	//                   .read
reg        		write_sram;         	//                   .write
reg 	[15:0] 	writedata_sram;     	//                   .writedata
wire 	[15:0] 	readdata_sram;      	//                   .readdata
wire        	readdatavalid; 		//                   .readdatavalid


reg signed [15:0] pcm;
reg pcm_valid;
reg [4:0] ROM_output_mux_counter;

wire clk_48khz;
wire clk_12Mhz;
wire clk_100Khz;
wire clk_1536Mhz;

assign oAUD_MCLK = clk_12Mhz;
assign oAUD_BCLK = clk_1536Mhz;
assign oAUD_ADCLRCK = clk_48khz;
assign oAUD_DACLRCK = clk_48khz;
assign led_done = config_done;

assign clk_256 =  clk_1536Mhz;
assign clk_8 = clk_48khz;


assign data_input_wm8731 = iAUD_ADCDAT;
assign led = pcm_valid ? (pcm[15] ? (~pcm + 1) : pcm) : 0;


assign oAUD_DACDAT = (read_sram)?readdata_sram[15-ROM_output_mux_counter]:0;

wire config_done;
reg [4:0] cnt;
reg pre_clk48khz;


// DOC GIA TRI PCM TU MIC LUU VAO SRAM
always @(posedge clk_1536Mhz or negedge reset) begin
	if(!reset) begin
		pcm_valid <= 0;
		pcm <= 0;
		cnt <= 0;
	end
	else if(config_done)
	begin
		if(!clk_48khz && pre_clk48khz)
			begin
				cnt <= 0;
				pre_clk48khz <= clk_48khz;
			end
		else if(clk_48khz) pre_clk48khz <= clk_48khz;
		else cnt <= cnt + 5'd1;
		
		if((cnt >= 1) && (cnt <= 16)) 
			begin
				pcm_valid <= 0;
				pcm <= {pcm[14:0],iAUD_ADCDAT};
			end
		else 
			begin
				pcm_valid <= 1;
				writedata_sram <= pcm;
			end
	end
end


// TĂNG DẦN BIẾN COUNTER BIT DE DOC TUNG BIT GUI RA CHAN DACDAT
reg lrclk_d;

always @(posedge clk_1536Mhz)
begin
    lrclk_d <= clk_48khz;

    if(lrclk_d != clk_48khz)
        ROM_output_mux_counter <= 0;
    else if(read_sram)
        ROM_output_mux_counter <= ROM_output_mux_counter + 5'd1;
end

// CHỌN CHE DO RAM, VA TANG DAN DIA CHI SRAM
always @(posedge clk_48khz or negedge reset )
begin
	if(!reset)begin
		write_sram <= 0;	
		read_sram  <= 0;
		address_sram <= 0;
		led_read <= 0;
		led_write <= 0;
		led_record <= 0;
	end
	 else if(!key2)begin
		write_sram <= 1;	
		read_sram  <= 0;
		address_sram <= 0;
		led_write <= 1;
		led_record <= 0;
	end
	 else if(!key1)begin
		write_sram <= 0;	
		read_sram  <= 1;
		address_sram <= 0;
		led_read <= 1;
		led_record <= 0;
	end
	else begin
    if(read_sram || write_sram)
		begin
        if(address_sram >= 19'd479999)
        begin
            write_sram <= 0;
            read_sram  <= 0;
            led_record <= 1;
        end
        else
            address_sram <= address_sram + 19'd1;
		end
	end
end


gen_lrclk_48k u1(
    .BCLK(clk_1536Mhz),       // 1.536 MHz
    .reset(reset),
    .LRCLK(clk_48khz)       // 48 kHz
);

pll u2(
	.inclk0(clk_50mhz),
	.c0(clk_12Mhz),
	.c1(clk_100Khz),
	.c2(clk_1536Mhz)
	);

config_mic u3(
				.clock_50mhz(clk_50mhz),
				.clock_100khz(clk_100Khz),
				.sda(I2C_SDAT),
				.scl(I2C_SLCK),
				.reset(reset),
				.enable_config(key3),
				.done_config(config_done),
				//test
				.o_index()
				);

SRAM u4(
		.address(address_sram),       //  avalon_sram_slave.address
		.byteenable(2'b11),    //                   .byteenable
		.read(read_sram),          //                   .read
		.write(write_sram),         //                   .write
		.writedata(writedata_sram),     //                   .writedata
		.readdata(readdata_sram),      //                   .readdata
		.readdatavalid(readdatavalid), //                   .readdatavalid
		.clk(clk_50mhz),           //                clk.clk
		.SRAM_DQ(SRAM_DQ),       // external_interface.DQ
		.SRAM_ADDR(SRAM_ADDR),     //                   .ADDR
		.SRAM_LB_N(SRAM_LB_N),     //                   .LB_N
		.SRAM_UB_N(SRAM_UB_N),     //                   .UB_N
		.SRAM_CE_N(SRAM_CE_N),     //                   .CE_N
		.SRAM_OE_N(SRAM_OE_N),     //                   .OE_N
		.SRAM_WE_N(SRAM_WE_N),     //                   .WE_N
		.reset(reset)          //              reset.reset
	);
	
endmodule


