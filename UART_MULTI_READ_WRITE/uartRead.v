module uartRead(	clock_50mhz,				
						data,
						rx_pin,
						feedback
			);
			
// khai bao dau vao dau ra cho module
input 			clock_50mhz;		// xung dau vao
input 			rx_pin;
output wire [7:0] 	data; 		// 8bit data nhan duoc
output wire		feedback;			// khai báo tin hieu feedback dau ra

// khai bao cac bien 

reg	clock;							// xung clock voi baurade 115200/s
reg	fb;
reg	[7:0]		counter;				// 50000000:115200:2 = 217. tính so xung cho 1 nua chu ky baurate 115200/s
reg	[7:0]		stt_rx;				//	trang thai khung nhan uart
reg	rx_ready;
reg	[7:0]		data_reciver;

// hàm tao xung clock baurade 115200/s

always@(posedge clock_50mhz)
	begin
		if(counter == 8'd216)
			begin
				counter<=0;
				clock= ~clock; 		// tao xung clock có tan so 115200 bit/s
			end
		else
			counter <= counter + 1;
	end
	
// chuong trinh nhan data

always@(posedge clock)
	begin

		if(rx_ready)					// kiem tra trang thai 
			begin
				if(input_rx == 0) begin stt_rx <= 0; rx_ready <= 0; fb<=0; end // nhan tin hieu reciver start
			end
			
		else
			case(stt_rx)
				8'd0: begin data_reciver[0]	<= input_rx; stt_rx<=1; end		// nhan bit du lieu dau tien
				8'd1:	begin data_reciver[1]	<= input_rx; stt_rx<=2; end		
				8'd2:	begin data_reciver[2]	<= input_rx; stt_rx<=3; end
				8'd3:	begin data_reciver[3]	<= input_rx; stt_rx<=4; end
				8'd4:	begin data_reciver[4]	<= input_rx; stt_rx<=5; end
				8'd5:	begin data_reciver[5]	<= input_rx; stt_rx<=6; end
				8'd6:	begin data_reciver[6]	<= input_rx; stt_rx<=7; end
				8'd7:	begin data_reciver[7]	<= input_rx; stt_rx<=8; end		// nhan bit du lieu cuoi cung
				8'd8:	begin rx_ready <= 1; stt_rx <= 9; fb <= 1;	end
				//8'd9:	
			endcase
		end

assign input_rx = rx_pin;				// doc trang thai chan rx
assign data = data_reciver;			// gan du lieu cho ouput data voi du lieu nhan duoc, gui ve cho module top_level
assign feedback = fb;					// tin hieu phan hoi
endmodule