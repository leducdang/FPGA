module hello ( input clk,
					output [7:0] led,
					input key0
					);
					
					
bai1 u0(
		.bt1_export(key0),
		.clk_clk(clk),       //   clk.clk
		.led_export(led),    //   led.export
		.reset_reset_n(1'b1)  // reset.reset_n
	);					
					
endmodule					
