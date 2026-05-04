
module ip_cordic (
	clk,
	areset,
	a,
	c,
	s);	

	input		clk;
	input		areset;
	input	[9:0]	a;
	output	[7:0]	c;
	output	[7:0]	s;
endmodule
