module top(	input clock_50mhz,
				input [5:0] sw_r,
				input [5:0] sw_g,
				input [5:0] sw_b,
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

//----------------------------------------------
// Tạo clock 25 MHz từ clock 50 MHz
//----------------------------------------------
always @(posedge clock_50mhz or negedge reset)
begin
    if (!reset)
        clock <= 1'b0;
    else
        clock <= ~clock;
end

//----------------------------------------------
// Đồng bộ dữ liệu màu theo clock VGA (25MHz)
//----------------------------------------------
always @(posedge clock or negedge reset)
begin
    if (!reset) begin
        data_r <= 8'b0;
        data_g <= 8'b0;
        data_b <= 8'b0;
    end
    else begin
        // Mở rộng 6 bit → 8 bit
        data_r <= {sw_r, 2'b11};
        data_g <= {sw_g, 2'b11};
        data_b <= {sw_b, 2'b00};
    end
end

			
			
							
VGA_Ctrl			vga(	//	Host Side
						.iRed(data_r),
						.iGreen(data_g),
						.iBlue(data_b),
						.oCurrent_X(),
						.oCurrent_Y(),
						.oAddress(),
						.oRequest(),
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