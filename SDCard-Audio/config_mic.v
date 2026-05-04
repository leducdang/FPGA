module config_mic(
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
reg [6:0]  	index;
reg			i_GO;
reg [23:0]	i_i2c_data;
wire			o_END;
wire			ACK;
wire			SD_COUNTER;
wire			SDO;
reg [15:0] 	message[15:0];
wire			o_i2c_clk;

//************* data Config ******//

initial begin //collection of all adddresses and values to be written in the microphone
				//{address,data}
	 
	 
//*********************************************************************************//

//message[0] = 16'h1E00; // (15) RESET codec
//message[1] = 16'h0C00; // (06) Power up:
//                       // ADC ON, MIC ON, DAC OFF, LINEIN OFF
//message[2] = 16'h0017; // (00) Left Mic PGA gain +20dB
//message[3] = 16'h0217; // (01) Right Mic PGA gain +20dB
//message[4] = 16'h0815; // (04) Analog audio path:
//                       // MICSEL=1  (MIC)
//                       // MICBOOST=1 (+20dB)
//                       // ADCSEL=1  (MIC → ADC)
//                       // BYPASS=0
//message[5] = 16'h0A00; // (05) Digital audio path:
//                       // No mute, no de-emphasis
//message[6] = 16'h0E23; // (07) Digital audio interface:
//                       // I2S
//                       // 16-bit
//                       // SLAVE mode
//message[7] = 16'h1000; // (08) Sampling control:
//                       // USB MODE
//                       // 48 kHz
//                       // BOSR=0
//message[8] = 16'h1201; // (09) ACTIVE = 1  (BẮT BUỘC CUỐI)


message[0]  = 16'h1E00;
message[1]  = 16'h0C00;
message[2]  = 16'h0017;
message[3]  = 16'h0217;
message[4]  = 16'h0460;
message[5]  = 16'h0660;
message[6]  = 16'h0815;
message[7]  = 16'h0A00;

/*
message[8]  = 16'h0E02; // I2S slave 16bit
//message[9]  = 16'h1001; // USB mode 48kHz							16'h1000 12.288Mhz, 16'h1001 12Mhz
message[9]  = 16'h101A; // USB mode 16kHz ✅
message[10] = 16'h1201;
*/

message[8]  = 16'h0E02; // R7: I2S, slave, 16-bit
message[9]  = 16'h1019; // R8: USB mode, ADC/DAC ~8kHz
message[10] = 16'h1201; // R9: Active


    message[11] = 16'h0000;
    message[12] = 16'h0000;
    message[13] = 16'h0000;
    message[14] = 16'h0000;
    message[15] = 16'h0000;

//**********************************************************************************//	 
  end

always@(posedge clock_100khz or negedge reset)
begin
	//i_i2c_data <= {8'h42,8'h12,8'h80 };
	if(!reset)
		begin
			i_GO 	<= 0;
			stt  	<= 5'b11111;
			index <= 0;
			done_config <= 0;
		end
	else if(!enable_config)
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
									i_i2c_data <= {8'h34,message[index]}; 
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
								if(index > 7'd10)
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


i2c config_mic(
			 .CLOCK(clock_100khz),
			 .I2C_SCLK(o_i2c_clk),	//I2C CLOCK
			 .I2C_SDAT(sda),			//I2C DATA
			 .I2C_DATA(i_i2c_data),	//DATA:[SLAVE_ADDR,SUB_ADDR,DATA]
			 .GO(i_GO),      			//GO transfor
			 .END(o_END),    	    	//END transfor 
			 .W_R(),     				//W_R
			 .ACK(ACK),     	    	//ACK
			 .RESET(reset),
			 //TEST
			 .SD_COUNTER(SD_COUNTER),
			 .SDO(SDO)
		   	);

assign 	scl = 	o_i2c_clk;	
assign o_index = index;
endmodule
