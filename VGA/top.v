module top(	input clock_50mhz,
				input [7:0] sw_r,
				input [7:0] sw_g,
				output [7:0] pin_r,
				output [7:0] pin_g,
				output [7:0] pin_b,
				output	pin_vga_clock,
				output	pin_sync,
				output	pin_bank,
				output	pin_hs,
				output	pin_vs,
				//output	clock_25mhz,
				input reset
				);
			
reg [7:0] data_r;
reg [7:0] data_g;
reg [7:0] data_b;
reg	clock;

always@(posedge clock_50mhz)
begin
		data_r <= sw_r;
		data_g <= sw_g;
		data_b <= 8'hff;
		clock <= ~clock;
end			
			
			
			
			

//assign clock_25mhz = clock;


//vga_controler vga_test( .clock_50mhz(clock_50mhz),
//								.vga_r(data_r),
//								.vga_g(data_g),
//								.vga_b(data_b),
//								.pin_rgb_r(pin_r),
//								.pin_rgb_g(pin_g),
//								.pin_rgb_b(pin_b),
//								.vga_clk(pin_vga_clock),
//								.vga_sync(pin_sync),
//								.vga_blank(pin_bank),
//								.vga_vs(pin_vs),
//								.vga_hs(pin_hs),
//								.reset(reset)
//							);
							
VGA_Ctrl			vga(	//	Host Side
						.iRed(data_r),
						.iGreen(data_g),
						.iBlue(data_b),
//						oCurrent_X,
//						oCurrent_Y,
//						oAddress,
//						oRequest,
						//	VGA Side
						.oVGA_R(pin_r),
						.oVGA_G(pin_g),
						.oVGA_B(pin_b),
						.oVGA_HS(pin_hs),
						.oVGA_VS(pin_vs),
						.oVGA_SYNC(pin_sync),
						.oVGA_BLANK(pin_bank),
						.oVGA_CLOCK(pin_vga_clock),
						//	Control Signal
						.iCLK(clock),
						.iRST_N(reset)	);

endmodule