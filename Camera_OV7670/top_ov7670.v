module top_ov7670(
						clock_50mhz,
						
						// I2C
						pin_scl,
						pin_sda,
						pin_reset,	  // key 0
						bt_config,    // key 3
						
						// SRAM
						SRAM_DQ,       // external_interface.DQ
						SRAM_ADDR,     //                   .ADDR
						SRAM_LB_N,     //                   .LB_N
						SRAM_UB_N,     //                   .UB_N
						SRAM_CE_N,     //                   .CE_N
						SRAM_OE_N,     //                   .OE_N
						SRAM_WE_N,     //                   .WE_N
						
						
						//CAMERA
						
						XCLK_CAMERA,
						PCLK_CAMERA,
						VSYNC_CAMERA,
						HREF_CAMERA,
						DATA_CAMERA,
				
						// PORT VGA
						
						pin_r,
						pin_g,
						pin_b,
						pin_vga_clock,
						pin_sync,
						pin_bank,
						pin_hs,
						pin_vs,
						
						//TEST
						led_test,
						//sw_data,
						sw_addr,
						pin_write_sram,
						pin_read_sram,
						led_g0,
						sw_read,
						sw_write
						);


//************ TOP ****************//						
						
input 			clock_50mhz;
input 			pin_reset;

//************ TEST ****************//

output	[18:0]	led_test;
//input 	[15:0] sw_data;
input				sw_read;
input				sw_write;
input 	[1:0]	sw_addr;
input  			pin_write_sram;
input				pin_read_sram;
output reg 		led_g0 = 0;

//************ i2c config **********//
output			pin_scl;
inout				pin_sda;
input				bt_config;			 // key 3

wire		[6:0] o_index;
wire				done_config;

//assign led_test = o_index;

//************ SRAM ****************//

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


//************ READ DATA CAMERA ****************//

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
reg [3:0] fsmCamera ;
reg [3:0] fsmVGA ;
reg	[24:0]	time_delay ;
reg	[24:0]	time_delay_vga ;

//************** function TEST **************//

always@(posedge clock_200Mhz )
begin
	if(!pin_reset) begin 
							fsmVGA <= 0;
							fsmCamera <= 0;
							time_delay <= 0;
							time_delay_vga <= 0;
							write_sram <= 0;
							byteenable_sram <= 2'b00;
						end
	else if(!pin_write_sram ) begin  fsmCamera <= 1; end
	else if(!pin_read_sram )  begin  fsmVGA <= 1;    end

	case(fsmCamera)
			4'd1: begin
						if(time_delay == 25'd25000000)  fsmCamera <= 2;
						else	time_delay <= time_delay + 1;
					end
			4'd2:if(addr_camera == 0) fsmCamera <= 3;
			4'd3:
				begin
					if(addr_camera >= 307199 ) fsmCamera <= 4;   //frame_done	640x480
					//if(addr_camera >= 76799 ) fsmCamera <= 4;   //frame_done   320x240
					
					address_sram <=  addr_camera;
					writedata_sram <= DATA_OUT_CAMERA;
					write_sram <= 1;
					byteenable_sram <= 2'b11;
					led_g0 <= 1;
				end
			4'd4: begin 
						write_sram <= 0;
						byteenable_sram <= 2'b00;
						led_g0 <= 0;
					end
	endcase
	
	case(fsmVGA)
		4'd1: begin
					if(time_delay_vga == 25'd25000000) fsmVGA <= 2;
					else	time_delay_vga <= time_delay_vga + 1;
				end
		4'd2: if(oAddress == 0) fsmVGA <= 3;  
		4'd3:	begin
					//************** VGA 320x240 *********************//
					
//					if((oCurrent_Y < 11'd240) && (oCurrent_X < 11'd320)) 
//						begin  
//							address_sram <= oCurrent_Y*320 + oCurrent_X ; //
//							stt_vga <= 1;
//						end
//					else
//							stt_vga <= 0;   
						
					//************** VGA 640x480 *********************//
						address_sram <= oAddress;   
						stt_vga <= 1;
					
					//************************************************//
						byteenable_sram <= 2'b11;
						read_sram <= 1;
						led_g0 <= 1;
				end
	endcase
end

assign led_test = address_sram;


wire [4:0] CMOS_R;
wire [5:0] CMOS_G;
wire [4:0] CMOS_B;

//*********** VGA 640x480 ******************
 
//assign CMOS_R = readdata_sram[15:11];									
//assign CMOS_G = readdata_sram[10:5];
//assign CMOS_B = readdata_sram[4:0];

//*********** VGA 320x240 ******************

assign CMOS_R = (stt_vga) ? readdata_sram[15:11]: 5'b00000;  
assign CMOS_G = (stt_vga) ? readdata_sram[10:5]:  4'b00000;
assign CMOS_B = (stt_vga) ? readdata_sram[4:0]:  5'b00000;

wire [7:0]	mVGA_R;				//memory output to VGA 8bit only
wire [7:0]	mVGA_G;
wire [7:0]	mVGA_B;

assign mVGA_R = {CMOS_R,{3{1'b0}}};
assign mVGA_G = {CMOS_G,{2{1'b0}}};
assign mVGA_B = {CMOS_B,{3{1'b0}}};


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
							
	
PLL u1(
	.inclk0(clock_50mhz),
	.c0(clock_200Mhz),
	.c1(clock_24Mhz),
	.c2(clock_25Mhz),
	.c3(clock_100Khz)
	);
	



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

endmodule
