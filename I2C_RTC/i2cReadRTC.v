module i2creadRTC(
clk_50mhz,
i2c_scl,
i2c_sda,
data_out,
addr_read,
);

input	 clk_50mhz;
output i2c_scl;
inout i2c_sda;
output [7:0] data_out;
input 	[7:0] addr_read;
reg 		SCLK;
reg		SDI;
reg 	[6:0] counter;
reg	[7:0]	counterI2C;
reg 			clock;
reg 	[7:0] data;


//assign addr_read = 7'b1101000;


//TẠO XUNG 200Khz
always@(posedge clk_50mhz)
	begin
		if(counter == 7'd124)
			begin
				counter	<= 7'b0;
				clock = ~clock;
			end
		else
			counter <= counter +1;
	end

	
// tạo bien start, stop
	
	
//tao bien chuyen trang thai cho bien ra i2c.
always@ (negedge clock)	
	begin
		//if(!btstart)
		//	counterI2C	<= 0;
		//else
			//if(counterI2C < 85)
				counterI2C <= counterI2C + 1;		
	end
	
	
// chuong trinh i2c doc data i2c	
always@ (posedge clk_50mhz)	
	begin
		//if(!btstart)
		//	begin
		//		SDI	<=	1;
		//		SCLK	<= 1;
		//	end
		//else
			case(counterI2C)
				8'd0: begin
							SDI	<=	1;
							SCLK	<=	1;
						end
				//start
				8'd1: SDI	<=	0;
				8'd2: SCLK	<=	0;
				
				//address 1101_0000 wr_data=8'b1101_0000; //slave address
				//	1
				8'd3: begin
							SCLK	<=	0;
							SDI	<= 1;
						end
				8'd4: SCLK	<= 1;
				//	1
				
				8'd5:begin
							SCLK 	<= 0;
							SDI	<= 1;
						end
				8'd6: 	SCLK 	<= 1;
				
				// 0
				8'd7: begin
							SCLK 	<= 0;
							SDI 	<= 0;
						end
				8'd8:		SCLK 	<= 1;
				
				//1
				8'd9:	begin 
							SCLK	<= 0;
							SDI	<= 1;
						end
				8'd10:		SCLK 	<= 1;
				
				//0
				8'd11:begin
							SCLK 	<= 0;
							SDI	<= 0;
						end
				8'd12:	SCLK 	<=	1;
				
				//0
				8'd13:begin
							SCLK	<=	0;
							SDI	<=	0;
						end
				8'd14:	SCLK 	<=	1;
				
				//0
				8'd15:begin
							SCLK	<=	0;
							SDI	<=	0;
						end
				8'd16:	SCLK	<=	1;
				
				//0 - write DATA
				8'd17:begin
							SCLK	<= 0;
							SDI	<=	0;
						end		
				8'd18:	SCLK	<=	1;
				
				// ACK
				8'd19:begin
							SCLK	<= 0;
							SDI	<=	1'bz;
						end		
				8'd20:	SCLK	<=	1;
				
				
				// register address 0x00;
				
				//0	-1
				8'd21:begin
							SCLK	<= 0;
							SDI	<=	addr_read[0];
						end
				8'd22:	SCLK	<=	1;
				
				//0	-2
				8'd23:begin
							SCLK	<= 0;
							SDI	<=	addr_read[1];
						end
				8'd24:	SCLK	<=	1;
				
				//0	-3
				8'd25:begin
							SCLK	<= 0;
							SDI	<=	addr_read[2];
						end
				8'd26:	SCLK	<=	1;
				
				//0	-4
				8'd27:begin
							SCLK	<= 0;
							SDI	<=	addr_read[3];
						end
				8'd28:	SCLK	<=	1;
				
				//0	-5
				8'd29:begin
							SCLK	<= 0;
							SDI	<=	addr_read[4];
						end
				8'd30:	SCLK	<=	1;
				
				//0	-6
				8'd31:begin
							SCLK	<= 0;
							SDI	<=	addr_read[5];
						end
				8'd32:	SCLK	<=	1;
				
				//0	-7
				8'd33:begin
							SCLK	<= 0;
							SDI	<=	addr_read[6];
						end
				8'd34:	SCLK	<=	1;
				
				//0	-8
				8'd35:begin
							SCLK	<= 0;
							SDI	<=	addr_read[7];
						end
				8'd36:	SCLK	<=	1;
				
				//0	-bit Write
				//8'd37:begin
				//			SCLK	<= 0;
				//			SDI	<=	0;
				//		end
				//8'd38:	SCLK	<=	1;
				
				//0 -write ACK bit
				8'd37: begin	
							SCLK 	<= 0;
							SDI 	<= 1'bz;
						end
				8'd38:	SCLK 	<= 1;
				
				//restart
				
				8'd39:begin
							SCLK<=0;
				//			SDI <=0;	
						end
				8'd40:	SCLK 	<= 1;
				8'd41:	SDI 	<= 1;
				8'd42:	SDI 	<= 0;
				8'd43:	SCLK 	<= 0;
				
				//Device address  1101_000 + 1 bit read = 1
				
				//1
				8'd44:begin
							SCLK 	<= 0;
							SDI 	<= 1;
						end
				8'd45:	SCLK 	<= 1;
				
				//1
				8'd46:begin
							SCLK 	<= 0;
							SDI 	<= 1;
						end
				8'd47:	SCLK 	<= 1;
				
				//0
				8'd48:begin
							SCLK 	<= 0;
							SDI 	<= 0;
						end
				8'd49:	SCLK 	<= 1;
				
				//1
				8'd50:begin
							SCLK 	<= 0;
							SDI 	<= 1;
						end
				8'd51:	SCLK 	<= 1;
				
				//0
				8'd52:begin
							SCLK 	<= 0;
							SDI 	<= 0;
						end
				8'd53:	SCLK 	<= 1;
				
				//0
				8'd54:begin
							SCLK 	<= 0;
							SDI 	<= 0;
						end
				8'd55:	SCLK 	<= 1;
				
				//0
				8'd56:begin
							SCLK 	<= 0;
							SDI 	<= 0;
						end
				8'd57:	SCLK 	<= 1;
				
				//1  bit write
				8'd58:begin
							SCLK 	<= 0;
							SDI 	<= 1;
						end
				8'd59:	SCLK 	<= 1;
				
				// bit ACK feed back from RTC
				8'd60:begin
							SCLK 	<= 0;
							SDI 	<= 1'bz;
						end
				8'd61:	SCLK 	<= 1;
				
//--------------------------------------- read DATA Seconds --------------------------------------------
				
				//bit 0
				8'd62:begin
							SCLK 	<= 0;
							data[7] 	<= input_sda;
						end
				8'd63:	SCLK 	<= 1;
				
				//bit 1
				8'd64:begin
							SCLK 	<= 0;
							data[6] 	<= input_sda;
						end
				8'd65:SCLK 	<= 1;
				
				//bit 2
				8'd66:begin
							SCLK 	<= 0;
							data[5] 	<= input_sda;
						end
				8'd67:SCLK 	<= 1;
				//bit 3
				8'd68:begin
							SCLK 	<= 0;
							data[4] 	<= input_sda;
						end
				8'd69:SCLK 	<= 1;
				
				//bit 4
				8'd70:begin
							SCLK 	<= 0;
							data[3] 	<= input_sda;
						end
				8'd71:SCLK 	<= 1;
				
				// bit 5
				8'd72:begin
							SCLK 	<= 0;
							data[2] 	<= input_sda;
						end
				8'd73:SCLK 	<= 1;
				
				// bit 6
				8'd74:begin
							SCLK 	<= 0;
							data[1] 	<= input_sda;
						end
				8'd75:SCLK 	<= 1;
				
				// bit 7
				8'd76:begin
							SCLK 	<= 0;
							data[0] 	<= input_sda;
						end
				8'd77:SCLK 	<= 1;
						

//---------------------------------------BIT NAK--------------------------------------------
				//bit NAK
				8'd78:begin
							SCLK 	<= 0;
							SDI 	<= 1;
						end
				8'd79:	SCLK 	<= 1;
				
				
				//stop
				8'd80:begin	
							SCLK 	<= 0;
							SDI	<= 0;
						end
				8'd81:	SCLK 	<= 1;
				8'd82:	SDI 	<= 1;
				
	endcase
end




// NHAN VA XUAT 
assign i2c_scl = SCLK;
assign i2c_sda	= SDI;
assign input_sda	= i2c_sda;
assign data_out = data;
endmodule