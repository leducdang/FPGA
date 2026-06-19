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

module top1(
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
			input SW13,
			
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
			output reg led_11,   // HEX0[0]
			output reg led_12,   // HEX0[1]
			output reg led_13,   // HEX0[2]
			
			
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

wire 	[18:0] 	address_sram;       	//  avalon_sram_slave.address
//reg 	[1:0]  	byteenable_sram;    	//                   .byteenable
reg        		read_sram;          	//                   .read
reg        		write_sram;         	//                   .write
wire 	[15:0] 	writedata_sram;     	//                   .writedata
wire signed [15:0] 	readdata_sram;      	//                   .readdata
wire        	readdatavalid; 		//                   .readdatavalid



//reg slect_addr_sram;					// = 1, ghi địa chi sram khi ghi am hoac phat ra loa
												// = 0, ghi dia chi sram khi truyen uart.
												
//************ RAM ****************//												

reg signed [15:0] write_data_ram;
wire signed [15:0] read_data_ram;	
reg [8:0]		address_ram;
reg 				wren;								


//----------------------------------//

reg run_audio;
wire signed [15:0] pcm;
wire pcm_valid;

reg 	[18:0] 	audio_address_sram;

wire clk_16khz;					// HOAC = 16KHZ VOI CHE DO SAMPLE RATE 16KHZ
wire clk_12Mhz;
wire clk_100Khz;
wire clk_512Khz;					// HOAC = 512KHZ VOI SAMPLE RATE 16KHZ

assign oAUD_MCLK = clk_12Mhz;
assign oAUD_BCLK = clk_512Khz;
assign oAUD_ADCLRCK = clk_16khz;
assign oAUD_DACLRCK = clk_16khz;
assign led_0 = config_done;

assign clk_256 =  clk_512Khz;
assign clk_8 = clk_16khz;


assign data_input_wm8731 = iAUD_ADCDAT;
assign led = pcm_valid ? (pcm[15] ? (~pcm + 1) : pcm) : 0;




wire config_done;
reg [4:0] cnt;
reg pre_clk48khz;


mic_pcm_capture record_audio(
    .clk_512Khz(clk_512Khz),     		// clock hệ thống
    .reset_n(reset),         				// reset active low
    .config_done(config_done),     		// codec đã cấu hình xong
    .clk_16khz(clk_16khz),       		// clock/lrck lấy mẫu
    .iAUD_ADCDAT(iAUD_ADCDAT),     		// data mic nối tiếp
    .start_run(run_audio),       		// bắt đầu ghi
    .stop_run(),        					// dừng ghi

    .pcm(pcm),             				// dữ liệu PCM 16-bit
    .pcm_valid(pcm_valid),       		// báo pcm hợp lệ
    .writedata_sram(writedata_sram),  	// dữ liệu ghi SRAM
    .rec_active()       					// đang ghi âm
);


audio_sram_player play_audio(
    .clk_512Khz(clk_512Khz),
    .reset_n(reset),
    .clk_16khz(clk_16khz),
    .read_sram(read_sram),			// có thể bỏ qua nếu dữ liệu ko đọc từ Sram
    .run(run_audio),
    .stop(),
    .data_audio(readdata_sram),

    .oAUD_DACDAT(oAUD_DACDAT),
    .bit_counter(),
    .play_active()
);



// CHỌN CHE DO RAM, VA TANG DAN DIA CHI SRAM
always @(posedge clk_16khz )
begin
    if(run_audio)
		begin
            audio_address_sram <= audio_address_sram + 19'd1;
		end
	 else 	audio_address_sram <= 0;
end


assign address_sram = (SW0) ? audio_address_sram : pre_address_sram;


//******** PRE *******//

reg [18:0] pre_address_sram;
reg [3:0] stt_pre;
reg pre_run;
wire pre_done;
wire [15:0] data_pre;
reg frame_new;

//******** HAMMING *******//

reg ham_run;
reg [7:0] index_hamming;
wire [15:0] data_out_hamming;
wire ham_done;	

//******** FFT *******//

reg         sink_valid;   //   sink.sink_valid
wire        sink_ready;   //       .sink_ready
reg         sink_sop;     //       .sink_sop
reg         sink_eop;     //       .sink_eop
reg [15:0]  sink_real;    //       .sink_real
wire        source_valid; // source.source_valid
reg         source_ready; //       .source_ready
wire [1:0]  source_error; //       .source_error
wire        source_sop;   //       .source_sop
wire        source_eop;   //       .source_eop
wire [23:0] source_real;  //       .source_real
wire [23:0] source_imag;  //       .source_imag
wire [8:0]  fftpts_out;    //       .fftpts_out

reg [3:0] fsm_fft;
reg [8:0] read_cnt;   // 0 → 255
reg       out_frame;

reg signed [23:0] fft_real_ram [0:255];
reg signed [23:0] fft_imag_ram [0:255];


//******** CALCULATOR MAGNITUDE ******//
reg [3:0] 	stt_mag;
reg [31:0] 	data_mag [0:128]; 
reg [7:0]	cnt_mag;
reg			valid_mag;
wire			mag_valid_sig;
reg signed [23:0] re_sig;
reg signed [23:0] im_sig;
wire 		  [31:0]	mag_sig;


//*********************** CALCULATOR MEL ***********************//

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


//*********************** CALCULATOR LOG2(MEL) ***********************//

reg 	[47:0]	data_test;
reg	[23:0]	out_data_lut[0:19];
reg 				in_valid_lut;
reg	[4:0]		cnt_lut;
reg 	[4:0] 	send_lut;
wire 				out_valid_lut;
wire	[15:0]	lut_data_out;


//************* TEST UART MOI **************//

reg 			start_uart_new;
reg [47:0]	data_in_uart;
reg [2:0]	data_byte;
wire			done_uart_new;
wire			busy_uart_new;



//*********** MAIN ************//

reg [3:0] FSM_MAIN;
reg [4:0] stt_main;
reg [8:0] frame;
reg start;

localparam FSM_IDLE	= 4'd0,
			  FSM_PRE 	= 4'd1,
           FSM_FFT  	= 4'd2,
			  FSM_MAG 	= 4'd3,
			  FSM_MEL 	= 4'd4,
			  FSM_LOG 	= 4'd5,
			  FSM_UART 	= 4'd6,
			  FSM_RECORD= 4'd7,
			  FSM_PCM	= 4'd8,
			  FSM_PLAYER= 4'd9;

always @ (posedge clk_50mhz or negedge reset) 
begin
	if (!reset)
		begin
			FSM_MAIN 		<= 0;
			frame				<= 0; 
			
			write_sram 		<= 0;	
			read_sram  		<= 0;
			run_audio 		<= 0;
			led_1 			<= 0;
			led_2				<= 0;
			
			pre_address_sram <= 0;
			address_ram 	<= 0;
			pre_run 			<= 0;
			stt_main 		<= 0;
			start 			<= 0;
			
			read_cnt     	<= 0;
			sink_valid   	<= 0;
			sink_sop     	<= 0;
			sink_eop     	<= 0;
			source_ready 	<= 0;
			fsm_fft 			<= 0;
			out_frame 		<= 1'b0;
		  
			cnt_mag			<= 0;
			valid_mag 		<= 0;
			
			cnt_mel			<= 0;
			cnt_lut 			<= 0;
			
			start_uart_new <=	0;
			data_byte 		<= 0;
			send_lut 		<= 0;
			in_valid_lut 	<= 0;
			
		end
	else
		case (FSM_MAIN)
			FSM_IDLE:
				begin
					write_sram 	<= 0;
					read_sram	<= 0;
					run_audio 	<= 0;
					
					//******** TÍNH PRE ********//
					pre_address_sram <= 0;
					address_ram 	<= 0;
					stt_main			<= 0;
					
					ham_run <= 0;
					index_hamming <= 0;
					
					sink_valid   	<= 0;
					source_ready 	<= 0;
					read_cnt     	<= 0;
					sink_sop     	<= 0;
					sink_eop     	<= 0;
					fsm_fft 			<= 0;
					out_frame 		<= 1'b0;
					
					cnt_mag 			<= 0;
					valid_mag 		<= 0;
					
					cnt_mel			<= 0;
					rx_send_sig 	<= 0;
					bin_valid_sig	<= 0;
					
					cnt_lut 			<= 0;
					
					start_uart_new <= 0;
					data_byte		<= 0;
						
					led_3	<= 0;
					led_4	<= 0;
					led_5	<= 0;
					led_6	<= 0;
					led_7	<= 0;
					led_8	<= 0;
					led_9 <= 1;
					led_10<= 0;
					led_11<= 1;
					led_12<= 1;
					led_13<= 1;
					
					frame		<= 0;
					
					if(!key1 && !start) begin FSM_MAIN <= FSM_PRE; start <= 1; end
					else if(SW1 && !key2)	FSM_MAIN <= FSM_RECORD;
					else if(SW2 && !key2)	FSM_MAIN <= FSM_PLAYER;
					else if(SW3 && !key2)	FSM_MAIN <= FSM_PCM;
				end
				
			FSM_RECORD:
				begin
					case(stt_main)
					5'd0:
						begin
							run_audio <= 1;
							write_sram <= 1;			// ghi SRAM
							read_sram <= 0;
							stt_main <= 1;
							led_1 <=  0;
						end
					5'd1:	if(audio_address_sram >= 19'd47999) 
						begin
							run_audio <= 0;
							write_sram <= 0;			
							read_sram <= 0;
							led_1 <=  1;
							FSM_MAIN <= FSM_IDLE;
						end
					endcase
				end
				
			FSM_PLAYER:
				begin
					case(stt_main)
					5'd0:
						begin
							run_audio <= 1;
							write_sram <= 0;			// DOC SRAM
							read_sram <= 1;
							stt_main <= 1;
							led_2 <=  0;
						end
					5'd1:	if(audio_address_sram >= 19'd47999) 
						begin
							run_audio <= 0;
							write_sram <= 0;			
							read_sram <= 0;
							led_2 <=  1;
							FSM_MAIN <= FSM_IDLE;
						end
					endcase
				end
				
			FSM_PCM:				// gửi mẫu âm thanh thu được lên PC.
				begin
					case(stt_main)	
						5'd0:
							begin
								write_sram <= 0;			
								read_sram <= 1;
								pre_address_sram <= 0;
								stt_main <= 1;
							end
						5'd1:	begin
							if(!busy_uart_new)
								begin
									data_in_uart <= {readdata_sram, 32'd0};
									start_uart_new <= 1;
									stt_main <= 2;
									data_byte <= 2;
								end
							end
						5'd2: if(busy_uart_new)
							begin
								start_uart_new <= 0;
								stt_main <= 3;
							end
						5'd3:	if(done_uart_new)
							begin
								pre_address_sram <= pre_address_sram + 5'd1;
								stt_main <= 4;	
							end
						5'd4:	
							begin
								if(pre_address_sram >= 19'd47999) 
									begin
										stt_main <= 0;
										start_uart_new <= 0;
										FSM_MAIN <= FSM_IDLE;
									end
								else	stt_main <= 1;
							end
					endcase
				end
				
			FSM_PRE:			// lọc Âm thanh
				begin
					case(stt_main)
					5'd0:
						begin
							wren <= 1;					// ghi RAM
							write_sram <= 0;			// doc SRAM
							read_sram <= 1;
							stt_main <= 1;
							led_9 <= 0;
							address_ram <= 0;
							pre_address_sram <= (frame * 128);
							pre_run <= 0;
							frame_new <= 1;
							
							ham_run <= 0;
							index_hamming <= 0;

							
						end
					5'd1:
						begin
							pre_run <= 1;
							if(pre_done) 
								begin 
									stt_main <= 2;
									frame_new <= 0;
								end
						end
					5'd2:
						begin
							pre_run <= 0;
							ham_run <= 1;
//							write_data_ram <= data_pre;
//							data_in_FFT[address_ram] <= data_pre;
							stt_main <= 3;
						end
						
					5'd3:
						if(ham_done)
							 begin
								write_data_ram <= data_out_hamming;
								ham_run <= 0;
								index_hamming <= index_hamming + 8'd1; 
								stt_main <= 4;
							 end
						
					5'd4:
						begin
							pre_address_sram <= pre_address_sram + 9'd1 ;
							address_ram <= address_ram + 9'd1;
							stt_main <= 5;
						end
					5'd5:
						begin
							if(address_ram > 255) 
								begin
									FSM_MAIN <= FSM_FFT;
									stt_main <= 0;	
									led_3	<= 1;
								end
							else  stt_main <= 1;
						end
					endcase
				end
			FSM_FFT:
				begin
					case (stt_main)
					5'd0: begin				// SEND
						case (fsm_fft)
						  0: 	begin
									wren	  <= 0;		// DOC RAM
									fsm_fft <= 1;	
									address_ram <= 0;
								end
						  1: 	begin
//									sink_real <= data_in_FFT[fft_address_ram];   // chốt trước khi valid
									sink_real <= read_data_ram;
									sink_sop  <= (address_ram == 0);
									sink_eop  <= (address_ram == 255);
									sink_valid  <= 1'b1;            				// data đã sẵn sàng, bắt đầu xin gửi
									fsm_fft     <= 2;
								end
						
						  2: 	begin
									if (sink_ready) 
										begin
											sink_valid   <= 1'b0;
											address_ram <= address_ram + 9'd1;
											if (address_ram == 255) 
												begin
													fsm_fft <= 0; // xong frame
													stt_main <= 1;
												end
											else  fsm_fft <= 1; // gửi mẫu tiếp theo
										end
								end
						endcase
					end					
					
					//==================================================
					5'd1: 
						begin
							sink_valid <= 0;
							sink_sop   <= 0;
							sink_eop   <= 0;
							source_ready <= 1;
							stt_main    <= 2;
							read_cnt <= 0;
						end
				  
					5'd2:
						if (source_valid && source_ready) 
							begin
								if (source_sop) 
									begin
										out_frame <= 1'b1;
										read_cnt   <= 9'd0;
									end 
								else if(out_frame) 
									begin
										read_cnt <= read_cnt + 9'd1;
									end
								fft_real_ram[read_cnt] <= source_real;
								fft_imag_ram[read_cnt] <= source_imag;
				
								if (source_eop) 
									begin
										out_frame <= 1'b0;
										stt_main <= 3;
									end
							end
					5'd3: 
						begin
							source_ready <= 0;
							FSM_MAIN <= FSM_MAG;
							stt_main <= 0;
							led_4	<= 1;
						end
					endcase	
				end				
				
			FSM_MAG:
				begin
					case(stt_main)
					5'd0: 
						begin
							re_sig <= fft_real_ram[cnt_mag];
							im_sig <= fft_imag_ram[cnt_mag];
							valid_mag <= 1;
							stt_main <= 1;
						end
					5'd1: if(mag_valid_sig)
						begin
							valid_mag <= 0;
							data_mag[cnt_mag] <= mag_sig;
							cnt_mag <= cnt_mag + 8'd1;
							stt_main <= 2;
						end
					5'd2: 
						begin
							if(cnt_mag > 8'd127 )	
								begin
									FSM_MAIN <= FSM_MEL;
									cnt_mag <= 0;
									stt_main <= 0;
									led_5	<= 1;
								end
							else if(!mag_valid_sig) stt_main <= 0;
						end
					endcase
				end
			FSM_MEL:
				begin
					case(stt_main)
					5'd0:
						begin
							bin_valid_sig <= 0;
							cnt_mel	<= 0;
							stt_main <= 1;
							start_calc_sig <=  0;
							rd_ready_in_sig <= 0;
						end
					5'd1: if(rx_ready_sig)
							begin
								rx_send_sig <= 1;
								stt_main <= 2;
							end
					5'd2: if(!rx_done_sig)
						begin	
							bin_valid_sig <=  1;
							bin_data_sig  <= data_mag[7'd5 + cnt_mel];
							stt_main <= 3;	
							led_10 <= 1;
						end
					5'd3: if(rx_done_sig)
						begin
							led_11 <= 0;
							bin_valid_sig <=  0;
							cnt_mel <= cnt_mel + 7'd1;
							if(cnt_mel >= 64) stt_main <= 4;
							else	 stt_main <= 2;
						end
					5'd4: 
						begin 
							rx_send_sig <= 0;
							start_calc_sig <=  1; 
							stt_main <= 5; 
							led_12 <= 0;	
						end
					5'd5: if(calc_done_sig) 
						begin 
							rd_ready_in_sig <= 1; 
							stt_main <= 6;  
							led_13 <= 0;
						end
					5'd6: if(mel_valid_sig)
						begin
							mel_20_data[mel_index_sig] <= mel_out_sig;
							if(read_done_sig) 
								begin 
									FSM_MAIN <= FSM_LOG;
										
									stt_main <= 0;
									led_6	<= 1;
								end
						end
					endcase
				end
				
			FSM_LOG:
				begin
					case(stt_main)
					5'd0: if(!out_valid_lut)
						begin
							data_test <= mel_20_data[cnt_lut];				//48'd3051584
							in_valid_lut <= 1;
							stt_main <= 1;
						end
					5'd1:if(out_valid_lut)
						begin
							out_data_lut[cnt_lut] <= lut_data_out;
							stt_main <= 2;
							cnt_lut <= cnt_lut +5'd1;
						end
					5'd2:	
						begin
							in_valid_lut <= 0;
							if(cnt_lut<20) stt_main <= 0;
							else
								begin
									stt_main <= 0;
									FSM_MAIN	<= FSM_UART;
									led_7 <= 1;
									cnt_lut <= 0;
								end
						end
					endcase
				end
			
			FSM_UART:
				begin
					case(stt_main)		
						5'd0:	begin
							if(!busy_uart_new)
								begin
									data_in_uart <= {out_data_lut[send_lut], 24'd0};
									start_uart_new <= 1;
									stt_main <= 1;
									data_byte <= 3;
								end
							end
						5'd1: if(busy_uart_new)
							begin
								start_uart_new <= 0;
								stt_main <= 2;
							end
						5'd2:	if(done_uart_new)
							begin
								send_lut <= send_lut + 5'd1;
								stt_main <= 3;	
							end
						5'd3:	
							begin
								if(send_lut > 5'd19) 
									begin
										stt_main <= 4;
										start_uart_new <= 0;
										send_lut <= 0;
										frame <= frame + 8'd1;
									end
								else	stt_main <= 0;
							end
						5'd4:
							begin
								if(frame > 374)
									begin
										FSM_MAIN	<= FSM_IDLE;
										led_8	<= 1;
									end
								else
									begin
										FSM_MAIN	<= FSM_PRE;	
										stt_main <= 0;
										led_3	<= 0;
										led_4	<= 0;
										led_5	<= 0;
										led_6	<= 0;
										led_7	<= 0;
										led_10 <= 0;
										led_11 <= 1;
										led_12 <= 1;
										led_13 <= 1;
									end
							end
					endcase
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


log2_u48	u9
(
    .clk(clk_50mhz),
    .rst_n(reset),
    .in_valid(in_valid_lut),
    .x(data_test),

    .out_valid(out_valid_lut),
    .y(lut_data_out)
);


magnitude_calc magnitude_calc_inst
(
	.clk(clk_50mhz) ,					
	.valid(valid_mag) ,				
	.re(re_sig) ,						
	.im(im_sig) ,						
	.mag(mag_sig) ,					
	.mag_valid(mag_valid_sig) 		
);	


uart_send UART_NEW
(
    .clk(clk_50mhz),
    .reset_n(reset),

    .start(start_uart_new),     		// xung bắt đầu gửi
    .data_in(data_in_uart),     		// dữ liệu lớn nhất 48 bit
    .data_bytes(data_byte),     		// số byte cần gửi: 2,3,4,6
	 .UART_TX(UART_TX),
	 .UART_RX(UART_RX),

    .uart_data(),      					// byte đưa vào UART
    .done(done_uart_new),           // gửi xong toàn bộ packet
    .busy(busy_uart_new)            // đang gửi packet
);


pre_emphasis u7(
    .clk(clk_50mhz),
	 .rst(reset),
	 .pre_run(pre_run),
    .x_in(readdata_sram),
    .y_out(data_pre),
	 .pre_done(pre_done),
	 .frame_new(frame_new)
);


gen_lrclk_16k u1(
	 .BCLK(clk_512Khz),       // 1.536 MHz
	 .reset(reset),
	 .LRCLK(clk_16khz)       	// 48 kHz
);


pll u2(
		.inclk0(clk_50mhz),
		.c0(clk_12Mhz),
		.c1(clk_100Khz),
		.c2(clk_512Khz)
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
	
hamming_256 hamming(
    .clk(clk_50mhz),
    .rst(reset),          // active low reset

    .ham_run(ham_run),
    .index (index_hamming),  // 0 -> 255
    .x_in (data_pre),

    .y_out(data_out_hamming),
    .ham_done (ham_done)
);
	
endmodule













