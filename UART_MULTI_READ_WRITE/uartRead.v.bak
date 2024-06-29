module uartRead(	clock_50mhz,				
						data,
						rx_pin
			);
			
// khai bao dau vao dau ra cho module
input 			clock_50mhz;		// xung dau vao
input 			rx;
output write [7:0] 	data; 		// 8bit data nhan duoc


// khai bao cac bien 

reg	clock;							// xung clock voi baurade 115200/s
reg	[7:0]		counter;				// 50000000:115200:2 = 217. tính so xung cho 1 nua chu ky baurate 115200/s
reg	[7:0]		stt_rx;				//	trang thai khung nhan uart


// hàm tao xung clock baurade 115200/s

always@(posedge clock_50mhz)
	begin
		if(counter == 8'd216)
			begin
				counter<=0;
				clock= ~clock; 
			end
		else
			counter <= counter + 1;
	end
	
// chuong trinh nhan data

always@(posedge clock)
	begin

		if(rx_ready)					// kiem tra trang thai 
			begin
				if(input_rx == 0) begin stt_rx <= 0; rx_ready <= 0; end // nhan tin hieu reciver start
			end
			
		else
			case(stt_rx)
				8'd0: begin data_rx[0]	<= input_rx; stt_rx<=1; end		// nhan bit du lieu dau tien
				8'd1:	begin data_rx[1]	<= input_rx; stt_rx<=2; end		
				8'd2:	begin data_rx[2]	<= input_rx; stt_rx<=3; end
				8'd3:	begin data_rx[3]	<= input_rx; stt_rx<=4; end
				8'd4:	begin data_rx[4]	<= input_rx; stt_rx<=5; end
				8'd5:	begin data_rx[5]	<= input_rx; stt_rx<=6; end
				8'd6:	begin data_rx[6]	<= input_rx; stt_rx<=7; end
				8'd7:	begin data_rx[7]	<= input_rx; stt_rx<=8; end		// nhan bit du lieu cuoi cung
				8'd8:	rx_ready <= 1;
				//8'd9:	
			endcase
		end

assign input_rx = rx_pin;
	
endmodule