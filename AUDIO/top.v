module top( clock_50Mhz,
				pin_reset,
				pin_start,
				pin_setup,
				pin_led_ready,
				audio_i2c_clock,
				audio_i2c_data,
				pin_AUD_XCK,
				pin_AUD_BCLK,
				pin_AUD_DACDAT,
				pin_AUD_DACLRCK
				//pin_AUD_ADCDAT,
				//pin_AUD_ADCLRCK
				);
				
input					clock_50Mhz;
input					pin_reset;
input					pin_start;
input					pin_setup;
output				pin_led_ready;
output				audio_i2c_clock;
inout 				audio_i2c_data;
output				pin_AUD_XCK;
output				pin_AUD_BCLK;
output				pin_AUD_DACDAT;
output				pin_AUD_DACLRCK;
//input 				pin_AUD_ADCDAT;
//output				pin_AUD_ADCLRCK;				
				
				
				
				
wire 				clock_12Mhz;				
wire				clock_20Khz;				
wire				clock_i2c_out_pin;			
wire				data_i2c_out_pin;	
reg [23:0]		data_i2c_in;
reg				i2c_run; // = 1 run;
wire				i2c_done; // = 1 done;
wire 				i2c_ACK;
reg 				stt_led;


wire 				audio_daclr;
wire				audio_dac_data;
reg [3:0]		stt_setIC;	
reg [31:0]		audio_data;
wire [15:0]		rom_out;
reg [17:0]		addr_rom;
reg [2:0]		bitprsc;
reg [15:0]		rom_in;
reg	[2:0]		control_stt;
// Cài Đặt IC Audio

always@ (posedge clock_20Khz or negedge pin_reset)
begin
	if(!pin_reset)
		begin
			stt_setIC		<= 0;
			i2c_run 			<= 0;
			stt_led			<= 0;
		end
	else 
	 begin 
			 if(stt_setIC < 4'd10 )
				begin
					case(control_stt):
					3'd0: begin i2c_run <=1; control_stt <= 1; end
					3'd1: begin if(i2c_done) 
									begin  
										control_stt <= 2 
										i2c_run <=0;
									end 
							end
					3'd2: begin stt_setIC <= stt_setIC +1; control_stt <= 0;

		end
							case (stt_setIC)
							4'd0: data_i2c_in <= {8'h34,16'h0E13};
							4'd1:	data_i2c_in <= {8'h34,16'h0579};
							4'd2:	data_i2c_in <= {8'h34,16'h0C07};
							4'd3:	data_i2c_in <= {8'h34,16'h1001};
							4'd4: data_i2c_in <= {8'h34,16'h13FF};
							4'd5: data_i2c_in <= {8'h34,16'h0812};
							4'd6: data_i2c_in <= {8'h34,16'h0A00};
							4'd7: data_i2c_in <= {8'h34,16'h1E00};
							4'd8: begin i2c_run 	<= 0; stt_led<=1; end
						endcase
	
end

always@(posedge clock_12Mhz or negedge pin_start)
begin
	if(!pin_start)
		begin
			addr_rom <= 0;
			bitprsc	<= 0;
			audio_data <= 0;
		end
	else
		begin
			audio_data[15:0] <= rom_out;
			audio_data[31:16] <= rom_out;
				if(audio_daclr == 1)
					begin
						if(bitprsc<5)
							begin
								bitprsc <= bitprsc + 1;
							end
						else
							begin
								bitprsc <=0;
								if(addr_rom < 65544)
									begin
										addr_rom <= addr_rom +1;
									end
								else
									addr_rom <= 0;
							end
					end
		end
end


//audio_data_import  u4(
//	.address(addr_rom),
//	.clock(clock_50Mhz),
//	.q(rom_out)
//	);
audio_data_ram u4(
					.address(addr_rom),
					.clock(clock_50Mhz),
					.data(rom_in),
					.wren(1'b0),
					.q(rom_out)
					);

	
I2C_Controller u2(
	.CLOCK(clock_20Khz),
	.I2C_SCLK(clock_i2c_out_pin),		//I2C CLOCK
 	.I2C_SDAT(data_i2c_out_pin),		//I2C DATA
	.I2C_DATA(data_i2c_in),								//DATA:[SLAVE_ADDR,SUB_ADDR,DATA]
	.GO(i2c_run),      								//GO transfor
	.END(i2c_done),     								//END transfor 
	.W_R(1'b1),     								//W_R
	.ACK(i2c_ACK),      								//ACK
	.RESET(pin_reset)
	//TEST
//	.SD_COUNTER(),
//	.SDO()
);				
							
				
clock_Audio u1(
	.inclk0(clock_50Mhz),
	.c0(clock_12Mhz),
	.c1(clock_20Khz)
	);
	
	
audio_gen  u3( .clock_12Mhz(clock_12Mhz),
					//.audio_bk(),
					.audio_dalr(audio_daclr),
					.audio_datat(audio_dac_data),
					.audio_data_in(audio_data)
);	
	
	

assign 	pin_led_ready = stt_led;
assign 	audio_i2c_clock = clock_i2c_out_pin;
assign 	audio_i2c_data  = data_i2c_out_pin;
assign 	pin_AUD_XCK = clock_12Mhz;
assign 	pin_AUD_BCLK = clock_12Mhz;
assign 	pin_AUD_DACDAT = audio_dac_data;
assign 	pin_AUD_DACLRCK = audio_daclr;
//assign 	pin_AUD_ADCDAT;
//assign 	pin_AUD_ADCLRCK;	
				
endmodule