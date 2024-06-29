module controllUart(clock, tx, rx, reset, led7seg, led7seg1, led7seg2, led7seg3);

// khai bao chan dau vao, dau ra cho module top_level
input 	clock;		
input		rx;
input		reset;
output 	tx;
output [0:6] led7seg;
output [0:6] led7seg1;
output [0:6] led7seg2;
output [0:6] led7seg3;

// khai báo cac bien phu

reg		[7:0] 	HEX1, HEX2, HEX3, HEX4;					// bien gan gia tri rx nhan duoc sang ma led 7 doan
reg		[7:0]		data_tx;										// khai báo bien data gui di
reg					en;											// khai bao bien cho phep truyen du lieu
wire					fb_tx;										// khai bao bien feedback tu uart write
wire					fb_rx;										// khai bao bien feedback tu uart read
wire		[7:0]		data_rx;										// khai bao bien du lieu uart nhan duoc
reg		[7:0]		data_rx_str[3:0];							// khai bao chuoi du lieu nhan 4 byte, thay doi độ rộng mảng nếu muốn nhận du lieu lơn hơn
reg		[4:0]		stt_tx;										// bien chuyen trang thai truyen du lieu
reg		[4:0]		stt_rx;										// bien chuyen trang thai nhan du lieu

wire 	[7:0]	data_write[15:0];									// khai bao mang du lieu 2 chieu can gui di, 16 phan tu, do rong 1 byte
wire 	[127:0] chuoikitu = "** Thanh Hung **";			// khai bao chuoi du lieu can gui di


reg	[4:0] 	cnt_tx;											// khai bao bien thu tu du lieu được gửi đi
reg	[4:0] 	cnt_rx;											// khai báo biến thứ tự dữ liệu nhận được
reg	[15:0]	counter;     //50_000 = 1ms				// tạo 1 biến đếm để tạo tín hiệu ngắt 1ms, kiểm tra dũ liệu còn tiếp tục được gửi ko.

generate																						// khởi tao chuc năng vòng lặp
	genvar i;
		for( i = 1; i < 17; i = i+1)													// chuyển đổi dữ liệu cần gửi sang mảng dữ liệu 
			begin: covert_data
				assign data_write[16-i] = chuoikitu[i*8-1 : i*8-8];			
			end
endgenerate



// gui du lieu di
always@(posedge clock or negedge reset)
	begin
		if(!reset) begin	stt_tx<=0;	cnt_tx <= 0;	end 												// reset lại và gửi lại 
		else
			case(stt_tx)
				5'd0: begin en<=0; 	stt_tx<=1; end															// gửi bit cho phep = 0 để chức năng uart write khởi tạo lại
				5'd1:	if(!fb_tx) 		stt_tx<=2;																// đợi phản hồi từ uart write là đã khởi tạo xong
				5'd2:	begin en<=1; data_tx <= data_write[cnt_tx];	stt_tx<= 3;	end				//	gửi bit cho phép = 1 cho phép truyền dữ liệu, data cần gửi và chuyển trạng thái tiếp theo
				5'd3:	if(fb_tx) 																					// chờ phản hồi từ uart write là đã truyền xong dữ liệu
							begin		
								if(cnt_tx < 15) begin  cnt_tx <= cnt_tx + 1; stt_tx <= 0; end		// kiem tra số phần tử dữ liệu đã gửi,
								else stt_tx <= 4; 
							end
								
				
//				5'd4:	begin en<=0; 	stt<=5; end
//				5'd5:	if(!fb_tx) 		stt<=6;
//				5'd6:	begin en<=1; data_tx <= "B";	stt<= 7;	end
//				5'd7:	if(fb_tx) 	stt<=8;
//				
//				5'd8:	begin en<=0; 	stt<=9; end
//				5'd9:	if(!fb_tx) 		stt<=10;
//				5'd10:begin en<=1; data_tx <= "c";	stt<= 11;	end
//				5'd11:	if(fb_tx) 	stt<=12;
				
			endcase
	end

// hàm đọc chuôi dữ liệu nhận được 
	
always@(posedge clock)
	begin
		if(counter == 16'd49999)					// nêu sau 1ms không có dữ liệu nhận được thì reset biến nhân data đầu tiên về 0 và reset counter
			begin
				counter 	<= 0;
				cnt_rx	<= 0;
			end
		else
			begin
				counter <= counter + 1;				// tăng biến đếm counter
				case(stt_rx)
					4'd0:	if(fb_rx)	begin data_rx_str[cnt_rx] <= data_rx;  stt_rx <= 1; end		// cho khi viec doc du lieu hoan thanh thi gán gia tri nhan dươc vao chuoi và chuyên trạng thái
					4'd1:	begin cnt_rx <= cnt_rx + 1; stt_rx <= 2; end										// tăng địa chỉ lưu dữ liệu tiếp theo
					4'd2:	if(!fb_rx)	begin  stt_rx <= 0; counter 	<= 0; end							// cho khi uart_read chuẩn bị đọc dữ liệu tiếp theo.
				endcase
			end
	end
	
	
	
	
// gán các giá trị uart_read nhận được vào các biến phụ để gán dữ liệu cho led 7 đoạn

always@(posedge clock)
	begin
		case(data_rx_str[0])
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
		case(data_rx_str[1])
			8'h30 : HEX2 = 7'b0000001;
			8'h31 : HEX2 = 7'b1001111;
			8'h32 : HEX2 = 7'b0010010;
			8'h33 : HEX2 = 7'b0000110;
			8'h34 : HEX2 = 7'b1001100;
			8'h35 : HEX2 = 7'b0100100;
			8'h36 : HEX2 = 7'b0100000;
			8'h37 : HEX2 = 7'b0001111;
			8'h38 : HEX2 = 7'b0000000;
			8'h39 : HEX2 = 7'b0000100;
		endcase
		case(data_rx_str[2])
			8'h30 : HEX3 = 7'b0000001;
			8'h31 : HEX3 = 7'b1001111;
			8'h32 : HEX3 = 7'b0010010;
			8'h33 : HEX3 = 7'b0000110;
			8'h34 : HEX3 = 7'b1001100;
			8'h35 : HEX3 = 7'b0100100;
			8'h36 : HEX3 = 7'b0100000;
			8'h37 : HEX3 = 7'b0001111;
			8'h38 : HEX3 = 7'b0000000;
			8'h39 : HEX3 = 7'b0000100;
		endcase
		case(data_rx_str[3])
			8'h30 : HEX4 = 7'b0000001;
			8'h31 : HEX4 = 7'b1001111;
			8'h32 : HEX4 = 7'b0010010;
			8'h33 : HEX4 = 7'b0000110;
			8'h34 : HEX4 = 7'b1001100;
			8'h35 : HEX4 = 7'b0100100;
			8'h36 : HEX4 = 7'b0100000;
			8'h37 : HEX4 = 7'b0001111;
			8'h38 : HEX4 = 7'b0000000;
			8'h39 : HEX4 = 7'b0000100;
		endcase
	end

// khai báo các module con với đầu vào, ra tương ứng
	
uartWrite	write1(
				.clock_50mhz(clock),
				.data(data_tx),
				.run(en),
				.feedback(fb_tx),
				.tx_pin(tx)
			);
	
uartRead		read1(	
				.clock_50mhz(clock),				
				.data(data_rx),
				.rx_pin(rx),
				.feedback(fb_rx)
			);	

			
// gán dữ liệu cho các led 7 đoạn với dữ liệu tương ứng.
assign led7seg = HEX1;
assign led7seg1 = HEX2;
assign led7seg2 = HEX3;
assign led7seg3 = HEX4;


endmodule