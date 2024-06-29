module i2cControllerRTC(
					clock,
					sda,
					scl,
					data,
					led7seg,
					led7seg2,
					led7min1,
					led7min2,
					led7hour1,
					led7hour2
);
// khai báo đầu vao, đầu ra cho chương trình
input	 clock;
inout  sda;
output scl;
output [0:6] led7seg;
output [0:6] led7seg2;
output [0:6] led7min1;
output [0:6] led7min2;
output [0:6] led7hour1;
output [0:6] led7hour2;
output 	[7:0] data;

// khai báo các biến phụ 
reg [7:0]		addr_read;	
reg [7:0]		data_seconds;
reg [7:0]		data_minutes;
reg [7:0]		data_hours;

//parameter [7:0] addr_read_data = 8'b0000_0000;
//parameter [7:0] addr_read_data_minute = 8'b1000_0000;

reg 	[22:0] counter;				
reg	[2:0] counter_update;

// tan so 10hz - quet lan luot lay gia tri thanh ghi RTC
always@(posedge clock)
	begin
		if(counter == 23'd4999999)
			begin
				counter	<= 23'b0;
				counter_update = counter_update + 1;
			end
		else
			counter <= counter +1;
	end

// VÒNG LẶP GÁN ĐỊA CHỈ MỚI ĐỂ ĐỌC THANH GHI.
always@(posedge clock)
begin
	case(counter_update)
	3'd0: addr_read = 8'b0000_0000;
	3'd1:	data_seconds = data;	
	3'd2: addr_read = 8'b1000_0000;
	3'd3: data_minutes = data;
	3'd4: addr_read = 8'b0100_0000;
	3'd5: data_hours = data;
	
	endcase
end
	
// GOI MODULE CON DE DOC DU LIEU VOI DIA CHI TUONG UNG
i2creadRTC seconds(
				.clk_50mhz(clock),
				.i2c_scl(scl),
				.i2c_sda(sda),
				.data_out(data),
				.addr_read(addr_read),
						);

// HIEN THI LED 7 DOAN VOI DATA SECONDS TUONG UNG NHAN ĐƯỢC
led7seg ledseconds(
		.clk(clock), 
		.data_in(data_seconds),
		.led1(led7seg), 
		.led2(led7seg2)
);

//HIEN THI PHÚT
led7seg ledminutes(
		.clk(clock), 
		.data_in(data_minutes),
		.led1(led7min1), 
		.led2(led7min2)
);

//HIEN THI GIO
led7seg ledhours(
		.clk(clock), 
		.data_in(data_hours),
		.led1(led7hour1), 
		.led2(led7hour2)
);

endmodule
