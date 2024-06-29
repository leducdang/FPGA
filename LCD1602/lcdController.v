module lcdController(clock_50mhz, rs_pin, rw_pin, en_pin, pinLCD, led_out );

//lcd1602Write

// khai báo in out cho thu vien lcd
input clock_50mhz;
output rs_pin;
output rw_pin;
output en_pin;
output 	[7:0] led_out;
output 	[7:0]	pinLCD;


//khai báo biến phụ
reg 		[15:0]	counter_1ms;		// bien dem tạo xung clock 1ms
reg		[9:0]		counter_lcd;				// bien dem chuyen trang thai lcd 1ms
reg	rs;
reg	rw;
reg	en;
reg 	[3:0]	pos_x;      //cột
reg 	[1:0]	pos_y;		// hàng
reg 	[7:0] data;
reg 	[7:0] char = 8'd48;				// 

wire 	[7:0]	data_write[15:0];
wire 	[127:0] chuoikitu = "** Thanh Hung **";

reg	[4:0]	counter;
reg	[9:0]		counter_char;
//chuoikitu = " Cong Ty Thanh Hung ";

generate
	genvar i;
		for( i = 1; i < 17; i = i+1)
			begin: covert_data
				assign data_write[16-i] = chuoikitu[i*8-1 : i*8-8];			
			end
endgenerate

always@(posedge clock_50mhz)
	begin
		//if(counter_1ms == 16'd24999)
		if(counter_1ms == 16'd49999)
			begin 
				counter_1ms <= 16'd0;
				counter_lcd <= counter_lcd + 1;
				counter_char <= counter_char + 1;

				
					if (counter_lcd > 40)
						begin
							counter_lcd <= 10'd29;
							if(counter < 16)
								counter <= counter+1;
						end

					if(counter_char == 10'd1000)
						begin
							char <= char + 1;
							counter_char <= 10'd0;	
							if (char > 8'd117) char <= 8'd48;
						
						end
			end
		else
			counter_1ms <= counter_1ms + 1;
	end
	

always@(posedge clock_50mhz)
	begin
		case(counter_lcd)
		
		// khoi tao LCD
			10'd5:begin
						rs <= 0;
						rw	<=	0;
						data <= 8'h30;
					end
			10'd6:	en <= 1;
			10'd7:	en	<= 0;
			
			10'd13:	begin
						rs <= 0;
						rw	<=	0;
						data <= 8'h30;
					end
			10'd14:en <= 1;
			10'd15:en	<= 0;
			
			10'd17:begin
						rs <= 0;
						rw	<=	0;
						data <= 8'h30;
					end
			10'd18:en <= 1;
			10'd19:en	<= 0;
			
			10'd20:begin
						rs <= 0;
						rw	<=	0;
						data <= 8'h38;
					end
			10'd21:en <= 1;
			10'd22:en	<= 0;
			//4
			10'd23:begin
						rs <= 0;
						rw	<=	0;
						data <= 8'h01;
					end
			10'd24:en <= 1;
			10'd25:en	<= 0;
			
			// TAT CON TRO
			10'd26:begin
						rw	<=	0;
						rs <= 0;
						data <= 8'h0C;
					end
			10'd27:en <= 1;
			10'd28:en	<= 0;
			
			// GHI VI TRI
			10'd29:begin
						rw	<=	0;
						rs <= 0;
						data <= 8'h80 + 6;
					end
			10'd30:en <= 1;
			10'd31:en	<= 0;
			

			// GHI DU LIEU HIEN THI
			10'd32:begin
						rw	<=	0;
						rs <= 1;
						data <= char;
					end
			10'd33:en 	<= 1;
			10'd34:en	<= 0;
			
		//------------------ gui chuoi gia tri --------------------	
						// GHI VI TRI
			10'd35:begin
							rw	<=	0;
							rs <= 0;
							data <= 8'hC0 + counter;
						
					end
			10'd36:en 	<= 1;
			10'd37:en	<= 0;
			
			10'd38:if(counter<16)
						begin
							rw	<=	0;
							rs <= 1;
							data <= data_write[counter];
						end
			10'd39:if(counter < 16) en <= 1;
			10'd40:if(counter < 16) en	<= 0;
		
		endcase
	end
	
assign led_out = data;
assign rs_pin = rs;
assign rw_pin = rw;
assign en_pin = en;
assign pinLCD = data;


endmodule