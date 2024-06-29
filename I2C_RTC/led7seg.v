`timescale 1ns / 1ps
module led7seg(input clk, 
				 input  [7:0] data_in,
				 output [0:6] led1, 
				 output [0:6] led2);
				 
reg	[0:6] HEX1	;
reg	[0:6] HEX2	;		 

always @(posedge clk) begin
			
			// so sánh voi bien led de hien thi ra led 7 doan
			case (data_in[3:0]) 
				4'b0000 : HEX1 = 7'b0000001;
				4'b0001 : HEX1 = 7'b1001111;
				4'b0010 : HEX1 = 7'b0010010;
				4'b0011 : HEX1 = 7'b0000110;
				4'b0100 : HEX1 = 7'b1001100;
				4'b0101 : HEX1 = 7'b0100100;
				4'b0110 : HEX1 = 7'b0100000;
				4'b0111 : HEX1 = 7'b0001111;
				4'b1000 : HEX1 = 7'b0000000;
				4'b1001 : HEX1 = 7'b0000100;
				default : HEX1 = 7'b0000001; // trang thai ban dau la 0
			endcase
			case (data_in[7:4]) 
				4'b0000 : HEX2 = 7'b0000001;
				4'b0001 : HEX2 = 7'b1001111;
				4'b0010 : HEX2 = 7'b0010010;
				4'b0011 : HEX2 = 7'b0000110;
				4'b0100 : HEX2 = 7'b1001100;
				4'b0101 : HEX2 = 7'b0100100;
				4'b0110 : HEX2 = 7'b0100000;
				4'b0111 : HEX2 = 7'b0001111;
				4'b1000 : HEX2 = 7'b0000000;
				4'b1001 : HEX2 = 7'b0000100;
				default : HEX2 = 7'b0000001; // trang thai ban dau la 0
			endcase
			
   end
	
assign led1 = HEX1;
assign led2 = HEX2;
endmodule