module top_i2c(
					clock_50mhz,
					pin_sda,
					pin_scl,
					pin_RESET,
					pin_write,
					pin_xclk_camera,
					pin_clock_pclk,
					pin_vs,
					pin_href,
					pin_data,
					pinData_sram,
					pinAddr_sram,
					pinCE_sram,
					pinOE_sram,
					pinWE_sram,
					pinUB_sram,
					pinLB_sram,
					pin_oVGA_R,
					pin_oVGA_G,
					pin_oVGA_B,
					pin_oVGA_HS,
					pin_oVGA_VS,
					pin_oVGA_SYNC,
					pin_oVGA_BLANK,
					pin_oVGA_CLOCK,
					pin_pickup,
					pin_show_image,
					pin_led
					);
					


// port Camera					
input 	pin_clock_pclk;
input 	pin_vs;
input 	pin_href;
input 	[7:0] pin_data;				
output	pin_xclk_camera;
output 	pin_scl;
inout 	pin_sda;

// port SRAM

wire clock_200mhz;
inout	[15:0]	pinData_sram;				//	pin data
output[19:0]	pinAddr_sram;				//	pin dia chi
output 			pinCE_sram;				// pin chọn chip = 0 cho phép chip hoạt động, = 1 ko hoat dong
output			pinOE_sram;				// Output Enable = 0 cho phép xuất data, =1 ko cho phép
output			pinWE_sram;				// Write Enable  = 0 cho phép ghi dữ liệu, = 1 không cho phép
output			pinUB_sram;				// upper byte	  = 0 cho phép ghi 8 bit cao
output			pinLB_sram;				// Lower byte	  = 0 cho phép ghi 8 bit thấp
reg				bit_Read_sram;			// chan dieu khien chuong trinh doc du lieu
reg				bit_Write_sram;			// chan dieu khien chương trinh ghi du lieu
reg [19:0]		addr_sram;		
reg	[15:0]	i_data_sram;
wire	[15:0]	o_data_sram;

// port VGA


output	[7:0]		pin_oVGA_R;
output	[7:0]		pin_oVGA_G;
output	[7:0]		pin_oVGA_B;
output				pin_oVGA_HS;
output				pin_oVGA_VS;
output				pin_oVGA_SYNC;
output				pin_oVGA_BLANK;
output				pin_oVGA_CLOCK;
reg		[7:0]		iRed_vga;
reg		[7:0]		iGreen_vga;
reg		[7:0]		iBlue_vga;
wire		[21:0]	oAddress_vga;
wire		[10:0]	oCurrent_X_vga;
wire		[10:0]	oCurrent_Y_vga;
wire					oRequest_vga;
wire					clock_25mhz;
//	VGA Side






// port main					
input 	pin_RESET;					
input 	clock_50mhz;
input 	pin_write;
input		pin_pickup;
input		pin_show_image;
output 	pin_led;
reg		stt_write_data_sram;

wire		clock_24mhz;
wire 		clock_100Khz;
reg 	[23:0] i_i2c_data;
reg		i_GO;
reg		i_WR;

wire		o_i2c_clk;
wire		o_END;
wire		o_ACK;
wire 		SD_COUNTER;
wire		SD0;

reg 	[5:0]	stt;

reg [15:0] message[250:0];
reg [6:0]  index;


// var Camera
wire 	[15:0] o_data_camera;
wire 	flag_camera;
wire 	[8:0]	o_row_camera;
wire	[9:0]	o_col_camera;

	 initial begin //collection of all adddresses and values to be written in the camera
				//{address,data}
	 message[0]=16'h12_80;  //reset all register to default values
	 message[1]=16'h12_04;  //set output format to RGB
	 message[2]=16'h15_20;  //pclk will not toggle during horizontal blank
	 message[3]=16'h40_d0;	//RGB565
	 
	// These are values scalped from https://github.com/jonlwowski012/OV7670_NEXYS4_Verilog/blob/master/ov7670_registers_verilog.v
    message[4]= 16'h12_04; // COM7,     set RGB color output
    message[5]= 16'h11_80; // CLKRC     internal PLL matches input clock
    message[6]= 16'h0C_00; // COM3,     default settings
    message[7]= 16'h3E_00; // COM14,    no scaling, normal pclock
    message[8]= 16'h04_00; // COM1,     disable CCIR656
    message[9]= 16'h40_d0; //COM15,     RGB565, full output range
    message[10]= 16'h3a_04; //TSLB       set correct output data sequence (magic)
	 message[11]= 16'h14_18; //COM9       MAX AGC value x4 0001_1000
    message[12]= 16'h4F_B3; //MTX1       all of these are magical matrix coefficients
    message[13]= 16'h50_B3; //MTX2
    message[14]= 16'h51_00; //MTX3
    message[15]= 16'h52_3d; //MTX4
    message[16]= 16'h53_A7; //MTX5
    message[17]= 16'h54_E4; //MTX6
    message[18]= 16'h58_9E; //MTXS
    message[19]= 16'h3D_C0; //COM13      sets gamma enable, does not preserve reserved bits, may be wrong?
    message[20]= 16'h17_14; //HSTART     start high 8 bits
    message[21]= 16'h18_02; //HSTOP      stop high 8 bits //these kill the odd colored line
    message[22]= 16'h32_80; //HREF       edge offset
    message[23]= 16'h19_03; //VSTART     start high 8 bits
    message[24]= 16'h1A_7B; //VSTOP      stop high 8 bits
    message[25]= 16'h03_0A; //VREF       vsync edge offset
    message[26]= 16'h0F_41; //COM6       reset timings
    message[27]= 16'h1E_00; //MVFP       disable mirror / flip //might have magic value of 03
    message[28]= 16'h33_0B; //CHLF       //magic value from the internet
    message[29]= 16'h3C_78; //COM12      no HREF when VSYNC low
    message[30]= 16'h69_00; //GFIX       fix gain control
    message[31]= 16'h74_00; //REG74      Digital gain control
    message[32]= 16'hB0_84; //RSVD       magic value from the internet *required* for good color
    message[33]= 16'hB1_0c; //ABLC1
    message[34]= 16'hB2_0e; //RSVD       more magic internet values
    message[35]= 16'hB3_80; //THL_ST
    //begin mystery scaling numbers
    message[36]= 16'h70_3a;
    message[37]= 16'h71_35;
    message[38]= 16'h72_11;
    message[39]= 16'h73_f0;
    message[40]= 16'ha2_02;
    //gamma curve values
    message[41]= 16'h7a_20;
    message[42]= 16'h7b_10;
    message[43]= 16'h7c_1e;
    message[44]= 16'h7d_35;
    message[45]= 16'h7e_5a;
    message[46]= 16'h7f_69;
    message[47]= 16'h80_76;
    message[48]= 16'h81_80;
    message[49]= 16'h82_88;
    message[50]= 16'h83_8f;
    message[51]= 16'h84_96;
    message[52]= 16'h85_a3;
    message[53]= 16'h86_af;
    message[54]= 16'h87_c4;
    message[55]= 16'h88_d7;
    message[56]= 16'h89_e8;
    //AGC and AEC
    message[57]= 16'h13_e0; //COM8, disable AGC / AEC
    message[58]= 16'h00_00; //set gain reg to 0 for AGC
    message[59]= 16'h10_00; //set ARCJ reg to 0
    message[60]= 16'h0d_40; //magic reserved bit for COM4
    message[61]= 16'h14_18; //COM9, 4x gain + magic bit
    message[62]= 16'ha5_05; // BD50MAX
    message[63]= 16'hab_07; //DB60MAX
    message[64]= 16'h24_95; //AGC upper limit
    message[65]= 16'h25_33; //AGC lower limit
    message[66]= 16'h26_e3; //AGC/AEC fast mode op region
    message[67]= 16'h9f_78; //HAECC1
    message[68]= 16'ha0_68; //HAECC2
    message[69]= 16'ha1_03; //magic
    message[70]= 16'ha6_d8; //HAECC3
    message[71]= 16'ha7_d8; //HAECC4
    message[72]= 16'ha8_f0; //HAECC5
    message[73]= 16'ha9_90; //HAECC6
    message[74]= 16'haa_94; //HAECC7
    message[75]= 16'h13_e5; //COM8, enable AGC / AEC
	 message[76]= 16'h1E_23; //Mirror Image
	 message[77]= 16'h69_06; //gain of RGB(manually adjusted)
  end


always@(posedge clock_100Khz or negedge pin_RESET)
begin
	//i_i2c_data <= {8'h42,8'h12,8'h80 };
	if(!pin_RESET)
		begin
			i_GO <= 0;
			i_WR <= 0;
			stt  <= 6'b111111;
			index <= 1;
		end
	else if(!pin_write && o_END == 0 )
			begin
				//i_GO 	<= 1;
				stt	<= 0;
			end
			else 
				case(stt)
					6'd0: begin i_GO <= 0; stt <= 1; end
					6'd1:	begin i_GO <= 1; i_i2c_data <= {8'h42,8'h12,8'h80 }; stt <= 2; end
					6'd2: if(o_END) begin i_GO <= 0; stt <= 3; end
					6'd3:	begin i_GO <= 1; i_i2c_data <= {8'h42,message[index]}; stt <= 4; end
					6'd4: stt <= 5;
					6'd5:	if(o_END) begin i_GO <= 0; stt <= 6; end
					6'd6: if(index < 78)
								begin
									index <= index + 1;
									stt <= 3;
								end
							else
									stt <= 7;
				endcase				
end


always@(posedge clock_200mhz or negedge pin_RESET)
begin
	if(!pin_RESET)begin  bit_Write_sram <= 0; bit_Read_sram <= 0; end
	else
		begin
			if(pin_pickup)
				begin
					bit_Write_sram <= 1;
					addr_sram <= o_row_camera*480 + o_row_camera;
					i_data_sram <= o_data_camera;
				end
			else
				begin
					bit_Write_sram <= 0;
				end
				
			if(pin_show_image)
				begin
					bit_Read_sram <= 1;
					addr_sram <= oAddress_vga;
					iRed_vga  <= {o_data_sram[15:11],3'b111};
					iGreen_vga<= {o_data_sram[10:5],2'b11};
					iBlue_vga <= {o_data_sram[4:0],3'b111};
					
				end
			else
				begin
					bit_Read_sram <= 0;
					iRed_vga  <= 8'h00;
					iGreen_vga<= 8'h00;
					iBlue_vga <= 8'h00;
				end
		end
	
end



					
i2c 	u1(
			 .CLOCK(clock_100Khz),
			 .I2C_SCLK(o_i2c_clk),		//I2C CLOCK
			 .I2C_SDAT(pin_sda),		//I2C DATA
			 .I2C_DATA(i_i2c_data),		//DATA:[SLAVE_ADDR,SUB_ADDR,DATA]
			 .GO(i_GO),      		//GO transfor
			 .END(o_END),    	    //END transfor 
			 .W_R(i_WR),     		//W_R
			 .ACK(o_ACK),     	    //ACK
			 .RESET(pin_RESET),
			 //TEST
			 .SD_COUNTER(SD_COUNTER),
			 .SDO(SD0)
		   	);			
		
PLL_I2C u2(
				.inclk0(clock_50mhz),
				.c0(clock_100Khz),
				.c1(clock_24mhz),
				.c2(clock_200mhz),
				.c3(clock_25mhz)
				);
	

camera_read_data	u3(	.clock_pclk(pin_clock_pclk),
								.vs(pin_vs),
								.href(pin_href),
								.data(pin_data),
								.o_data(o_data_camera),
								.flag(flag_camera),
								.pin_reset(pin_RESET),
								.o_row(o_row_camera),
								.o_col(o_col_camera)
								);
topSRAM	u4(	.clock_200mhz(clock_200mhz), 		
					.pinData(pinData_sram),
					.pinAddr(pinAddr_sram),
					.pinCE(pinCE_sram),
					.pinOE(pinOE_sram),
					.pinWE(pinWE_sram),
					.pinUB(pinUB_sram),
					.pinLB(pinLB_sram),
					.bit_Read(bit_Read_sram),
					.bit_Write(bit_Write_sram),
					.pinReset(pin_RESET),
					.addr(addr_sram),
					.i_data(i_data_sram),
					.o_data(o_data_sram)
					);
					
VGA_Ctrl		u5(	//	Host Side
						.iRed(iRed_vga),
						.iGreen(iGreen_vga),
						.iBlue(iBlue_vga),
						.oCurrent_X(oCurrent_X_vga),
						.oCurrent_Y(oCurrent_Y_vga),
						.oAddress(oAddress_vga),
						.oRequest(oRequest_vga),
						//	VGA Side
						.oVGA_R(pin_oVGA_R),
						.oVGA_G(pin_oVGA_G),
						.oVGA_B(pin_oVGA_B),
						.oVGA_HS(pin_oVGA_HS),
						.oVGA_VS(pin_oVGA_VS),
						.oVGA_SYNC(pin_oVGA_SYNC),
						.oVGA_BLANK(pin_oVGA_BLANK),
						.oVGA_CLOCK(pin_oVGA_CLOCK),
						//	Control Signal
						.iCLK(clock_25mhz),
						.iRST_N(pin_RESET)	
						);
	
	
	
assign 	pin_scl = 	o_i2c_clk;	
assign	pin_xclk_camera = clock_24mhz;
assign 	pin_led = (o_row_camera == 9'd470 && o_col_camera == 10'd639)?1:0;
					
endmodule