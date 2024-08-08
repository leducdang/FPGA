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
reg [15:0] message[100:0];
wire			o_i2c_clk;

//************* data Config ******//

initial begin //collection of all adddresses and values to be written in the camera
				//{address,data}
	 
	 
//*********************************************************************************//
	 message[0]  <=16'h12_80; //reset
    message[1]  <=16'hFF_F0; //delay
    message[2]  <=16'h12_04;//04; 14 // COM7,     set RGB color output
    message[3]  <=16'h11_80; // CLKRC     internal PLL matches input clock
    message[4]  <=16'h0C_00; // COM3,     default settings
    message[5]  <=16'h3E_00; // COM14,   //01 -div2 no scaling, normal pclock
    message[6]  <=16'h04_00; // COM1,     disable CCIR656
    message[7]  <=16'h40_d0; //COM15,     RGB565, full output range
    message[8]  <=16'h3a_04; //TSLB       set correct output data sequence (magic)
    message[9]  <=16'h14_18; //COM9       MAX AGC value x4
    message[10] <=16'h4F_B3; //MTX1       all of these are magical matrix coefficients
    message[11] <=16'h50_B3; //MTX2
    message[12] <=16'h51_00; //MTX3
    message[13] <=16'h52_3d; //MTX4
    message[14] <=16'h53_A7; //MTX5
    message[15] <=16'h54_E4; //MTX6
    message[16] <=16'h58_9E; //MTXS
    message[17] <=16'h3D_C0; //COM13      sets gamma enable, does not preserve reserved bits, may be wrong?
    message[18] <=16'h17_14; //HSTART     start high 8 bits
    message[19] <=16'h18_02; //HSTOP      stop high 8 bits //these kill the odd colored line
	 message[20] <=16'h32_80; //HREF       edge offset
    message[21] <=16'h19_03; //VSTART     start high 8 bits
    message[22] <=16'h1A_7B; //VSTOP      stop high 8 bits
    message[23] <=16'h03_0A; //VREF       vsync edge offset
    message[24] <=16'h0F_41; //COM6       reset timings
    message[25] <=16'h1E_30; //MVFP       disable mirror / flip //might have magic value of 03
    message[26] <=16'h33_0B; //CHLF       //magic value from the internet
    message[27] <=16'h3C_78; //COM12      no HREF when VSYNC low
    message[28] <=16'h69_00; //GFIX       fix gain control
    message[29] <=16'h74_00; //REG74      Digital gain control
    message[30] <=16'hB0_84; //RSVD       magic value from the internet *required* for good color
    message[31] <=16'hB1_0c; //ABLC1
    message[32] <=16'hB2_0e; //RSVD       more magic internet values
    message[33] <=16'hB3_80; //THL_ST
    //begin mystery scaling numbers
    message[34] <=16'h70_3a;
    message[35] <=16'h71_35;
    message[36] <=16'h72_11;
    message[37] <=16'h73_f0;
    message[38] <=16'ha2_02;
    //gamma curve values
    message[39] <=16'h7a_20;
    message[40] <=16'h7b_10;
    message[41] <=16'h7c_1e;
    message[42] <=16'h7d_35;
    message[43] <=16'h7e_5a;
    message[44] <=16'h7f_69;
    message[45] <=16'h80_76;
    message[46] <=16'h81_80;
    message[47] <=16'h82_88;
    message[48] <=16'h83_8f;
    message[49] <=16'h84_96;
    message[50] <=16'h85_a3;
    message[51] <=16'h86_af;
    message[52] <=16'h87_c4;
    message[53] <=16'h88_d7;
    message[54] <=16'h89_e8;
    //AGC and AEC
    message[55] <=16'h13_e0; //COM8, disable AGC / AEC
    message[56] <=16'h00_00; //set gain reg to 0 for AGC
    message[57] <=16'h10_00; //set ARCJ reg to 0
    message[58] <=16'h0d_40; //magic reserved bit for COM4
    message[59] <=16'h14_18; //COM9, 4x gain + magic bit
    message[60] <=16'ha5_05; // BD50MAX
    message[61] <=16'hab_07; //DB60MAX
    message[62] <=16'h24_95; //AGC upper limit
    message[63] <=16'h25_33; //AGC lower limit
    message[64] <=16'h26_e3; //AGC/AEC fast mode op region
    message[65] <=16'h9f_78; //HAECC1
    message[66] <=16'ha0_68; //HAECC2
    message[67] <=16'ha1_03; //magic
    message[68] <=16'ha6_d8; //HAECC3
    message[69] <=16'ha7_d8; //HAECC4
    message[70] <=16'ha8_f0; //HAECC5
    message[71] <=16'ha9_90; //HAECC6
    message[72] <=16'haa_94; //HAECC7
	 //73: message[0] 16'h13_e5; //COM8, enable AGC / AEC
    message[73] <=16'h13_e7; //COM8, enable AGC / AEC
	 
	 //experimental
	 message[74] <=16'h6b_00;
	 
//**********************************************************************************//	 
	 
	 
  end

  
  
  
  
  
always@(posedge clock_100khz or negedge reset)
begin
	//i_i2c_data <= {8'h42,8'h12,8'h80 };
	if(!reset)
		begin
			i_GO <= 0;
			//i_WR <= 0;
			stt  <= 5'b111111;
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
									i_i2c_data <= {8'h42,message[index]}; 
									stt <= 3; 
								end
					5'd3: stt <= 4;
					5'd4:	if(o_END) 
							begin 
									i_GO <= 0; 
									stt <= 5;
									index <=  index + 1;	
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