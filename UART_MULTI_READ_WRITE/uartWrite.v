module uartWrite(
						clock_50mhz,
						data,
						run,
						feedback,
						tx_pin
			);
			
// khai bao dau vao dau ra cho module
input 			clock_50mhz;		// xung dau vao
input [7:0] 	data; 				// 8bit data gui di
input 			run;					// 0 reset tham so chuan bi gui data cho lan toi, 1 gui data
output			tx_pin;				// chan tx là chân out ra			
output wire		feedback;			// tra ve ket qua = 1 khi da gui xong data

// khai bao cac bien 

reg	clock;							// xung clock voi baurade 115200/s
reg	fb;								// bien phan hoi ket qua
reg 	tx;								// bien gan gia tri cho chan tx
//reg	[7:0]		counter;				// 50000000:115200:2 = 217. tính so xung cho 1 nua chu ky baurate 115200/s
reg	[11:0]	counter;				// 50000000:9600:2 = 2604. tính so xung cho 1 nua chu ky baurate 9600 bit/s
reg	[7:0]		stt_tx;				//	trang thai khung truyen uart




// hàm tao xung clock baurade 115200/s

always@(posedge clock_50mhz)
	begin
//		if(counter == 8'd216)		// baurade 115200 bit/s
		if(counter == 12'd2603)		// baurade	9600  bit/s
			begin
				counter<=0;
				clock= ~clock; 												// đầu ra xung clock có tần số 115200/s
			end
		else
			counter <= counter + 1;
	end
	
// chuong trinh gui data

always@(posedge clock)
	begin
		if(run)																		//	module top_level gui data va tín hieu bắt đầu truyền dữ liệu 
			case(stt_tx)
				8'd0: begin tx<=0; 			stt_tx<=1; end					// start
				8'd1:	begin tx <= data[0]; stt_tx<=2; end					// gui bit lsb - bit[0]
				8'd2:	begin tx <= data[1]; stt_tx<=3; end					//  bit[1]
				8'd3:	begin tx <= data[2]; stt_tx<=4; end					//  bit[2]
				8'd4:	begin tx <= data[3]; stt_tx<=5; end					//  bit[3]
				8'd5:	begin tx <= data[4]; stt_tx<=6; end					//  bit[4]
				8'd6:	begin tx <= data[5]; stt_tx<=7; end					//  bit[5]
				8'd7:	begin tx <= data[6]; stt_tx<=8; end					//  bit[6]
				8'd8:	begin tx <= data[7]; stt_tx<=9; end					//  gui bit msb - bit[7]
				8'd9:	begin tx <= 1; 		stt_tx<=10; end				//  stop
				8'd10:begin tx <= 1; 		stt_tx<=11; fb <=1; end		//  bit stop và fb lai cho module top_level la da truyen xong du lieu		
			endcase
			
		else if(!run)																// khoi tao lai de chuan bi gui byte tiep theo
			begin
				fb <= 0;
				stt_tx <= 0;
			end
	end

assign tx_pin = tx;				// gan trang thai tin hieu ra chan TX							
assign feedback = fb;			// gan du lieu feedback cho module top_level		
	
endmodule