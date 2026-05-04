module calculator_sincos(
									clock_50mhz,
									reset,
									phase,
									cos,
									sin,
									dataout
);

input clock_50mhz;
input reset;
input 	[9:0] phase;   // SW0 -> SW9
output 	[7:0] sin;		// LEDR0 -> LEDR7
output	[7:0]	cos;		//	LEDG0 -> LEDG7
output	[7:0] dataout;

reg 		[7:0]	kc;

always @(posedge clock_50mhz)
begin
	kc <= 10*cos[5:0]/64;

end

assign dataout = kc;


ip_cordic u0(
		.a(phase),      //      a.a
		.areset(reset), // areset.reset
		.c(cos),      //      c.c
		.clk(clock_50mhz),    //    clk.clk
		.s(sin)       //      s.s
	);


endmodule


