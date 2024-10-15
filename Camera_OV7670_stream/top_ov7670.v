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
						
						//TEST		- cac chan dung de test chuong trình
						led_test,
						led_g0,
//						sw_data,
//						sw_addr,
//						pin_read_sram,
//						sw_read,
//						sw_write
						);


//************ TOP ****************//						
						
input 			clock_50mhz;			// xung clock vao
input 			pin_reset;				// chan reset

//************ TEST ****************//

output	[18:0]	led_test;			// led test
//input 	[15:0] sw_data;
//input				sw_read;					
//input				sw_write;
//input 	[1:0]	sw_addr;
input  			pin_start;				// nut nhan bat dau chay chuong trinh
//input				pin_read_sram;
output reg 		led_g0 = 0;				// hien thị toc do fbs
	
//************ i2c config **********//	khai báo in-out cac chan I2C
output			pin_scl;
inout				pin_sda;
input				bt_config;			 // key 3

wire		[6:0] o_index;
wire				done_config;

//assign led_test = o_index;

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
//clk_sram - clock_200mhz


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


assign XCLK_CAMERA = clock_24Mhz;

//************ PORT VGA ************************//

output [7:0] pin_r;
output [7:0] pin_g;
output [7:0] pin_b;
output	pin_vga_clock;
output	pin_sync;
output	pin_bank;
output	pin_hs;
output	pin_vs;

reg		[7:0]	iRed;
reg		[7:0]	iGreen;
reg		[7:0]	iBlue;
wire		[18:0]	oAddress;
wire		[10:0]	oCurrent_X;
wire		[10:0]	oCurrent_Y;
wire				oRequest;
reg 				stt_read_sram;
reg				enable_vga;
reg		[15:0] pixel_data;
reg		[2:0]  stt_vga;

//************ PORT RAM ************************//

reg	[16:0]  address_ram;
reg	[15:0]  data_ram;
reg	  write_ram;					//0 doc 1 ghi
wire	[15:0]  readdata_ram;

//************ PLL CREATE CLOCK ****************//


wire 	clock_200Mhz;
wire 	clock_24Mhz;
wire 	clock_25Mhz;
wire 	clock_100Khz;

//wire 	clock_100Mhz;
/* c0 - 200Mhz
	c1 - 24Mhz
	c2 - 48Mhz
	c3 - 100Khz
*/




//reg [3:0] fsmCamera ;
//reg [3:0] fsmVGA ;
//reg	[24:0]	time_delay ;
//reg	[24:0]	time_delay_vga ;
//
////************** function TEST - CHUP ANH LUU ẢNH BẰNG RAM VÀ SRAM **************//
//
//always@(posedge clock_200Mhz )
//begin
//	if(!pin_reset) begin 
//							fsmVGA <= 0;
//							fsmCamera <= 0;
//							time_delay <= 0;
//							time_delay_vga <= 0;
//							write_sram <= 0;
//							byteenable_sram <= 2'b00;
//						end
//	else if(!pin_start ) begin  fsmCamera <= 1; end
//	else if(!pin_read_sram )  begin  fsmVGA <= 1;    end
//
//	case(fsmCamera)
//			4'd1: begin
//						if(time_delay == 25'd25000000)  fsmCamera <= 2;
//						else	time_delay <= time_delay + 1;
//					end
//			4'd2:if(addr_camera == 0) fsmCamera <= 3;
//			4'd3:
//				begin
////					if(addr_camera >= 307199 ) fsmCamera <= 4;   //frame_done	640x480
//					if(addr_camera >= 76799 ) fsmCamera <= 4;   //frame_done   320x240
//					
//					address_sram <=  addr_camera;
//					writedata_sram <= DATA_OUT_CAMERA;
//					write_sram <= 1;
//					byteenable_sram <= 2'b11;
//					led_g0 <= 1;
//					
//					// ram
//					address_ram <=  addr_camera;
//					write_ram <= 1;
//					data_ram <= DATA_OUT_CAMERA;
//					
//				end
//			4'd4: begin 
//						write_sram <= 0;
//						byteenable_sram <= 2'b00;
//						led_g0 <= 0;
//					end
//	endcase
//	
//	case(fsmVGA)
//		4'd1: begin
//					if(time_delay_vga == 25'd25000000) fsmVGA <= 2;
//					else	time_delay_vga <= time_delay_vga + 1;
//				end
//		4'd2: if(oAddress == 0) fsmVGA <= 3;  
//		4'd3:	begin
//					//************** VGA 320x240 *********************//
//					
//					if((oCurrent_Y < 11'd240) && (oCurrent_X < 11'd320)) 
//						begin  
//							address_sram <= oCurrent_Y*320 + oCurrent_X ; //
//							stt_vga <= 1;
//							
//							// ram
//							address_ram <=  oCurrent_Y*320 + oCurrent_X ;
//						end
//					else
//							stt_vga <= 0;   
//						
//					//************** VGA 640x480 *********************//
////						address_sram <= oAddress;   
////						stt_vga <= 1;
//					
//					//************************************************//
//						byteenable_sram <= 2'b11;
//						read_sram <= 1;
//						led_g0 <= 1;
//						
//					// ram
//						
//						write_ram <= 0;
//				end
//	endcase
//end





reg	[2:0] FMS;						// khai bao bien trang thai may
reg	[0:0] slectMemory = 0;		// = 0 sram; = 1 ram

always@(posedge clock_50mhz )
begin
	if(!pin_reset)
		begin
			FMS <= 3'd0;				// reset bien FMS ve 0
		end
		
	write_sram	<= ~ slectMemory;	// gan gia tri cho cac bien 
	read_sram	<= slectMemory;
	write_ram	<= slectMemory;
	
	if(!pin_start)   FMS <= 1; 	// nhan start de bat dau
	
	case(FMS)
		3'd1: if(addr_camera == 0)  FMS <= 3'd2; 			// chờ dia chi camera = 0
		3'd2: begin
					if(addr_camera >= 76799 ) FMS <= 3'd3;	// neu du 320x240 Pixel thì thoat
					else if(slectMemory && write_ram)		// luu gia tri pixel vao ram
							begin
								address_ram <=  addr_camera;
								data_ram <= DATA_OUT_CAMERA;
							end
					else if(!slectMemory && write_sram)		// luu gia tri pixel vao sram
							begin	
								address_sram <=  addr_camera;
								writedata_sram <= DATA_OUT_CAMERA;
								byteenable_sram <= 2'b11;	
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
	

		
	case(slectMemory)				// xet trường hợp để lấy địa chỉ sram hoặc ram tương ứng
	
		1'd0: if(!write_ram && (oCurrent_Y < 11'd240) && (oCurrent_X < 11'd320))
					address_ram <=  oCurrent_Y*320 + oCurrent_X ;
		1'd1: if(read_sram && (oCurrent_Y < 11'd240) && (oCurrent_X < 11'd320))
					address_sram <= oCurrent_Y*320 + oCurrent_X ;
	endcase

		stt_vga <= ((!write_ram || read_sram) && (oCurrent_Y < 11'd240) && (oCurrent_X < 11'd320))?1:0;
		// gán vị trí hiển thị hình ảnh còn lại không hiển thị
end


assign led_test = address_sram;		// gán địa chỉ sram (test)


wire [4:0] CMOS_R;			// khai bao bien luu pixel mau do
wire [5:0] CMOS_G;			// khai bao bien luu pixel mau xanh la
wire [4:0] CMOS_B;			// khai bao bien luu pixel mau xanh duong

//*********** VGA 640x480 ******************
 
//assign CMOS_R = readdata_sram[15:11];									
//assign CMOS_G = readdata_sram[10:5];
//assign CMOS_B = readdata_sram[4:0];

//*********** VGA 320x240 ******************
//
//assign CMOS_R = (stt_vga) ? readdata_sram[15:11]: 5'b00000;  
//assign CMOS_G = (stt_vga) ? readdata_sram[10:5]:  4'b00000;
//assign CMOS_B = (stt_vga) ? readdata_sram[4:0]:  5'b00000;

// ram
//assign CMOS_R = (stt_vga) ? readdata_ram[15:11]: 5'b00000;  
//assign CMOS_G = (stt_vga) ? readdata_ram[10:5]:  4'b00000;
//assign CMOS_B = (stt_vga) ? readdata_ram[4:0]:  5'b00000;

// gán giá trị mau pixel vào các biến với điều khiện tương ứng

assign CMOS_R = stt_vga ? (slectMemory ? readdata_sram[15:11]: readdata_ram[15:11]): 5'b00000;  
assign CMOS_G = stt_vga ? (slectMemory ? readdata_sram[10:5]:  readdata_ram[10:5]):4'b00000;
assign CMOS_B = stt_vga ? (slectMemory ? readdata_sram[4:0]:  	readdata_ram[4:0]):5'b00000;

wire [7:0]	mVGA_R;				//memory output to VGA 8bit only
wire [7:0]	mVGA_G;
wire [7:0]	mVGA_B;

// gán giá trị màu cho các chân màu VGA.
assign mVGA_R = {CMOS_R,{3{1'b0}}};			
assign mVGA_G = {CMOS_G,{2{1'b0}}};
assign mVGA_B = {CMOS_B,{3{1'b0}}};

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
	.c1(clock_24Mhz),
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
				
//assign led_test = (pixel_valid)?DATA_OUT_CAMERA:16'h0000;			
	
// KHAI BÁO MODULE VGA -  HIỂN THỊ HÌNH ẢNH				

VGA_Ctrl	u5(	//	Host Side
						.iRed(mVGA_R),
						.iGreen(mVGA_G),
						.iBlue(mVGA_B),
						.oCurrent_X(oCurrent_X),
						.oCurrent_Y(oCurrent_Y),
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
						
// KHAI BÁO MODULE RAM LUU DỮ LIỆU KHUNG HÌNH

RAM u6(
	.address(address_ram),
	.clock(clock_200Mhz),
	.data(data_ram),
	.wren(write_ram),
	.q(readdata_ram)
	);	


	
						
						
endmodule
