module config_camera(
							clock_50mhz,
							clock_100khz,
							sda,
							scl,
							reset,
							enable_config,
							done_config,
							//test
							o_index
							);
							
//************* PORT *************//							
							
input clock_50mhz;
input clock_100khz;
output		scl;
inout			sda;
input 		reset;
input			enable_config;
output reg	done_config;
output	[7:0] o_index;

//************* VAR **************//

reg [4:0]	stt;
reg [6:0]  index;
reg		i_GO;
//reg		i_WR;
reg [23:0]	i_i2c_data;
wire			o_END;
wire			ACK;
wire			SD_COUNTER;
wire			SDO;
reg [15:0] cam_cfg[100:0];
wire			o_i2c_clk;

//************* data Config ******//

initial begin //collection of all adddresses and values to be written in the camera
				//{address,data}
	 
	 
//*********************************************************************************//
	 cam_cfg[0]  <=16'h12_80; //reset
    cam_cfg[1]  <=16'hFF_F0; //delay
    cam_cfg[2]  <=16'h12_14;//04; 14 // COM7,     set RGB color output ** 04: 640X480 **14: 320X240
    cam_cfg[3]  <=16'h11_80; // CLKRC     internal PLL matches input clock
    cam_cfg[4]  <=16'h0C_00; // COM3,     default settings
    cam_cfg[5]  <=16'h3E_01; // COM14,   //01 -div2 no scaling, normal pclock ** 00: 640X480 **01: 320X240
    cam_cfg[6]  <=16'h04_00; // COM1,     disable CCIR656
    cam_cfg[7]  <=16'h40_d0; //COM15,     RGB565, full output range
    cam_cfg[8]  <=16'h3a_04; //TSLB       set correct output data sequence (magic)
    cam_cfg[9]  <=16'h14_18; //COM9       MAX AGC value x4
	 
	 //----------------------
	cam_cfg[10] <= 16'h4F_80;
	cam_cfg[11] <= 16'h50_80;
	cam_cfg[12] <= 16'h51_00;
	cam_cfg[13] <= 16'h52_22;
	cam_cfg[14] <= 16'h53_5E;
	cam_cfg[15] <= 16'h54_80;
	cam_cfg[16] <= 16'h58_9E;

	 //-----------------------------

    cam_cfg[17] <=16'h3D_C0; //COM13      sets gamma enable, does not preserve reserved bits, may be wrong?
    cam_cfg[18] <=16'h17_14; //HSTART     start high 8 bits
    cam_cfg[19] <=16'h18_02; //HSTOP      stop high 8 bits //these kill the odd colored line
	 cam_cfg[20] <=16'h32_80; //HREF       edge offset
    cam_cfg[21] <=16'h19_03; //VSTART     start high 8 bits
    cam_cfg[22] <=16'h1A_7B; //VSTOP      stop high 8 bits
    cam_cfg[23] <=16'h03_0A; //VREF       vsync edge offset
    cam_cfg[24] <=16'h0F_41; //COM6       reset timings
    cam_cfg[25] <=16'h1E_30; //MVFP       disable mirror / flip //might have magic value of 03
    cam_cfg[26] <=16'h33_0B; //CHLF       //magic value from the internet
    cam_cfg[27] <=16'h3C_78; //COM12      no HREF when VSYNC low
    cam_cfg[28] <=16'h69_00; //GFIX       fix gain control
    cam_cfg[29] <=16'h74_00; //REG74      Digital gain control
    cam_cfg[30] <=16'hB0_84; //RSVD       magic value from the internet *required* for good color
    cam_cfg[31] <=16'hB1_0c; //ABLC1
    cam_cfg[32] <=16'hB2_0e; //RSVD       more magic internet values
    cam_cfg[33] <=16'hB3_80; //THL_ST
    //begin mystery scaling numbers
    cam_cfg[34] <=16'h70_3a;
    cam_cfg[35] <=16'h71_35;
    cam_cfg[36] <=16'h72_11;
    cam_cfg[37] <=16'h73_f0;
    cam_cfg[38] <=16'ha2_02;
	 
    //gamma curve values
    cam_cfg[39] <=16'h7a_20;
    cam_cfg[40] <=16'h7b_10;
    cam_cfg[41] <=16'h7c_1e;
    cam_cfg[42] <=16'h7d_35;
    cam_cfg[43] <=16'h7e_5a;
    cam_cfg[44] <=16'h7f_69;
    cam_cfg[45] <=16'h80_76;
    cam_cfg[46] <=16'h81_80;
    cam_cfg[47] <=16'h82_88;
    cam_cfg[48] <=16'h83_8f;
    cam_cfg[49] <=16'h84_96;
    cam_cfg[50] <=16'h85_a3;
    cam_cfg[51] <=16'h86_af;
    cam_cfg[52] <=16'h87_c4;
    cam_cfg[53] <=16'h88_d7;
    cam_cfg[54] <=16'h89_e8;

    //AGC and AEC
    cam_cfg[55] <=16'h13_e0; //COM8, disable AGC / AEC
    cam_cfg[56] <=16'h00_00; //set gain reg to 0 for AGC
    cam_cfg[57] <=16'h10_00; //set ARCJ reg to 0
    cam_cfg[58] <=16'h0d_40; //magic reserved bit for COM4
    cam_cfg[59] <=16'h14_18; //COM9, 4x gain + magic bit
    cam_cfg[60] <=16'ha5_05; // BD50MAX
    cam_cfg[61] <=16'hab_07; //DB60MAX
    cam_cfg[62] <=16'h24_95; //AGC upper limit
    cam_cfg[63] <=16'h25_33; //AGC lower limit
    cam_cfg[64] <=16'h26_e3; //AGC/AEC fast mode op region
    cam_cfg[65] <=16'h9f_78; //HAECC1
    cam_cfg[66] <=16'ha0_68; //HAECC2
    cam_cfg[67] <=16'ha1_03; //magic
    cam_cfg[68] <=16'ha6_d8; //HAECC3
    cam_cfg[69] <=16'ha7_d8; //HAECC4
    cam_cfg[70] <=16'ha8_f0; //HAECC5
    cam_cfg[71] <=16'ha9_90; //HAECC6
    cam_cfg[72] <=16'haa_94; //HAECC7
	 //73: cam_cfg[0] 16'h13_e5; //COM8, enable AGC / AEC
    cam_cfg[73] <=16'h13_e7; //COM8, enable AGC / AEC
	 
	 //experimental
	 cam_cfg[74] <=16'h6b_00;
	 
//**********************************************************************************//	 
	
  end

  
  
  
  
  
always@(posedge clock_100khz or negedge reset)
begin
	//i_i2c_data <= {8'h42,8'h12,8'h80 };
	if(!reset)
		begin
			i_GO <= 0;
			//i_WR <= 0;
			stt  <= 5'b11111;
			index <= 0;
			done_config <= 0;
		end
	else if(!enable_config && o_END == 0 )
			begin
				//i_GO 	<= 1;
				stt	<= 0;
			end
	else 
		case(stt)
					5'd0: begin i_GO <= 0; 
									stt <= 1; 
								end

					5'd1: if(!o_END)	stt <= 2; 
					5'd2:	begin 
									i_GO <= 1; 
									i_i2c_data <= {8'h42,cam_cfg[index]}; 
									stt <= 3; 
								end
					5'd3: stt <= 4;
					5'd4:	if(o_END) 
							begin 
									i_GO <= 0; 
									stt <= 5;
									index <=  index + 7'd1;	
								end
					5'd5: begin
								if(index > 8'd74)
									begin
										stt <= 6;
										done_config <= 1;
									end
								else
									begin
										stt <= 0;
									end
							end
				
				endcase				
end


i2c config_camera(
			 .CLOCK(clock_100khz),
			 .I2C_SCLK(o_i2c_clk),		//I2C CLOCK
			 .I2C_SDAT(sda),		//I2C DATA
			 .I2C_DATA(i_i2c_data),		//DATA:[SLAVE_ADDR,SUB_ADDR,DATA]
			 .GO(i_GO),      		//GO transfor
			 .END(o_END),    	    //END transfor 
			 .W_R(),     		//W_R
			 .ACK(ACK),     	    //ACK
			 .RESET(reset),
			 //TEST
			 .SD_COUNTER(SD_COUNTER),
			 .SDO(SDO)
		   	);

assign 	scl = 	o_i2c_clk;	
assign o_index = index;
endmodule
