//module mel_20band_linear_3input (
//    input              clk,
//    input              rst,
//    input              start,          // flag bắt đầu tính
//	 input 				  ack,
//
//    input      [15:0]  bin0,
//    input      [15:0]  bin1,
//    input      [15:0]  bin2,
//
//    output reg         done,           // flag báo xong
//    output reg [17:0]  band_out        // kết quả tổng 3 bin
//);
//
//always @(posedge clk or posedge rst)
//begin
//    if (rst) begin
//        band_out <= 0;
//        done     <= 0;
//    end
//    else begin
//        if (start) begin
//            band_out <= bin0 + bin1 + bin2;
//            done     <= 1;   // báo hoàn thành sau 1 clock
//        end
//		  else
//			if (done && ack)
//				done <= 0;
//    end
//end
//
//endmodule

/*

cách lây dữ liệu bên top_level
case(stt)
1:	if(!done)
	begin
		bin0 <= ...;
		bin1 <= ...;
		bin2 <= ...;
		start <= 1;
		stt <= 2;
	end

2:	if (done) begin
		 data <= band_out;
		 ack <= 1;
		 stt <= 3;
		 start <= 0;
	end
3:	begin
    ack <= 0;
	 stt <= 1;
	end
	  
*/	 
	 