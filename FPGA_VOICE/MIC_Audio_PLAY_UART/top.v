/* 
	--	MODE SAMPLE RATE 48KHZ --
	
	MODE USB:   MCLK 	12MHZ
					BCLK 	1.536 MHz (= 48k × 32)
					LRCLK 48KHZ
	
	USB mode =  MCLK = 250 × Fs
					48k × 250 = 12 MHz ✅
					16 bit stereo → 32bit (2mic right-left) => BCLK / frame → 1.536 MHz 

	
	-- MODE SAMPLE RATE 16KHZ --
		
		MODE USB:   MCLK 	12MHZ
						BCLK 	512 KHz (= 16k × 32)
						LRCLK 16KHZ										
							
	MIC AUDIO RECODER
	
	*******************************************
	SRAM
		WRITE: 	write_sram <= 1;	read_sram <= 0;
		READ: 	write_sram <= 0;	read_sram <= 1;
		IDLE:		write_sram <= 0;	read_sram <= 0;
		
	RAM 0 DOC 1 GHI:
		wren <= 0		-> DOC
		wren <= 1 		-> GHI

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
			input SW0,					// chon dia chi SRAM.
			input SW1,
			input SW2,
			input SW3,
			input SW4,
			input SW5,
			input SW6,
			input SW7,
			input SW8,
			input SW9,
			input SW10,
			input SW11,
			input SW12,
			
			output [15:0] led,		// Hien THI DU LIEU DOC DUOC
			output led_0,			// BAO HOAN THANH CONFIG IC
			output clk_256,			// CHECK TÍN HIEU XUNG - DO XUNG DAU VAO, DAU RA
			output clk_8,				// CHECK TIN HIEU XUNG - DO XUNG DAU VAO, DAU RA
			
			output data_input_wm8731,	// CHECK XUNG DATA WM8731 PHAN HOI
			output reg led_1,		// LED BAO DIA CHI SRAM DA DOC HOAC GHI DU
			output reg led_2,		// BAO SRAM CHE DO WRITE
			output reg led_3,			// BAO SRAM CHE DO READ
			output reg led_4,		// BAO TINH XONG PRE LUU VAO RAM.
			output reg led_5,
			output reg led_6,
			output reg led_7,
			output reg led_8,
			output reg led_9,
			output reg led_10,
			
			inout   [15:0] SRAM_DQ,       // external_interface.DQ
			output  [19:0] SRAM_ADDR,     //                   .ADDR
			output        SRAM_LB_N,     //                   .LB_N
			output        SRAM_UB_N,     //                   .UB_N
			output        SRAM_CE_N,     //                   .CE_N
			output        SRAM_OE_N,     //                   .OE_N
			output        SRAM_WE_N,     //                   .WE_N
			
			output UART_TX,
			input  UART_RX
);

//************ SRAM ****************//	khai bao in-out cac chan SRAM

reg 	[18:0] 	address_sram;       	//  avalon_sram_slave.address
//reg 	[1:0]  	byteenable_sram;    	//                   .byteenable
reg        		read_sram;          	//                   .read
reg        		write_sram;         	//                   .write
reg 	[15:0] 	writedata_sram;     	//                   .writedata
wire signed [15:0] 	readdata_sram;      	//                   .readdata
wire        	readdatavalid; 		//                   .readdatavalid



//reg slect_addr_sram;						// = 1, ghi địa chi sram khi ghi am hoac phat ra loa
												// = 0, ghi dia chi sram khi truyen uart.
												
//************ RAM ****************//												

reg signed [15:0] write_data_ram;
wire signed [15:0] read_data_ram;	
reg [8:0]		address_ram;
reg 				wren;								

//************ TEST UART ***********//

reg run;
wire fb_uart;
reg [7:0] data_uart;
reg [15:0] data_array [0:9];
reg 	[18:0] 	uart_address_sram;

//----------------------------------//

reg signed [15:0] pcm;
reg pcm_valid;
reg [4:0] ROM_output_mux_counter;

reg 	[18:0] 	audio_address_sram;

wire clk_48khz;					// HOAC = 16KHZ VOI CHE DO SAMPLE RATE 16KHZ
wire clk_12Mhz;
wire clk_100Khz;
wire clk_1536Mhz;					// HOAC = 512KHZ VOI SAMPLE RATE 16KHZ

assign oAUD_MCLK = clk_12Mhz;
assign oAUD_BCLK = clk_1536Mhz;
assign oAUD_ADCLRCK = clk_48khz;
assign oAUD_DACLRCK = clk_48khz;
assign led_0 = config_done;

assign clk_256 =  clk_1536Mhz;
assign clk_8 = clk_48khz;


assign data_input_wm8731 = iAUD_ADCDAT;
assign led = pcm_valid ? (pcm[15] ? (~pcm + 1) : pcm) : 0;


assign oAUD_DACDAT = (read_sram && SW0) ? readdata_sram[15-ROM_output_mux_counter] : 0;

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
		audio_address_sram <= 0;
		led_3 <= 0;
		led_2 <= 0;
		led_1 <= 0;
	end
	 else if(!key2)begin
		audio_address_sram <= 0;
		led_2 <= 1;
		led_1 <= 0;
	end
	 else if(!key1 && SW0)begin
		audio_address_sram <= 0;
		led_3 <= 1;
		led_1 <= 0;
	end
	else begin
    if(run_audio)
		begin
        if(audio_address_sram >= 19'd47999)
        begin
//            write_sram <= 0;
//            read_sram  <= 0;
            led_1 <= 1;
        end
        else
            audio_address_sram <= audio_address_sram + 19'd1;
		end
	end
end


//********* CHON CHE DO DOC GHI CUA SRAM ***********/
reg run_audio;
always @(posedge clk_50mhz or negedge reset)
begin
	if(!reset)
		begin
			write_sram <= 0;	
			read_sram  <= 0;
			run_audio <= 0;
		end
	else if(!key2)						// GHI AM
		begin
			write_sram <= 1;	
			read_sram  <= 0;
			run_audio <= 1;
		end
	else if((SW0 || SW1 || SW2) && !key1)	// PHAT AM THANH + TRUYEN UART + TRUYEN UART_PRE
		begin
			write_sram <= 0;	
			read_sram  <= 1;
			run_audio <= 1;
		end
	else if(SW3 && !key1)
		begin
			wren <= 1;					// GHI
			write_sram <= 0;	
			read_sram  <= 1;
		end
	else if((SW4||SW5) && !key1)
		begin
			wren <= 0;					// DOC
		end
	
end

//****************** CHON DIA CHI SRAM HOAT DONG ******************

always @(posedge clk_50mhz )
begin
	if(SW0)
		address_sram <= audio_address_sram;
	else if(SW1 || SW2)
		address_sram <= uart_address_sram;
	else if(SW3) 
		address_sram <= pre_address_sram;
end



reg [4:0] stt_uart;

reg [2:0] state;
wire [15:0] data_pre;
wire  pre_run;
wire pre_done;
reg pre_run1;
reg pre_run2;
reg [8:0] uart_addr_ram;
reg [8:0] send_fft;   // 0 → 255
reg [4:0] send_lut;

localparam UART = 3'd0,
           UART_PRE  = 3'd1,
			  UART_PRE_RAM = 3'd2,
			  UART_FFT = 3'd3,
			  UART_MAG = 3'd4,
			  UART_MEL = 3'd5,
			  UART_LUT = 3'd6;
			  
always @(posedge clk_50mhz or negedge reset ) 
begin
    if (!reset)
		begin
		  run <= 0;
		  uart_address_sram <= 0;
		  uart_addr_ram <= 0;
		  stt_uart <= 0;
		  pre_run1 <= 0;
		  led_5 <= 0;
		  send_fft <= 0;
		  send_lut <= 0;
		end
	 else if (!key1 && SW1) begin stt_uart <= 1; state <= UART; end
	 else if (!key1 && SW2) begin stt_uart <= 1; state <= UART_PRE; end
	 else if (!key1 && SW4) begin stt_uart <= 1; state <= UART_PRE_RAM; end
	 else if (!key1 && SW6) begin stt_uart <= 1; state <= UART_FFT; end
	 else if (!key1 && SW8) begin stt_uart <= 1; state <= UART_MAG; end 
	 else if (!key1 && SW10) begin stt_uart <= 1; state <= UART_MEL; end 
	 else if (!key1 && SW12) begin stt_uart <= 1; state <= UART_LUT; end 
    else begin
        case (state)
            UART: 
				begin
					case(stt_uart)
						5'd0: run <= 0;
						5'd1: 
						if(!fb_uart)
							begin
								data_uart <= readdata_sram[15:8];
								run <= 1;
								stt_uart <= 2;
							end
						5'd2:if(fb_uart)
							begin
								run <= 0;
								stt_uart <= 3;
							end
						5'd3:if(!fb_uart)
							begin
								data_uart <= readdata_sram[7:0];
								run <= 1;
								stt_uart <= 4;
							end
						5'd4:	if(fb_uart)
							begin
								run <= 0;
								uart_address_sram <= uart_address_sram + 19'd1;
								stt_uart <= 5;
							end
						5'd5:	
							begin
								if(uart_address_sram < 19'd47999) stt_uart <= 1;
								else 
									begin
									stt_uart <= 0;
									uart_address_sram <= 0;
								end
							end
					endcase
            end
				
				UART_LUT:
				begin
					case(stt_uart)
						5'd0: begin run <= 0; send_lut <= 0; end
						5'd1: 
						if(!fb_uart)
							begin
								data_uart <= out_data_lut[send_lut][15:8];
								run <= 1;
								stt_uart <= 2;
							end
						5'd2:if(fb_uart)
							begin
								run <= 0;
								stt_uart <= 3;
							end
						5'd3:if(!fb_uart)
							begin
								data_uart <= out_data_lut[send_lut][7:0];
								run <= 1;
								stt_uart <= 4;
							end
						5'd4:	if(fb_uart)
							begin
								run <= 0;
								send_lut <= send_lut + 5'd1;
								stt_uart <= 5;
							end
						5'd5:	
							begin
								if(send_lut < 5'd20) stt_uart <= 1;
								else 
									begin
									stt_uart <= 0;
									send_lut <= 0;
								end
							end
					endcase
            end		
								

            UART_PRE: 
				begin
					case(stt_uart)
						5'd0: run <= 0;
						5'd1: 
						if(!fb_uart)
							begin
//								data_uart <= y_out[15:8];
								data_uart <= data_pre[15:8];
								run <= 1;
								stt_uart <= 2;
							end
						5'd2:if(fb_uart)
							begin
								run <= 0;
								stt_uart <= 3;
							end
						5'd3:if(!fb_uart)
							begin
//								data_uart <= y_out[7:0];
								data_uart <= data_pre[7:0];
								run <= 1;
								stt_uart <= 4;
							end
						5'd4:	if(fb_uart)
							begin
								run <= 0;
								uart_address_sram <= uart_address_sram + 19'd1;
								stt_uart <= 5;
							end

						5'd5:	if(uart_address_sram < 19'd47999) stt_uart <= 6;
								else
							 begin
								  stt_uart <= 0;
								  uart_address_sram <= 0;
							 end
						5'd6: begin
//								x_reg <= readdata_sram;   // ✅ LƯU MẪU CỐ ĐỊNH
								stt_uart <= 7;
							end
//						
//						4'd7:
//							 begin
//								  mult_reg <= ALPHA * x_prev;
//								  stt_uart <= 8;
//							 end
//						
//						4'd8:
//							 begin
//								  y_out <= x_reg - (mult_reg >>> 15);
//								  stt_uart <= 9;
//							 end
//						
//						4'd9:
//							 begin
//								  x_prev <= x_reg;   // ✅ cập nhật sau khi tính xong
//								  stt_uart <= 1;
//							 end

					//**** code điều khiển PRE_EMPHASIS****//
						5'd7:
							 begin
								 pre_run1 <= 1;
								 if(pre_done) stt_uart <= 8;
							 end
								
						5'd8:
							 begin
								   pre_run1 <= 0;
								  stt_uart <= 1;
							 end
					endcase
            end
				
				
				UART_PRE_RAM:
				begin
					case(stt_uart)
						5'd0: run <= 0;
						5'd1: 
						if(!fb_uart)
							begin
//								data_uart <= read_data_ram[15:8];
								data_uart <= data_in_FFT[uart_addr_ram][15:8];
								run <= 1;
								stt_uart <= 2;
							end
						5'd2:if(fb_uart)
							begin
								run <= 0;
								stt_uart <= 3;
							end
						5'd3:if(!fb_uart)
							begin
//								data_uart <= read_data_ram[7:0];
								data_uart <= data_in_FFT[uart_addr_ram][7:0];
								run <= 1;
								stt_uart <= 4;
							end
						5'd4:	if(fb_uart)
							begin
								run <= 0;
								uart_addr_ram <= uart_addr_ram + 9'd1;
								stt_uart <= 5;
							end
						5'd5:	
							begin
								if(uart_addr_ram < 9'd256) stt_uart <= 1;
								else 
									begin
									stt_uart <= 0;
									uart_addr_ram <= 0;
									led_5 <= 1;
								end
							end
					endcase
            end
				
				UART_FFT:
				begin
					case(stt_uart)
						5'd0: run <= 0;
						5'd1: 
						if(!fb_uart)
							begin
								data_uart <= fft_real_ram[send_fft][23:16];
								run <= 1;
								stt_uart <= 2;
							end
						5'd2:if(fb_uart)
							begin
								run <= 0;
								stt_uart <= 3;
							end
						5'd3:if(!fb_uart)
							begin
								data_uart <= fft_real_ram[send_fft][15:8];
								run <= 1;
								stt_uart <= 4;
							end
						5'd4:if(fb_uart)
							begin
								run <= 0;
								stt_uart <= 5;
							end	
						5'd5:if(!fb_uart)
							begin
								data_uart <= fft_real_ram[send_fft][7:0];
								run <= 1;
								stt_uart <= 6;
							end
						5'd6:if(fb_uart)
							begin
								run <= 0;
								stt_uart <= 7;
								send_fft <= send_fft + 9'd1;
							end
						5'd7:	
							begin
								if(send_fft < 255) stt_uart <= 1;
								else 
									begin
									stt_uart <= 8;
									send_fft <= 0;
								end
							end
						
						//------------------- gui so 0 de chia giua 2 phan ---------------
							
						5'd8:if(!fb_uart)
							begin
								data_uart <= 8'd0;
								run <= 1;
								stt_uart <= 9;
							end
						5'd9:if(fb_uart)
							begin
								run <= 0;
								stt_uart <= 10;
							end
						5'd10:if(!fb_uart)
							begin
								data_uart <= 8'd0;
								run <= 1;
								stt_uart <= 11;
							end
						5'd11:if(fb_uart)
							begin
								run <= 0;
								stt_uart <= 12;
							end	
						5'd12:if(!fb_uart)
							begin
								data_uart <= 8'd0;
								run <= 1;
								stt_uart <= 13;
							end		
						5'd13:	if(fb_uart)
							begin
								run <= 0;
								stt_uart <= 14;
							end
							
							
							
					/////////////////////////////////////////////////////
						5'd14: 
						if(!fb_uart)
							begin
								data_uart <= fft_imag_ram[send_fft][23:16];
								run <= 1;
								stt_uart <= 15;
							end
						5'd15:if(fb_uart)
							begin
								run <= 0;
								stt_uart <= 16;
							end
						5'd16:if(!fb_uart)
							begin
								data_uart <= fft_imag_ram[send_fft][15:8];
								run <= 1;
								stt_uart <= 17;
							end
						5'd17:if(fb_uart)
							begin
								run <= 0;
								stt_uart <= 18;
							end	
						5'd18:if(!fb_uart)
							begin
								data_uart <= fft_imag_ram[send_fft][7:0];
								run <= 1;
								stt_uart <= 19;
							end		
						5'd19:	if(fb_uart)
							begin
								run <= 0;
								send_fft <= send_fft + 9'd1;
								stt_uart <= 20;
							end
						5'd20:	
							begin
								if(send_fft < 255) stt_uart <= 14;
								else 
									begin
									stt_uart <= 0;
									send_fft <= 0;
									led_5 <= 1;
								end
							end
					endcase
            end
				
				UART_MAG:
				begin
					case(stt_uart)
						4'd0: begin run <= 0; send_fft <= 0; end
						4'd1: 
						if(!fb_uart)
							begin
								data_uart <= data_mag[send_fft][31:24];
								run <= 1;
								stt_uart <= 2;
							end
						4'd2:if(fb_uart)
							begin
								run <= 0;
								stt_uart <= 3;
							end
						4'd3: 
						if(!fb_uart)
							begin
								data_uart <= data_mag[send_fft][23:16];
								run <= 1;
								stt_uart <= 4;
							end
						4'd4:if(fb_uart)
							begin
								run <= 0;
								stt_uart <= 5;
							end
						4'd5:if(!fb_uart)
							begin
								data_uart <= data_mag[send_fft][15:8];
								run <= 1;
								stt_uart <= 6;
							end
						4'd6:if(fb_uart)
							begin
								run <= 0;
								stt_uart <= 7;
							end	
						4'd7:if(!fb_uart)
							begin
								data_uart <= data_mag[send_fft][7:0];
								run <= 1;
								stt_uart <= 8;
							end
						4'd8:if(fb_uart)
							begin
								run <= 0;
								stt_uart <= 9;
								send_fft <= send_fft + 9'd1;
							end
						4'd9:	
							begin
								if(send_fft < 128) stt_uart <= 1;
								else 
									begin
									stt_uart <= 0;
									send_fft <= 0;
								end
							end
					endcase
				end
				
				//*************************** MEL *************************
				
				UART_MEL:
				begin
					case(stt_uart)
						4'd0: begin run <= 0; send_fft <= 0; end
						4'd1: if(!fb_uart)
							begin
								data_uart <= mel_20_data[send_fft][31:24];
								run <= 1;
								stt_uart <= 2;
							end
						4'd2:if(fb_uart)
							begin
								run <= 0;
								stt_uart <= 3;
							end
						4'd3: 
						if(!fb_uart)
							begin
								data_uart <= mel_20_data[send_fft][23:16];
								run <= 1;
								stt_uart <= 4;
							end
						4'd4:if(fb_uart)
							begin
								run <= 0;
								stt_uart <= 5;
							end
						4'd5:if(!fb_uart)
							begin
								data_uart <= mel_20_data[send_fft][15:8];
								run <= 1;
								stt_uart <= 6;
							end
						4'd6:if(fb_uart)
							begin
								run <= 0;
								stt_uart <= 7;
							end	
						4'd7:if(!fb_uart)
							begin
								data_uart <= mel_20_data[send_fft][7:0];
								run <= 1;
								stt_uart <= 8;
							end
						4'd8:if(fb_uart)
							begin
								run <= 0;
								stt_uart <= 9;
								send_fft <= send_fft + 9'd1;
							end
						4'd9:	
							begin
								if(send_fft < 20) stt_uart <= 1;
								else 
									begin
									stt_uart <= 0;
									send_fft <= 0;
								end
							end
					endcase
				end
				
				
        endcase
    end
end

//************* CALUCATOR FFT *************
//****************** FFT ****************//

reg         sink_valid;   //   sink.sink_valid
wire        sink_ready;   //       .sink_ready
reg         sink_sop;     //       .sink_sop
reg         sink_eop;     //       .sink_eop
reg [15:0]  sink_real;    //       .sink_real
//		input  wire [15:0] sink_imag,    //       .sink_imag
//		input  wire [8:0]  fftpts_in,    //       .fftpts_in
//		input  wire [0:0]  inverse,      //       .inverse
wire        source_valid; // source.source_valid
reg         source_ready; //       .source_ready
wire [1:0]  source_error; //       .source_error
wire        source_sop;   //       .source_sop
wire        source_eop;   //       .source_eop
wire [23:0] source_real;  //       .source_real
wire [23:0] source_imag;  //       .source_imag
wire [8:0]  fftpts_out;    //       .fftpts_out


//reg start;
reg [3:0] fsm_fft;
reg [9:0] fft_addr_ram;


localparam IDLE        = 3'd0;
localparam SEND        = 3'd1;
localparam WAIT_OUTPUT = 3'd2;
localparam READ        = 3'd3;
localparam DONE        = 3'd4;

reg [2:0] state_fft;

//reg [8:0] send_cnt;   // 0 → 255
reg [8:0] read_cnt;   // 0 → 255
reg       out_frame;

// Ví dụ RAM chứa frame
reg [15:0] frame_ram [0:255];

// RAM chứa kết quả FFT
reg signed [23:0] fft_real_ram [0:255];
reg signed [23:0] fft_imag_ram [0:255];


always @(posedge clk_50mhz or negedge reset) 
begin
    if (!reset) begin
        state_fft    <= IDLE;
//        send_cnt     <= 0;
        read_cnt     <= 0;
        sink_valid   <= 0;
        sink_sop     <= 0;
        sink_eop     <= 0;
        source_ready <= 0;
//		  start			<= 0;
		  fft_addr_ram <= 0;
		  fsm_fft 		<= 0;
		  led_6  <= 0;
		  out_frame <= 1'b0;
    end 
	 else if(SW5 && !key1)  begin state_fft <= SEND; led_6  <= 1; end
	 else
	 begin
        case (state_fft)

        //==================================================
        IDLE: begin
            sink_valid   	<= 0;
            source_ready 	<= 0;
            read_cnt     	<= 0;
				fft_addr_ram 	<= 0;
				sink_sop     	<= 0;
				sink_eop     	<= 0;
				led_6  			<= 0;
				fsm_fft 			<= 0;
				out_frame <= 1'b0;
        end

        //==================================================
        SEND: begin
				case (fsm_fft)
				  0: begin
						// yêu cầu đọc RAM
//						address_ram <= fft_addr_ram;
						fsm_fft <= 1;
				  end
				
				  1: begin
						// chờ RAM ra dữ liệu (1 chu kỳ) rồi CHỐT vào reg
						sink_real <= data_in_FFT[fft_addr_ram];   // chốt trước khi valid
//						sink_imag <= 16'sd0;
				
						sink_sop  <= (fft_addr_ram == 0);
						sink_eop  <= (fft_addr_ram == 255);
				
						sink_valid  <= 1'b1;            // data đã sẵn sàng, bắt đầu xin gửi
						fsm_fft     <= 2;
				  end
				
				  2: begin
						// giữ nguyên valid + data cho tới khi FFT nhận (ready=1)
						if (sink_ready) begin
						  // handshake xảy ra tại chu kỳ này (vì valid đang 1)
						  sink_valid   <= 1'b0;
				
						  fft_addr_ram <= fft_addr_ram + 10'd1;
				
						  if (fft_addr_ram == 255) 
								begin
									fsm_fft <= 4; // xong frame
									state_fft <= WAIT_OUTPUT;
								end
						  else   fsm_fft <= 0; // gửi mẫu tiếp theo
						end
				  end
				
				  4: begin
						// done
				  end
				endcase
			end					
			
        //==================================================
        WAIT_OUTPUT: begin
            sink_valid <= 0;
            sink_sop   <= 0;
            sink_eop   <= 0;
            source_ready <= 1;
				state_fft    <= READ;
				read_cnt <= 0;
        end
		  
		  READ:
			if (source_valid && source_ready) begin
				if (source_sop) begin
				  out_frame <= 1'b1;
				  read_cnt   <= 9'd0;
				end else if (out_frame) begin
				  read_cnt <= read_cnt + 9'd1;
				end
		
				// ====== lấy dữ liệu FFT tại đây ======
				// source_real/source_imag là 24-bit (thường là signed)
				// ví dụ lưu vào RAM/ FIFO:
				fft_real_ram[read_cnt] <= source_real;
            fft_imag_ram[read_cnt] <= source_imag;
		
				if (source_eop) begin
				  out_frame <= 1'b0;
				  state_fft <= DONE;
				  // out_cnt lúc này nên ~255 (đủ 256 mẫu)
				end
			 end
	
        //==================================================
//        READ: begin
//            if (source_valid && source_ready) begin
//                fft_real_ram[read_cnt] <= source_real;
//                fft_imag_ram[read_cnt] <= source_imag;
//
//                read_cnt <= read_cnt + 9'd1;
//
//                if (source_eop)
//                    state_fft <= DONE;
//            end
//        end

        //==================================================
        DONE: begin
            source_ready <= 0;
            state_fft <= IDLE;
				led_6  <= 0;
        end
        endcase
    end
end

//*********************** CALCULATOR MEL ***********************//

reg [3:0] 	stt_mel;
reg [6:0]	cnt_mel;
reg [47:0] 	mel_20_data[0:19];
wire			rx_ready_sig;
reg			bin_valid_sig;
reg [31:0]	bin_data_sig;
wire			rx_done_sig;
reg			start_calc_sig;
wire			calc_done_sig;
reg			rd_ready_in_sig;
wire			mel_valid_sig;
wire[4:0]	mel_index_sig;
wire[47:0]	mel_out_sig;
wire			read_done_sig;
reg 			rx_send_sig;


always @(posedge clk_50mhz or negedge reset ) 
begin
	if(!reset)
		begin
			stt_mel	<= 0;
			cnt_mel	<= 0;
			led_9		<= 0;
			led_10	<= 0;
		end
	else if(!key1 && SW9) stt_mel <= 1;
	else
		case(stt_mel)
		0:	cnt_mel	<= 0;
		1: if(rx_ready_sig)
				begin
					rx_send_sig <= 1;
					stt_mel <= 2;
					
				end
		2: if(!rx_done_sig)
			begin	
				bin_valid_sig <=  1;
				bin_data_sig  <= data_mag[7'd5 + cnt_mel];
				stt_mel <= 3;
				
			end
		3: if(rx_done_sig)
			begin
				bin_valid_sig <=  0;
				cnt_mel <= cnt_mel + 7'd1;
				if(cnt_mel > 64) stt_mel <= 4;
				else	 stt_mel <= 2;
			end
			
			
		4: if(rx_done_sig) begin start_calc_sig <=  1; stt_mel <= 5;  end
		5: if(calc_done_sig) begin rd_ready_in_sig <= 1; stt_mel <= 6;  end
		6: if(mel_valid_sig)
			begin
				mel_20_data[mel_index_sig] <= mel_out_sig;
				if(read_done_sig) begin stt_mel <= 0; led_9 <= 1; end
			end
		endcase
end


mel_20 mel_20_inst
(
	.clk(clk_50mhz) ,						// input  clk_sig
	.rst_n(reset) ,						// input  rst_n_sig
	.rx_ready(rx_ready_sig) ,			// output  rx_ready_in_sig
	.bin_valid(bin_valid_sig) ,		// input  bin_valid_sig
	.bin_data(bin_data_sig) ,			// input [31:0] bin_data_sig
	.rx_send(rx_send_sig),
	.rx_done(rx_done_sig) ,				// output  rx_done_sig
	.start_calc(start_calc_sig) ,		// input  start_calc_sig
	.calc_done(calc_done_sig) ,		// output  calc_done_sig
	.rd_ready_in(rd_ready_in_sig) ,	// input  rd_ready_in_sig
	.mel_valid(mel_valid_sig) ,		// output  mel_valid_sig
	.mel_index(mel_index_sig) ,		// output [4:0] mel_index_sig
	.mel_out(mel_out_sig) ,				// output [47:0] mel_out_sig
	.read_done(read_done_sig) 			// output  read_done_sig
);


//*********************** CALCULATOR MAGNITUDE ***********************//
reg [3:0] 	stt_mag;
reg [31:0] 	data_mag [0:128]; 
reg [7:0]	cnt_mag;
//reg			start_mag;
reg			valid_mag;
wire			mag_valid_sig;
reg signed [23:0] re_sig;
reg signed [23:0] im_sig;
wire 		  [31:0]	mag_sig;


always @(posedge clk_50mhz or negedge reset ) 
begin
	if(!reset)
		begin
			cnt_mag		<= 0;
			stt_mag 		<= 0;
//			start_mag 	<= 0;
			led_7 		<= 0;
		end
	else if(!key1 && SW7) stt_mag <= 1;
	else
		begin
			case(stt_mag)
			0: cnt_mag <= 0;
			1: begin
					re_sig <= fft_real_ram[cnt_mag];
					im_sig <= fft_imag_ram[cnt_mag];
					valid_mag <= 1;
					stt_mag <= 2;
				end
			2: if(mag_valid_sig)
				begin
					valid_mag <= 0;
					data_mag[cnt_mag] <= mag_sig;
					cnt_mag <= cnt_mag + 8'd1;
					stt_mag <= 3;
				end
			3: if(cnt_mag > 8'd128 )
					begin
						stt_mag <= 0;
						led_7 <= 1;
					end
				else if(!mag_valid_sig) stt_mag <= 1;
			endcase
		end
end


magnitude_calc magnitude_calc_inst
(
	.clk(clk_50mhz) ,					// input  clk_sig
	.valid(valid_mag) ,				// input  valid_sig
	.re(re_sig) ,						// input [15:0] re_sig
	.im(im_sig) ,						// input [15:0] im_sig
	.mag(mag_sig) ,					// output [23:0] mag_sig
	.mag_valid(mag_valid_sig) 		// output  mag_valid_sig
);		


reg	[5:0]		stt_lut;
reg 	[47:0]	data_test;
reg	[15:0]	out_data_lut[0:19];
reg in_valid_lut;
wire out_valid_lut;
reg	[4:0]		cnt_lut;
wire	[15:0]	lut_data_out;

always @(posedge clk_50mhz or negedge reset ) 
begin
	if(!reset)
		begin
			stt_lut <= 0;
			cnt_lut <= 0;
		end
	else if(!key1 && SW11) stt_lut <= 1;
	else 
		case(stt_lut)
			0: cnt_lut <= 0;
			1: if(!out_valid_lut)
				begin
					data_test <= mel_20_data[cnt_lut];				//48'd3051584
					in_valid_lut <= 1;
					stt_lut <= 2;
				end
			2:if(out_valid_lut)
				begin
					out_data_lut[cnt_lut] <= lut_data_out;
					stt_lut <= 3;
					cnt_lut <= cnt_lut +5'd1;
				end
			3:	begin
					in_valid_lut <= 0;
					if(cnt_lut<20) stt_lut <= 1;
					else stt_lut <= 0;
				end
		endcase
end


log2_u48	u9
(
    .clk(clk_50mhz),
    .rst_n(reset),
    .in_valid(in_valid_lut),
    .x(data_test),

    .out_valid(out_valid_lut),
    .y(lut_data_out)
);


//*******************************************************************//

reg [8:0] pre_addr_ram;
reg [8:0] pre_address_sram;
reg [3:0] stt_pre;
reg [15:0] data_in_FFT[0:255];

always @(posedge clk_50mhz or negedge reset ) 
begin
	if(!reset)
		begin
			pre_address_sram <= 0;
			pre_addr_ram <= 0;
			led_4 <= 0;
			stt_pre <= 0;
			pre_run2 <= 0;
		end
	else if(!key1 && SW3) stt_pre <= 1;
	else
		begin
			case(stt_pre)
				4'd1:begin
						pre_run2 <= 1;
					 if(pre_done) stt_pre <= 2;
				end
				4'd2:begin
						pre_run2 <= 0;
						stt_pre <= 3;
						write_data_ram <= data_pre;
						if(pre_addr_ram < 256)
							data_in_FFT[pre_addr_ram] <= data_pre;
				end
				4'd3:begin
						pre_address_sram <= pre_address_sram + 9'd1;
						stt_pre <= 4;
				end
				4'd4:begin
						pre_addr_ram <= pre_addr_ram + 9'd1;
						stt_pre <= 5;
				end
				4'd5:begin
						if(pre_addr_ram >= 511) 
							begin
								stt_pre <= 0;
								led_4 <= 1;
							end
						else  stt_pre <= 1;
				end
			endcase
		end 
end

 
assign pre_run = (SW2) ? pre_run1 : pre_run2;
//assign address_ram = (SW3) ? pre_addr_ram : uart_addr_ram;

always @(posedge clk_50mhz) 
begin
	if(SW3) address_ram <= pre_addr_ram;
	else if (SW4) address_ram <= uart_addr_ram;
	else if (SW5) address_ram <= fft_addr_ram;
end 

pre_emphasis u7(
    .clk(clk_50mhz),
	 .rst(reset),
	 .pre_run(pre_run),
    .x_in(readdata_sram),
    .y_out(data_pre),
	 .pre_done(pre_done)
);

uartWrite u5(
				.clock_50mhz(clk_50mhz),
				.reset(reset),
				.data(data_uart),
				.run(run),
				.feedback(fb_uart),
				.tx_pin(UART_TX)
);

gen_lrclk_48k u1(
    .BCLK(clk_1536Mhz),       // 1.536 MHz
    .reset(reset),
    .LRCLK(clk_48khz)       	// 48 kHz
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
				.o_index()
				);

SRAM u4(
		.address(address_sram),       	//  .address
		.byteenable(2'b11),   	 			//  .byteenable
		.read(read_sram),          		//  .read
		.write(write_sram),         		//  .write
		.writedata(writedata_sram),     	//  .writedata
		.readdata(readdata_sram),      	//  .readdata
		.readdatavalid(readdatavalid), 	//  .readdatavalid
		.clk(clk_50mhz),           		//  .clk
		.SRAM_DQ(SRAM_DQ),       			//  .DQ
		.SRAM_ADDR(SRAM_ADDR),     		//  .ADDR
		.SRAM_LB_N(SRAM_LB_N),     		//  .LB_N
		.SRAM_UB_N(SRAM_UB_N),     		//  .UB_N
		.SRAM_CE_N(SRAM_CE_N),     		//  .CE_N
		.SRAM_OE_N(SRAM_OE_N),     		//  .OE_N
		.SRAM_WE_N(SRAM_WE_N),     		//  .WE_N
		.reset(reset)          				//  .reset
	);
	
RAM u6(
	.address(address_ram),
	.clock(clk_50mhz),
	.data(write_data_ram),
	.wren(wren),
	.q(read_data_ram)
	);	
	
FFT u8(
		.clk(clk_50mhz),          		//   	.clk
		.reset_n(reset),      			//    .reset_n
		.sink_valid(sink_valid),   	//   	.sink_valid
		.sink_ready(sink_ready),   	//    .sink_ready
		.sink_error(2'b00),   			//    .sink_error
		.sink_sop(sink_sop),     		//    .sink_sop
		.sink_eop(sink_eop),     		//    .sink_eop
		.sink_real(sink_real),    		//    .sink_real
		.sink_imag(16'd0),    			//    .sink_imag
		.fftpts_in(9'd256),    			//    .fftpts_in
		.inverse(1'b0),      			//    .inverse
		.source_valid(source_valid), 	// 	.source_valid
		.source_ready(1'b1), 			//    .source_ready
		.source_error(source_error), 	//    .source_error
		.source_sop(source_sop),   	//    .source_sop
		.source_eop(source_eop),   	//    .source_eop
		.source_real(source_real),  	//    .source_real
		.source_imag(source_imag),  	//    .source_imag
		.fftpts_out()    					//    .fftpts_out
	);
	
endmodule




//always @(posedge clk_50mhz or negedge reset )
//begin
//	if(!reset)
//		begin
//			run <= 0;
//			uart_address_sram <= 0;
//			stt_uart <= 0;
//		end
//	else if(!key1) stt_uart <= 1; 
//	else 
//		begin
//			case(stt_uart)
//				4'd0: run <= 0;
//				4'd1: 
//					if(!fb_uart)
//						begin
//							data_uart <= readdata_sram[15:8];
//							run <= 1;
//							stt_uart <= 2;
//						end
//				4'd2:
//					if(fb_uart)
//						begin
//							run <= 0;
//							stt_uart <= 3;
//						end
//				4'd3:if(!fb_uart)
//						begin
//							data_uart <= readdata_sram[7:0];
//							run <= 1;
//							stt_uart <= 4;
//						end
//				4'd4:	if(fb_uart)
//						begin
//							run <= 0;
//							uart_address_sram <= uart_address_sram + 1;
//							stt_uart <= 5;
//						end
//				4'd5:	begin
//							if(uart_address_sram < 19'd79999) stt_uart <= 1;
//							else 
//								begin
//								stt_uart <= 0;
//								uart_address_sram <= 0;
//								end
//						end
//			endcase
//		end
//end


// CHUONG TRINH CHO PHEP TINH PRE_EMPHASIS
//reg signed [15:0] x_reg;
//reg signed [15:0] x_prev;
//
//parameter signed [15:0] ALPHA = 16'sd31130; 
//
//reg signed [31:0] mult_reg;
//reg signed [15:0] y_out;










//always @(posedge clk_50mhz or posedge rst) begin
//    if (rst) begin
//        state_fft     <= IDLE;
//        sample_cnt    <= 0;
//        output_cnt    <= 0;
//
//        sink_valid    <= 0;
//        sink_sop      <= 0;
//        sink_eop      <= 0;
//        source_ready  <= 0;
//
//        address_ram   <= 0;
//    end
//    else begin
//        case(state_fft)
//
//        // ===============================
//        IDLE:
//        begin
//            sink_valid   <= 0;
//            source_ready <= 0;
//            sample_cnt   <= 0;
//            output_cnt   <= 0;
//
//            if (start_fft) begin
//                state_fft <= LOAD_ADDR;
//            end
//        end
//
//        // ===============================
//        // đặt địa chỉ RAM
//        LOAD_ADDR:
//        begin
//            address_ram <= sample_cnt;
//            state_fft   <= WAIT_RAM;
//        end
//
//        // ===============================
//        // đợi RAM trả data (1 cycle)
//        WAIT_RAM:
//        begin
//            state_fft <= SEND_SAMPLE;
//        end
//
//        // ===============================
//        // gửi sample vào FFT
//        SEND_SAMPLE:
//        begin
//            if (sink_ready) begin
//
//                sink_valid <= 1;
//                sink_real  <= read_data_ram;
//                sink_imag  <= 16'd0;
//
//                sink_sop   <= (sample_cnt == 0);
//                sink_eop   <= (sample_cnt == 8'd255);
//
//                if (sample_cnt == 8'd255) begin
//                    state_fft <= WAIT_OUTPUT;
//                end
//                else begin
//                    sample_cnt <= sample_cnt + 1;
//                    state_fft  <= LOAD_ADDR;
//                end
//            end
//            else begin
//                sink_valid <= 0;
//            end
//        end
//
//        // ===============================
//        WAIT_OUTPUT:
//        begin
//            sink_valid   <= 0;
//            sink_sop     <= 0;
//            sink_eop     <= 0;
//            source_ready <= 1;
//
//            if (source_valid) begin
//                state_fft <= READ_OUTPUT;
//            end
//        end
//
//        // ===============================
//        READ_OUTPUT:
//        begin
//            if (source_valid) begin
//
//                fft_real_out <= source_real;
//                fft_imag_out <= source_imag;
//
//                output_cnt <= output_cnt + 1;
//
//                if (output_cnt == 8'd255) begin
//                    state_fft <= DONE;
//                end
//            end
//        end
//
//        // ===============================
//        DONE:
//        begin
//            source_ready <= 0;
//            fft_done     <= 1;
//            state_fft    <= IDLE;
//        end
//
//        endcase
//    end
//end











