module top_level(
						clock,
						reset,
						phase,
						sin,
						cos,
						HEX1,
						HEX2,
						HEX3,
						HEX4,
						HEX5,
						HEX6,
						HEX7,
						HEX8
);


output [6:0] HEX1;
output [6:0] HEX2;
output [6:0] HEX3;
output [6:0] HEX4;
output [6:0] HEX5;
output [6:0] HEX6;
output [6:0] HEX7;
output [6:0] HEX8;


input clock;
input reset;
input [9:0] phase;
output [7:0] cos;
output [7:0] sin;

reg [11:0] data;     // max = 4096
reg [6:0] data1;

// 17.44444 = 3.14*1000/180
reg [1:0] bitInt;
reg		 bitDau;          // bit hiển thi dấu = 0 là (-); = 1 là (+)
reg [6:0] bitPhanso;			// bit phân số
reg [9:0] phaseIn;


reg [3:0] cos0;				// so nguyen
reg [3:0] cos1;				// so thap phan thu 1
reg [3:0] cos2;				// so thap phan thu 2
reg [3:0] cos3;				// so thap phan thu 3


reg [3:0] sin0;				// so nguyen
reg [3:0] sin1;				// so thap phan thu 1
reg [3:0] sin2;				// so thap phan thu 2
reg [3:0] sin3;				// so thap phan thu 3


wire [7:0] outCos;
wire [7:0] outSin;




always@(posedge clock)
begin
	data = phase * 17444/1000;
	if(data > 3000)
		begin
			bitInt <= 3;
			bitPhanso <= (data - 3000) *128 / 1000 + 1;	// láy giá trị phần phan so
		end
	else if(data > 2000)
		begin
			bitInt <= 2;
			bitPhanso <= (data - 2000) *128 / 1000 + 1;
		end
	else if (data > 1000)
		begin
			bitInt <= 1;
			bitPhanso <= (data - 1000) *128 / 1000 + 1;
		end
	else
		begin
			bitInt <= 0;
			bitPhanso <= data * 128 / 1000 + 1;
		end

	phaseIn <= {bitDau,bitInt,bitPhanso};		// tạo du lieu phase du lieu dau vao
	
	cos0 <= outCos[6];								// lay gia tri nguyen của cos đầu ra
	sin0 <= outSin[6];								// lay gia tri nguyen cua sin dau ra
		
	cos1 <= outCos[5:0]*10/64;						// lay gia tri so thap phan thu nhat
	cos2 <= outCos[5:0]*100/64%10;				// lay gia tri so thap phan thu 2
	cos3 <= outCos[5:0]*1000/64%100;				// lay gia tri so thap phan thu 3

	sin1 <= outSin[5:0]*10/64;						// lay gia tri so thap phan thu nhat
	sin2 <= outSin[5:0]*100/64%10;				// lay gia tri so thap phan thu 2
	sin3 <= outSin[5:0]*1000/64%100;				// lay gia tri so thap phan thu 3
	
end

assign sin = outSin;
assign cos = outCos;

ip_cordic u1(
		.a(phaseIn),      //      a.a
		.areset(!reset), // areset.reset
		.c(outCos),      //      c.c
		.clk(clock),    //    clk.clk
		.s(outSin)       //      s.s
	);		
	
led7seg u2(
			.clk(clock), 
			.data_in(cos3),
			.led(HEX1)
				 );

led7seg u3(
			.clk(clock), 
			.data_in(cos2),
			.led(HEX2)
				 );
				 
led7seg u4(
			.clk(clock), 
			.data_in(cos1),
			.led(HEX3)
				 );
				 
led7seg u5(
			.clk(clock), 
			.data_in(cos0),
			.led(HEX4)
				 );
				 
led7seg u6(
			.clk(clock), 
			.data_in(sin3),
			.led(HEX5)
				 );
				 
led7seg u7(
			.clk(clock), 
			.data_in(sin2),
			.led(HEX6)
				 );
				 
led7seg u8(
			.clk(clock), 
			.data_in(sin1),
			.led(HEX7)
				 );
				 
led7seg u9(
			.clk(clock), 
			.data_in(sin0),
			.led(HEX8)
				 );
	
endmodule


