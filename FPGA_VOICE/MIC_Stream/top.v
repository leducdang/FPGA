/*

ĐẦU TIÊN NHẤN KEY1 RESET
- NHÁN KEY3 ĐẺ CONFIG
*/


module top(
				input 	clk_50mhz,
				input 	reset,
				input 	key3,				// config i2c
				inout 	I2C_SDAT,
				output 	I2C_SCLK,
				output	led_0,
				output 	MCK,
				output 	BCLK,
				output 	LRCK
);

wire		clk_12mhz;
wire 		clk_512khz;
wire		clk_100khz;
wire		clk_16khz;
wire		config_done;

assign MCK = clk_12mhz;
assign BCLK = clk_512khz;
assign LRCK = clk_16khz;
assign led_0 = config_done;

PLL u1(
	.inclk0(clk_50mhz),
	.c0(clk_12mhz),
	.c1(clk_512khz),
	.c2(clk_100khz)
	);
	
gen_lrclk_16k u2(
	 .BCLK(clk_512khz),    
	 .reset(reset),
	 .LRCLK(clk_16khz)       	
);

config_mic u3(
		.clock_50mhz(clk_50mhz),
		.clock_100khz(clk_100khz),
		.sda(I2C_SDAT),
		.scl(I2C_SCLK),
		.reset(reset),
		.enable_config(key3),
		.done_config(config_done),
		.o_index()
		);

endmodule


