module top(	input clock_50mhz,
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
wire	[10:0] Current_X;
wire	[10:0] Current_Y;
reg  [21:0] Address_ram;
wire  [21:0] Address;
wire	Request;

// ram
reg	[23:0] data_in;
wire	[23:0] data_out;
wire 	clock_100mhz;
wire 	clock_25mhz;

// DOC DU LIEU TU IP RAM VA GUI GIA TRI MAU SAC RA CONG VGA.
always@(posedge clock_100mhz)
begin
		if(Request)
		begin
			//if((Current_X > 11'd112) && (Current_Y < 11'd240) && (Current_X < 11'd320))
			if((Current_Y < 11'd240) && (Current_X < 11'd320))
				begin
					Address_ram <= Current_Y*320 + Current_X ;      //( 112 = H_FRONT + H_SYNC )
					data_b <= data_out[7:0];
					data_g <= data_out[15:8];
					data_r <= data_out[23:16];
				end
			else
				begin
					data_r <= 8'h00;
					data_g <= 8'h00;
					data_b <= 8'h00;
				end
		end
end			


// Tao xung 25Mhz cap cho bo VGA
always@(posedge clock_50mhz or negedge reset)
	begin 
		if(!reset) clock <= 0;
			else
				clock <= ~clock;
		
			end	



pll1 u2(
	.inclk0(clock_50mhz),
	.c0(clock_100mhz),
	.c1(clock_25mhz)
	);
 
// RAM 1
		
ram1 U1(
	.address(Address_ram),
	.clock(clock_100mhz),
	.data(data_in),
	.wren(1'b0),
	.q(data_out)
	);			
			
			

VGA_Ctrl			vga(	//	Host Side
						.iRed(data_r),
						.iGreen(data_g),
						.iBlue(data_b),
						.oCurrent_X(Current_X),
						.oCurrent_Y(Current_Y),
						.oAddress(Address),
						.oRequest(Request),
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
						.iCLK(clock_25mhz),
						.iRST_N(reset)	);

endmodule