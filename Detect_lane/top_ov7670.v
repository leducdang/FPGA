module top_ov7670(
						clock_50mhz,
						
						// I2C	- khai bao chan vao ra cho I2C
						pin_scl,
						pin_sda,
						
						// SRAM	- khai bao chan vao ra cho SRAM
						SRAM_DQ,       // external_interface.DQ
						SRAM_ADDR,     //                   .ADDR
						SRAM_LB_N,     //                   .LB_N
						SRAM_UB_N,     //                   .UB_N
						SRAM_CE_N,     //                   .CE_N
						SRAM_OE_N,     //                   .OE_N
						SRAM_WE_N,     //                   .WE_N
						
						// SDRAM
						SDRAM_addr,    //     sdram.addr
						SDRAM_ba,      //          .ba
						SDRAM_cas_n,   //          .cas_n
						SDRAM_cke,     //          .cke
						SDRAM_cs_n,    //          .cs_n
						SDRAM_dq,      //          .dq
						SDRAM_dqm,     //          .dqm
						SDRAM_ras_n,   //          .ras_n
						SDRAM_we_n,    //          .we_n
						SDRAM_clk_clk,  // sdram_clk.clk
						
						//CAMERA	- khai báo chân vào ra cho CAMERA
						XCLK_CAMERA,
						PCLK_CAMERA,
						VSYNC_CAMERA,
						HREF_CAMERA,
						DATA_CAMERA,
				
						// PORT VGA	-	khai báo chân vào ra cho cổng VGA
						pin_r,
						pin_g,
						pin_b,
						pin_vga_clock,
						pin_sync,
						pin_bank,
						pin_hs,
						pin_vs,
						
						//PORT MAIN	- Khai báo chân điều khiển
						pin_start,	  // key 2
						pin_reset,	  // key 0
						bt_config,    // key 3
						
						// GIA TRI LOC MAU RGB
						fil_R,
						fil_G,
						fil_B,
						
						//TEST		- cac chan dung de test chuong trình
						led_test,
						led_g0
						);

//************ TOP ****************//						
						
input 			clock_50mhz;			// xung clock vao
input 			pin_reset;				// chan reset

//************ TEST ****************//

output	[18:0]	led_test;			// led test
input  			pin_start;				// nut nhan bat dau chay chuong trinh
output reg 		led_g0 = 0;				// hien thị toc do fbs

//************ FILLTER RGB ****************//
input	[4:0]		fil_R;
input	[5:0]		fil_G;
input	[4:0]		fil_B;
	
//************ i2c config **********//	khai báo in-out cac chan I2C
output			pin_scl;
inout				pin_sda;
input				bt_config;			 // key 3

wire		[6:0] o_index;
wire				done_config;

//************ SRAM ****************//	khai bao in-out cac chan SRAM

inout  wire [15:0] SRAM_DQ;       // external_interface.DQ
output wire [19:0] SRAM_ADDR;     //                   .ADDR
output wire        SRAM_LB_N;     //                   .LB_N
output wire        SRAM_UB_N;     //                   .UB_N
output wire        SRAM_CE_N;     //                   .CE_N
output wire        SRAM_OE_N;     //                   .OE_N
output wire        SRAM_WE_N;     //                   .WE_N

reg 	[18:0] 	address_sram;       	//  avalon_sram_slave.address
reg 	[1:0]  	byteenable_sram;    	//                   .byteenable
reg        		read_sram;          	//                   .read
reg        		write_sram;         	//                   .write
reg 	[15:0] 	writedata_sram;     	//                   .writedata
wire 	[15:0] 	readdata_sram;      	//                   .readdata
wire        	readdatavalid; 		//                   .readdatavalid

// SDRAM
output  [12:0] SDRAM_addr;    //     sdram.addr
output  [1:0]  SDRAM_ba;      //          .ba
output         SDRAM_cas_n;   //          .cas_n
output         SDRAM_cke;     //          .cke
output         SDRAM_cs_n;    //          .cs_n
inout   [31:0] SDRAM_dq;      //          .dq
output  [3:0]  SDRAM_dqm;     //          .dqm
output         SDRAM_ras_n;   //          .ras_n
output         SDRAM_we_n;    //          .we_n
output         SDRAM_clk_clk;  // sdram_clk.clk
		
reg [24:0] 	SDRAM_address;       //   sdram_1.address
reg [3:0]  	SDRAM_byteenable_n = 4'b0000;  //          .byteenable_n
reg        	SDRAM_chipselect = 1'b1;    //          .chipselect
reg [31:0] 	SDRAM_writedata;     //          .writedata
reg         SDRAM_read_n;        //          .read_n
reg        	SDRAM_write_n;       //          .write_n
wire [31:0] SDRAM_readdata;      //          .readdata
wire        SDRAM_readdatavalid; //          .readdatavalid
wire        SDRAM_waitrequest;   //          .waitrequest

reg [1:0]	byteRW;					  //	= 0 Write, =1 Read
reg [31:0]	dataRead;
		
//************ READ DATA CAMERA ****************//	khai bao in-out cac chan Camera

output				XCLK_CAMERA;
input					PCLK_CAMERA;
input					VSYNC_CAMERA;
input					HREF_CAMERA;
input	[7:0]			DATA_CAMERA;


wire	[15:0]		DATA_OUT_CAMERA;
wire	[18:0]		addr_camera;
reg					enable_camera;
wire					stt_read_data_camera;				
reg					stt_write_data;
wire					pixel_valid;
wire					frame_done;

assign XCLK_CAMERA = clock_25Mhz;

//************ PORT VGA ************************//

output [7:0] pin_r;
output [7:0] pin_g;
output [7:0] pin_b;
output	pin_vga_clock;
output	pin_sync;
output	pin_bank;
output	pin_hs;
output	pin_vs;

reg	[7:0]	iRed;
reg	[7:0]	iGreen;
reg	[7:0]	iBlue;
wire	[18:0]	oAddress;
wire	[10:0]	x;
wire	[10:0]	y;
wire				oRequest;
reg 				stt_read_sram;
reg				enable_vga;
reg	[15:0] pixel_data;

//************ PORT RAM ************************//

reg	[16:0]  address_ram;
reg	[15:0]  data_ram;
reg	  write_ram;					//0 doc 1 ghi
wire	[15:0]  readdata_ram;

reg	[16:0]  address_ram2;
reg	[15:0]  data_ram2;
reg	  write_ram2;					//0 doc 1 ghi
wire	[15:0]  readdata_ram2;

//************ PLL CREATE CLOCK ****************//

wire 	clock_200Mhz;
wire 	clock_100Mhz;
wire 	clock_25Mhz;
wire 	clock_100Khz;

// ===== FIFO =====
wire [15:0] fifo_pixel;
wire fifo_empty;

//wire 	clock_100Mhz;
/* c0 - 200Mhz
	c1 - 24Mhz
	c2 - 48Mhz
	c3 - 100Khz
*/
/*
SDRAM
	READ:		SDRAM_read_n 	<= 0;    SDRAM_write_n <= 1;
	WRITE: 	SDRAM_write_n 	<= 0;		SDRAM_read_n  <= 1;
	IDLE:		SDRAM_read_n  <= 1;		SDRAM_write_n <= 1;

SRAM
	WRITE: 	write_sram <= 1;	read_sram <= 0;
	READ: 	write_sram <= 0;	read_sram <= 1;
	IDLE:		write_sram <= 0;	read_sram <= 0;

RAM
	WRITE:	write_ram <= 1;
	READ:		write_ram <= 0;
	*/


reg	[2:0] FMS;						// khai bao bien trang thai may
reg	[0:0] slectMemory = 0;		// = 0 sram; = 1 ram

always @ (posedge clock_50mhz )
begin
	if(!pin_reset)		FMS <= 3'd0;							// reset bien FMS ve 0
	if(!pin_start) 	FMS <= 1; 								// nhan start de bat dau
	
	case(FMS)
		3'd1: if(addr_camera == 0)  
				begin
					write_ram	<= slectMemory;
					write_ram2  <= ~ slectMemory;
					FMS <= 3'd2; 									// chờ dia chi camera = 0
				end
		3'd2: begin
					if(addr_camera >= 76799 ) FMS <= 3'd3;	// neu du 320x240 Pixel thì thoat
					else if(slectMemory)							// luu gia tri pixel vao ram
						begin
							address_ram <=  addr_camera;
							data_ram <= DATA_OUT_CAMERA;
						end
					else if(!slectMemory)						// luu gia tri pixel vao sram
						begin	
							address_ram2 <=  addr_camera;
							data_ram2 <= DATA_OUT_CAMERA;
						end
				end
		3'd3: if(!frame_done)									// chờ khi hoan thanh 1 khung anh
					begin
						led_g0 <= slectMemory;
						FMS <= 3'd4; 
						slectMemory <= ~ slectMemory;			// đảo vi tri lưu giá trị pixel
					end

		3'd4:	FMS <= 3'd1; 										// lặp lại quá trình mới
	endcase

	if(!slectMemory && (y < 11'd240) && (x < 11'd320)) address_ram <=  y*320 + x ;
	if( slectMemory && (y < 11'd240) && (x < 11'd320)) address_ram2 <=  y*320 + x ;	
end




/*----------------------- XU LY ANH ---------------------*/

// ===== PIXEL =====
reg [8:0]  Px;   // 0..319
reg [8:0]  Py;   // 0..239    // ko được khai báo 8 bit sẽ gây lôi tran bit

// ===== COL SUM =====
reg [4:0] col_sum [0:319];

// ===== WINDOW PIPELINE =====
reg [7:0] win_sum_cur, win_sum_prev;
reg [4:0] col_front_val, col_back_val;

// ===== MAX DETECT =====
reg [7:0] sum_left_max, sum_right_max;
reg [8:0] left_pos, right_pos;
reg [8:0] x_center;

// ===== FSM =====
//reg [3:0] step;
reg [1:0] win_pipe_state;

reg [7:0] win_sum_next;
reg [8:0] x_win;

reg [2:0] state_handle;
parameter DETECT_IMAGE_1 = 0, DISPLAY_IMAGE = 2, DETECT_IMAGE = 1, DETECT_LANE_1 = 3, DETECT_LANE = 4, WRITE_IMAGE = 5; 
reg [4:0] step;

// ===== Bit Selcect Detect =====
reg ram_detect; 		// = 1 SRAM display ,   = 0 SDRAM display

// DOC DU LIEU TU IP RAM VA GUI GIA TRI MAU SAC RA CONG VGA.

always@(posedge clock_100Mhz)
begin
	if(!pin_reset) 
		begin
			state_handle <= DETECT_IMAGE;
			address_sram <= 0;
			step <= 0;
			Px <= 0;
			Py <= 0;
			ram_detect <= 0;
		end
	else 
		begin
		
/* ---------------------------------------------------------
   ------------------------- SRAM --------------------------
   ---------------------------------------------------------*/
	
			case (state_handle)	
				DETECT_IMAGE:
				begin
					case (step)	
						0: begin						// enable write
								read_sram <= 0;
								write_sram <= 1;
								if(addr_camera == 0) step <= 1;
								byteenable_sram <= 2'b11;
							end
						1: begin
								if(addr_camera >= 76799 ) step <= 3;	
								else
									begin
										address_sram <= addr_camera + 20'd100_000;
										if((DATA_OUT_CAMERA[15:11] >= fil_R) && (DATA_OUT_CAMERA[10:5] >= fil_G) && (DATA_OUT_CAMERA[4:0] < fil_B) && (DATA_OUT_CAMERA[10:5] > DATA_OUT_CAMERA[15:11]))
											writedata_sram <= 16'hffff;
										else
											writedata_sram <= 16'h0000;
											step <= 2;
									end
							end
						2: begin
								address_sram <= addr_camera + 20'd200_000;
								if((DATA_OUT_CAMERA[15:11] >= fil_R) && (DATA_OUT_CAMERA[10:5] >= fil_G) && (DATA_OUT_CAMERA[4:0] < fil_B) && (DATA_OUT_CAMERA[10:5] > DATA_OUT_CAMERA[15:11]))
									writedata_sram <= 16'h0001;
								else
									writedata_sram <= 16'h0000;
									step <= 1;
							end
						3: begin
										state_handle <= DETECT_LANE;
										step <= 0;
//										led <= 1;
							end
					endcase
				end
				
				DETECT_LANE:
				begin
					case(step)
						0: begin
							Px <= 0;
							step <= 1;
						end

						1: begin
							col_sum[Px] <= 0;
							Px <= Px + 9'd1;
							if (Px == 319) begin
								Px <= 0;
								Py <= 120;
								step <= 2;
							end
						end
						2: begin
							read_sram <= 1;
							write_sram <= 0;
							address_sram <= Py*320 + Px + 20'd200_000;
							step <= 3;
						end

						3: step <= 4;
						4: begin
							col_sum[Px] <= col_sum[Px] + readdata_sram[0];
							Py <= Py + 9'd1;
							if (Py == 140) begin
								Py <= 120;
								Px <= Px + 9'd1;
								if (Px == 319) step <= 5;
								else step <= 2;
							end
							else step <= 2;
						end
						5: begin
							x_win <= 4;
							win_sum_prev <= col_sum[0] + col_sum[1] + col_sum[2]
													+ col_sum[3] + col_sum[4]
													+ col_sum[5] + col_sum[6];

							sum_left_max  <= 0;
							sum_right_max <= 0;
							left_pos  <= 0;
							right_pos <= 0;

							win_pipe_state <= 0;
							step <= 6;
						end

						6: begin
							case (win_pipe_state)

							// ========= CYCLE 0 =========
							2'd0: begin
								col_front_val <= col_sum[x_win - 4];
								win_pipe_state <= 2'd1;
							end

							// ========= CYCLE 1 =========
							2'd1: begin
								col_back_val <= col_sum[x_win + 3];
								win_pipe_state <= 2'd2;
							end

							// ========= CYCLE 2 =========
							2'd2: begin
								win_sum_next <= win_sum_prev - col_front_val + col_back_val;
								win_pipe_state <= 2'd3;
							end

							// ========= CYCLE 3 =========
							2'd3: begin
								win_sum_prev <= win_sum_next;

							// detect max
								if (x_win < 160) begin
									if (win_sum_next > sum_left_max) begin
										sum_left_max <= win_sum_next;
										left_pos <= x_win;
									end
								end else begin
										if (win_sum_next > sum_right_max) begin
										sum_right_max <= win_sum_next;
										right_pos <= x_win;
										end
								end

								x_win <= x_win + 9'd1;
								win_pipe_state <= 2'd0;

								if (x_win == 316)
									step <= 7;
								end
							endcase
						end

						7: begin
							write_sram <= 1;
							read_sram  <= 0;
							Px <= 0;
							Py <= 120;
							step <= 8;
							x_center <= (left_pos + right_pos)/2;
						end

						8: begin
							address_sram <= Py*320 + left_pos - 3 + Px + 20'd100_000;
							writedata_sram <= 16'hF800;
							Py <= Py + 9'd1;
							if (Py == 140) begin
								Py <= 120;
								Px <= Px + 9'd1;
								if(Px == 7)
									begin
									Px <= 0;
									step <= 9;
									end
							end
						end

						9: begin
							address_sram <= Py*320 + right_pos - 3 + Px + 20'd100_000;
							writedata_sram <= 16'hF800;
							Py <= Py + 9'd1;
							if (Py == 140)begin
								Py <= 120;
								Px <= Px + 9'd1;
								if(Px == 7)
									begin
									Px <= 0;
									step <= 10;
									end
								end
						end
						
						10:begin
							address_sram <= Py*320 + x_center + Px + 20'd100_000;
							writedata_sram <= 16'hffff;
							Py <= Py + 9'd1;
							if (Py == 140)begin
								Py <= 120;
								Px <= Px + 9'd1;
								if(Px == 7)
									begin
									Px <= 0;
									step <= 11;
									end
								end
						end
						
						11:begin
							read_sram <= 1;
							write_sram <= 0;
							step <= 0;
							state_handle <= DETECT_IMAGE_1;
							ram_detect <= 1; 								// CHO PHEP DOC SRAM
						end
					endcase
				end

/* ---------------------------------------------------------
   ------------------------- SDRAM --------------------------
   ---------------------------------------------------------*/
				DETECT_IMAGE_1:
				begin
					case (step)	
						0: begin						// enable write
								SDRAM_read_n 	<= 1;    
								SDRAM_write_n <= 0;
								if(addr_camera == 0) step <= 1;
							end
						1: begin
								if(addr_camera >= 76799 ) step <= 3;	
								else
									begin
										SDRAM_address <= addr_camera + 20'd100_000;
										if((DATA_OUT_CAMERA[15:11] >= fil_R) && (DATA_OUT_CAMERA[10:5] >= fil_G) && (DATA_OUT_CAMERA[4:0] < fil_B) && (DATA_OUT_CAMERA[10:5] > DATA_OUT_CAMERA[15:11]))
											SDRAM_writedata <= 32'hffff_ffff;
										else
											SDRAM_writedata <= 32'h0000_0000;
											step <= 2;
									end
							end
						2: begin
								SDRAM_address <= addr_camera + 20'd200_000;
								if((DATA_OUT_CAMERA[15:11] >= fil_R) && (DATA_OUT_CAMERA[10:5] >= fil_G) && (DATA_OUT_CAMERA[4:0] < fil_B) && (DATA_OUT_CAMERA[10:5] > DATA_OUT_CAMERA[15:11]))
									SDRAM_writedata <= 32'h0000_0001;
								else
									SDRAM_writedata <= 32'h0000_0000;
									step <= 1;
							end
						3: begin
										state_handle <= DETECT_LANE_1;
										step <= 0;
//										led <= 1;
							end
					endcase
				end
				
				DETECT_LANE_1:
				begin
					case(step)
						0: begin
							Px <= 0;
							Py <= 120;
							step <= 1;
						end

						1: begin
							col_sum[Px] <= 0;
							Px <= Px + 9'd1;
							if (Px == 319) begin
								Px <= 0;
								step <= 2;
							end
						end
						2: begin											// ENABLE READ SDRAM
							SDRAM_read_n 	<= 0;    
							SDRAM_write_n <= 1;
							SDRAM_address <= Py*320 + Px + 20'd200_000;
							step <= 3;
						end

						3: step <= 4;
						4: begin
							col_sum[Px] <= col_sum[Px] + SDRAM_readdata[0];
							Py <= Py + 9'd1;
							if (Py == 140) begin
								Py <= 120;
								Px <= Px + 9'd1;
								if (Px == 319) step <= 5;
								else step <= 2;
							end
							else step <= 2;
						end
						5: begin
							x_win <= 4;
							win_sum_prev <= col_sum[0] + col_sum[1] + col_sum[2]
													+ col_sum[3] + col_sum[4]
													+ col_sum[5] + col_sum[6];

							sum_left_max  <= 0;
							sum_right_max <= 0;
							left_pos  <= 0;
							right_pos <= 0;

							win_pipe_state <= 0;
							step <= 6;
						end

						6: begin
							case (win_pipe_state)

							// ========= CYCLE 0 =========
							2'd0: begin
								col_front_val <= col_sum[x_win - 4];
								win_pipe_state <= 2'd1;
							end

							// ========= CYCLE 1 =========
							2'd1: begin
								col_back_val <= col_sum[x_win + 3];
								win_pipe_state <= 2'd2;
							end

							// ========= CYCLE 2 =========
							2'd2: begin
								win_sum_next <= win_sum_prev - col_front_val + col_back_val;
								win_pipe_state <= 2'd3;
							end

							// ========= CYCLE 3 =========
							2'd3: begin
								win_sum_prev <= win_sum_next;

							// detect max
								if (x_win < 160) begin
									if (win_sum_next > sum_left_max) begin
										sum_left_max <= win_sum_next;
										left_pos <= x_win;
									end
								end else begin
										if (win_sum_next > sum_right_max) begin
										sum_right_max <= win_sum_next;
										right_pos <= x_win;
										end
								end

								x_win <= x_win + 9'd1;
								win_pipe_state <= 2'd0;

								if (x_win == 316)
									step <= 7;
								end
							endcase
						end

						7: begin
							SDRAM_read_n  <= 1;    
							SDRAM_write_n <= 0;
							Px <= 0;
							Py <= 120;
							step <= 8;
							x_center <= (left_pos + right_pos)/2;
						end

						8: begin
							SDRAM_address <= Py*320 + left_pos - 3 + Px + 20'd100_000;
							SDRAM_writedata <= 16'hF800;
							Py <= Py + 9'd1;
							if (Py == 140) begin
								Py <= 120;
								Px <= Px + 9'd1;
								if(Px == 7)
									begin
									Px <= 0;
									step <= 9;
									end
							end
						end

						9: begin
							SDRAM_address <= Py*320 + right_pos - 3 + Px + 20'd100_000;
							SDRAM_writedata <= 16'hF800;
							Py <= Py + 9'd1;
							if (Py == 140)begin
								Py <= 120;
								Px <= Px + 9'd1;
								if(Px == 7)
									begin
									Px <= 0;
									step <= 10;
									end
								end
						end
						
						10:begin
							SDRAM_address <= Py*320 + x_center + Px + 20'd100_000;
							SDRAM_writedata <= 16'hffff;
							Py <= Py + 9'd1;
							if (Py == 140)begin
								Py <= 120;
								Px <= Px + 9'd1;
								if(Px == 7)
									begin
									Px <= 0;
									step <= 11;
									end
								end
						end
						
						11:begin
							SDRAM_read_n  <= 0;    
							SDRAM_write_n <= 1;
							step <= 0;
							state_handle <= DETECT_IMAGE;
							ram_detect <= 0;
						end
					endcase
				end
			endcase
		end
	if(ram_detect==0)
		begin
			if((y < 11'd240) && (x > 11'd319) && (x < 11'd640))
			SDRAM_address <= y*320 + x - 320 + 20'd100_000 ;
		end
		else
		begin
			if((y < 11'd240) && (x > 11'd319) && (x < 11'd640))
			address_sram  <= y*320 + x - 320 + 20'd100_000 ;
		end
end


reg [7:0]	mVGA_R;				//memory output to VGA 8bit only
reg [7:0]	mVGA_G;
reg [7:0]	mVGA_B;

always @(posedge clock_50mhz) begin
	if(slectMemory)
	begin
		if((x < 11'd320) && (y < 11'd240) )
			begin
			mVGA_R <= {readdata_ram2[15:11],3'b111};
			mVGA_G <= {readdata_ram2[10:5],2'b11};
			mVGA_B <= {readdata_ram2[4:0],3'b111};
			end
		else
			begin
			mVGA_R <= 8'h00;
			mVGA_G <= 8'h00;
			mVGA_B <= 8'h00;
			end
	end
	else
	begin
		if((x < 11'd320) && (y < 11'd240) )
			begin
			mVGA_R <= {readdata_ram[15:11],3'b111};
			mVGA_G <= {readdata_ram[10:5],2'b11};
			mVGA_B <= {readdata_ram[4:0],3'b111};
			end
		else
			begin
			mVGA_R <= 8'h00;
			mVGA_G <= 8'h00;
			mVGA_B <= 8'h00;
			end
	end
	if((x < 11'd640) && (y < 11'd240) && (x > 11'd319))
	begin
		if(ram_detect)
		begin
			mVGA_R <= {readdata_sram[15:11],3'b111};
			mVGA_G <= {readdata_sram[10:5],2'b11};
			mVGA_B <= {readdata_sram[4:0],3'b111};
		end
		else
		begin
			mVGA_R <= {SDRAM_readdata[15:11],3'b111};
			mVGA_G <= {SDRAM_readdata[10:5],2'b11};
			mVGA_B <= {SDRAM_readdata[4:0],3'b111};
		end
	end
end

//assign led_test = address_sram;		// gán địa chỉ sram (test)

// KHAI BÁO MODULE CẤU HÌNH CAMERA

config_camera	u2(
						.clock_50mhz(clock_50mhz),
						.clock_100khz(clock_100Khz),
						.sda(pin_sda),
						.scl(pin_scl),
						.reset(pin_reset),
						.enable_config(bt_config),
						.done_config(done_config),
							//test
						.o_index(o_index)
							);

// KHAI BÁO MODULE TẠO XUNG CẤP CHO CÁC MODULE							
	
PLL u1(
	.inclk0(clock_50mhz),
	.c0(clock_200Mhz),
	.c1(clock_100Mhz),
	.c2(clock_25Mhz),
	.c3(clock_100Khz)
	);

// KHAI BÁO MODULE SRAM

sram u3(
		.address({1'b0,address_sram}),       //  avalon_sram_slave.address
		.byteenable(byteenable_sram),    //                   .byteenable
		.read(read_sram),          //                   .read
		.write(write_sram),         //                   .write
		.writedata(writedata_sram),     //                   .writedata
		.readdata(readdata_sram),      //                   .readdata
		.readdatavalid(readdatavalid), //                   .readdatavalid
		.clk(clock_200Mhz),           //                clk.clk
		.SRAM_DQ(SRAM_DQ),       // external_interface.DQ
		.SRAM_ADDR(SRAM_ADDR),     //                   .ADDR
		.SRAM_LB_N(SRAM_LB_N),     //                   .LB_N
		.SRAM_UB_N(SRAM_UB_N),     //                   .UB_N
		.SRAM_CE_N(SRAM_CE_N),     //                   .CE_N
		.SRAM_OE_N(SRAM_OE_N),     //                   .OE_N
		.SRAM_WE_N(SRAM_WE_N),     //                   .WE_N
		.reset(pin_reset)          //              reset.reset
	);

// KHAI BÁO MODULE ĐỌC DỮ LIỆU CAMERA
				
camera_read u4(
					.p_clock(PCLK_CAMERA),
					.vsync(VSYNC_CAMERA),
					.href(HREF_CAMERA),
					.p_data(DATA_CAMERA),
					.pixel_data(DATA_OUT_CAMERA),
					.pixel_valid(pixel_valid),
					.frame_done(frame_done),
					.wraddr(addr_camera)
    );					
	
// KHAI BÁO MODULE VGA -  HIỂN THỊ HÌNH ẢNH				

VGA_Ctrl	u5(	//	Host Side
						.iRed(mVGA_R),
						.iGreen(mVGA_G),
						.iBlue(mVGA_B),
						.oCurrent_X(x),
						.oCurrent_Y(y),
						.oAddress(oAddress),
						.oRequest(oRequest),
						//	VGA Side
						.oVGA_R(pin_r),
						.oVGA_G(pin_g),
						.oVGA_B(pin_b),
						.oVGA_HS(pin_hs),
						.oVGA_VS(pin_vs),
						.oVGA_SYNC(pin_sync),
						.oVGA_BLANK(pin_bank),
						.oVGA_CLOCK(pin_vga_clock),
						//	Control Signal
						.iCLK(clock_25Mhz),
						.iRST_N(pin_reset)
						);

RAM u6(
	.address(address_ram),
	.clock(clock_200Mhz),
	.data(data_ram),
	.wren(write_ram),
	.q(readdata_ram)
	);		

RAM u8(
	.address(address_ram2),
	.clock(clock_200Mhz),
	.data(data_ram2),
	.wren(write_ram2),
	.q(readdata_ram2)
	);	
	
 sdram u7 (
        .wire_addr             (SDRAM_addr),             //      wire.addr
        .wire_ba               (SDRAM_ba),               //          .ba
        .wire_cas_n            (SDRAM_cas_n),            //          .cas_n
        .wire_cke              (SDRAM_cke),              //          .cke
        .wire_cs_n             (SDRAM_cs_n),             //          .cs_n
        .wire_dq               (SDRAM_dq),               //          .dq
        .wire_dqm              (SDRAM_dqm),              //          .dqm
        .wire_ras_n            (SDRAM_ras_n),            //          .ras_n
        .wire_we_n             (SDRAM_we_n),             //          .we_n
        .sdram_clk_clk         (SDRAM_clk_clk),         // sdram_clk.clk
        .clk_clk               (clock_50mhz),             //       clk.clk
        .reset_reset_n         (pin_reset),             //     reset.reset
        .sdram_address       (SDRAM_address),       //   sdram_1.address
        .sdram_byteenable_n  (SDRAM_byteenable_n),  //          .byteenable_n
        .sdram_chipselect    (SDRAM_chipselect),    //          .chipselect
        .sdram_writedata     (SDRAM_writedata),     //          .writedata
        .sdram_read_n        (SDRAM_read_n),        //          .read_n
        .sdram_write_n       (SDRAM_write_n),       //          .write_n
        .sdram_readdata      (SDRAM_readdata),      //          .readdata
        .sdram_readdatavalid (SDRAM_readdatavalid), //          .readdatavalid
        .sdram_waitrequest   (SDRAM_waitrequest)    //          .waitrequest
    );

						
endmodule




//always@(posedge clock_50mhz )
//begin
//	if(!pin_reset)
//		begin
//			FMS <= 3'd0;				// reset bien FMS ve 0
//		end
//		
////	write_sram	<= ~ slectMemory;	// gan gia tri cho cac bien 
////	read_sram	<= slectMemory;
//	write_ram	<= slectMemory;
//	write_ram2  <= ~ slectMemory;
//	
//	SDRAM_read_n 	<= ~slectMemory;
//	SDRAM_write_n 	<= slectMemory;
//	
//	if(!pin_start)   FMS <= 1; 	// nhan start de bat dau
//	
//	case(FMS)
//		3'd1: if(addr_camera == 0)  FMS <= 3'd2; 			// chờ dia chi camera = 0
//		3'd2: begin
//					if(addr_camera >= 76799 ) FMS <= 3'd3;	// neu du 320x240 Pixel thì thoat
//					else if(slectMemory && write_ram)		// luu gia tri pixel vao ram
//							begin
//								address_ram <=  addr_camera;
//								data_ram <= DATA_OUT_CAMERA;
////								if((DATA_OUT_CAMERA[15:11] >= 5'd20) && (DATA_OUT_CAMERA[10:5] >= 6'd30) && (DATA_OUT_CAMERA[4:0] < 5'd20) && (DATA_OUT_CAMERA[10:5] > DATA_OUT_CAMERA[15:11]))    
////									data_ram <= 16'hffff;
////								else
////									data_ram <= 16'h0000;
//							end
//					else if(!slectMemory && write_sram)		// luu gia tri pixel vao sram
//							begin	
////								address_sram <=  addr_camera;
////								SDRAM_address<=  addr_camera;
//								address_ram2 <=  addr_camera;
//								data_ram2 <= DATA_OUT_CAMERA;
//								
////								writedata_sram <= DATA_OUT_CAMERA;
////								SDRAM_writedata <= DATA_OUT_CAMERA;
////								if((DATA_OUT_CAMERA[15:11] >= 5'd20) && (DATA_OUT_CAMERA[10:5] >= 6'd30) && (DATA_OUT_CAMERA[4:0] < 5'd20) && (DATA_OUT_CAMERA[10:5] > DATA_OUT_CAMERA[15:11]))    
////									begin
////										writedata_sram <= 16'hffff;
////									end
////								else
////									begin
////										writedata_sram <= 16'h0000;
//////										SDRAM_writedata <= 32'h00000000;
////									end
////								byteenable_sram <= 2'b11;	
//							end
//				end
//		3'd3: if(!frame_done)									// chờ khi hoan thanh 1 khung anh
//					begin
//						led_g0 <= slectMemory;
//						FMS <= 3'd4; 
//						slectMemory <= ~ slectMemory;			// đảo vi tri lưu giá trị pixel
//					end
//
//		3'd4:	FMS <= 3'd1; 										// lặp lại quá trình mới
//				
//	endcase
//		
//	case(slectMemory)				// xet trường hợp để lấy địa chỉ sram hoặc ram tương ứng
//		1'd0: if(!write_ram && (y < 11'd240) && (x < 11'd320))
//					address_ram <=  y*320 + x ;
//		1'd1: if( read_sram && (y < 11'd240) && (x < 11'd320))
//					begin
////						address_sram <= y*320 + x ;
//						address_ram2 <=  y*320 + x ;
////						SDRAM_address<= y*320 + x ;
//					end
//	endcase
//		stt_vga <= ((y < 11'd240) && (x < 11'd320)) ? 3'd1 : 3'd0;
////		if(read_sram && (x < 11'd640) && (y < 11'd240) && (x > 11'd319)) SDRAM_address<= y*320 + x - 320 ;
//end