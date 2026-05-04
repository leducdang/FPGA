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
	 
	 
//*************** MODE SIDE TONE **************//
//
//message[0]  = 16'h1E00; // reset
//message[1]  = 16'h0C00; // power down control
//message[2]  = 16'h0017; // left line in
//message[3]  = 16'h0217; // right line in
////message[4]  = 16'h0460; // left headphone
////message[5]  = 16'h0660; // right headphone
//message[4]  = 16'h046F; // headphone L (max vừa)
//message[5]  = 16'h066F; // headphone R
//
//message[6]  = 16'h0815; // analog path (old)
//message[7]  = 16'h0A00; // digital path
//message[8]  = 16'h081A; // ✅ Side tone enable
//message[9]  = 16'h101A; // 16kHz
//message[10] = 16'h1201; // activate


//message[0]  = 16'h1E00; // reset
//message[1]  = 16'h0C00; // power
//
//message[2]  = 16'h0017;
//message[3]  = 16'h0217;
//
//message[4]  = 16'h046F;
//message[5]  = 16'h066F;
//
//message[6]  = 16'h081F; // ✅ side tone + boost
//
//message[7]  = 16'h0A00;
//message[9]  = 16'h101A;
//message[10] = 16'h1201;


//
//message[0]  = 16'h1E00; // reset
//message[1]  = 16'h0C00;
//
//message[4]  = 16'h046F;
//message[5]  = 16'h066F;
//
//message[6]  = 16'h081F; // 🔥 side tone + mic boost
//
//message[7]  = 16'h0A00;
//message[9]  = 16'h101A;
//message[10] = 16'h1201;
//
//message[11] = 16'h0000;
//message[12] = 16'h0000;
//message[13] = 16'h0000;
//message[14] = 16'h0000;
//message[15] = 16'h0000;





    message[0]  = 16'h1E00;
    message[1]  = 16'h0C00;
    message[2]  = 16'h0017;
    message[3]  = 16'h0217;
    message[4]  = 16'h046F;
    message[5]  = 16'h066F;
    message[6]  = 16'h0821; // side tone chuẩn hơn
    message[7]  = 16'h0A00;
    message[8]  = 16'h0E02;
    message[9]  = 16'h101A;
    message[10] = 16'h1201;
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
