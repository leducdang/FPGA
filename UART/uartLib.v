module uartLib(clock_50mhz, 
					tx_pin, 
					rx_pin, 
					reset_pin, 
					//clock_out, 
					//tx_test, 
					led7seg);

// khai bao các chan vào ra
input 	clock_50mhz;
input 	rx_pin;
input		reset_pin;
output	tx_pin;
//output	tx_test;							// kiem tra frame truyen
//output	clock_out;						// kiem tra xung clock baurate
output [0:6] led7seg;

// tao cac bien thay doi
reg rx;				
reg tx;

reg 		[7:0] 	data_tx = 8'h41;	// du lieu rx gui di
reg		[7:0]		data_rx;				// du lieu rx nhan duoc
reg		[7:0]		counter; 			// 50000000:115200:2 = 217. tính so xung cho 1 nua chu ky baurate 115200/s
reg					clock; 				// lAY Xung cạnh len duoc tan so 115200/s baurate mong muon.
reg		[7:0]		stt_tx;				//	trang thai khung truyen uart
reg		[7:0]		stt_rx;				//	trang thai khung nhan uart
reg					rx_ready;			//	bit kiem tra chân rx da san sang nhan du lieu hay chua = 1 la san sang

reg		[7:0] 	HEX1;					// bien gan gia tri rx nhan duoc sang ma led 7 doan


// chuong trinh tao 1 xung clock co baurade 115200 xung /s
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



// chuong trinh uart gui du lieu	
always@(posedge clock or negedge reset_pin)
	begin
		if(!reset_pin)																	//khoi tao
			begin
				stt_tx <= 0;				
				tx <= 1;
			end
		else 
			case(stt_tx)
				8'd0: begin tx<=0; 				stt_tx<=1; end					// start
				8'd1:	begin tx <= data_tx[0]; stt_tx<=2; end					// gui bit lsb - bit[0]
				8'd2:	begin tx <= data_tx[1]; stt_tx<=3; end					//  bit[1]
				8'd3:	begin tx <= data_tx[2]; stt_tx<=4; end					//  bit[2]
				8'd4:	begin tx <= data_tx[3]; stt_tx<=5; end					//  bit[3]
				8'd5:	begin tx <= data_tx[4]; stt_tx<=6; end					//  bit[4]
				8'd6:	begin tx <= data_tx[5]; stt_tx<=7; end					//  bit[5]
				8'd7:	begin tx <= data_tx[6]; stt_tx<=8; end					//  bit[6]
				8'd8:	begin tx <= data_tx[7]; stt_tx<=9; end					//  gui bit msb - bit[7]
				8'd9:	begin tx <= 1; 			stt_tx<=10; end				//  stop
				8'd10:begin tx <= 1; 			stt_tx<=11; end					
				
			endcase
		end

// CHUONG TRINH NHAN DU LIEU
always@(posedge clock or negedge reset_pin)
	begin
		if(!reset_pin)						//reset lại thiet bi
			begin
				stt_rx <= 0;
				rx_ready <= 1;				// dua ve trang thai san sang nhan du lieu
			end
		else if(rx_ready)					// kiem tra trang thai 
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

// hien thi du lieu nhan duoc ra LED 7 doan
always@(clock_50mhz)
	begin
		case(data_rx)
			8'h30 : HEX1 = 7'b0000001;
			8'h31 : HEX1 = 7'b1001111;
			8'h32 : HEX1 = 7'b0010010;
			8'h33 : HEX1 = 7'b0000110;
			8'h34 : HEX1 = 7'b1001100;
			8'h35 : HEX1 = 7'b0100100;
			8'h36 : HEX1 = 7'b0100000;
			8'h37 : HEX1 = 7'b0001111;
			8'h38 : HEX1 = 7'b0000000;
			8'h39 : HEX1 = 7'b0000100;
		endcase
	end
		
		
assign led7seg = HEX1;	
assign input_rx = rx_pin;	
assign tx_pin = tx;
assign tx_test = tx;
assign clock_out = clock;
endmodule
