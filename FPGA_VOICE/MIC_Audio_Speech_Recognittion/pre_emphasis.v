module pre_emphasis(
    input clk,
    input rst,
    input pre_run,
    input signed [15:0] x_in,
    output reg signed [15:0] y_out,
    output reg pre_done
);

reg signed [15:0] x_reg;
reg signed [15:0] x_prev;
parameter signed [15:0] ALPHA = 16'sd31130; 
reg signed [31:0] mult_reg;
reg [3:0] stt;
reg first;

always @(posedge clk or negedge rst) 
begin
  if (!rst) begin
        x_prev <= 0;
        x_reg  <= 0;
        mult_reg <= 0;
        y_out <= 0;
        pre_done <= 0;
		  stt <= 1;
		  first <= 0;
    end
	else if(pre_run)
			begin
				if (!first) 
					begin
						// mẫu đầu tiên: không có mẫu trước
						y_out  <= x_in;
						x_prev <= x_in;
						first  <= 1;
						stt    <= 0;
						pre_done <= 1;
					end
				else
					begin
						case(stt)
							4'd1: begin
								mult_reg <= ALPHA * x_prev;
								x_reg <= x_in;
								stt <= 2;
							end
							4'd2: begin
								y_out <= x_reg - (mult_reg >>> 15);
								stt <= 3;
							end
							4'd3: begin
								x_prev <= x_reg;
								stt <= 0;
								pre_done <= 1;
							end
						endcase
					end
			end
	else if(!pre_run)
			begin
				pre_done <= 0;
				stt <= 1;
			end
end
endmodule



//module pre_emphasis(
//    input clk,
//    input rst,
//    input pre_run,
//    input signed [15:0] x_in,
//    output reg signed [15:0] y_out,
//    output reg pre_done
//);
//
//reg signed [15:0] x_reg;
//reg signed [15:0] x_prev;
//reg signed [31:0] mult_reg;
//reg [3:0] stt;
//reg first;
//
//parameter signed [15:0] ALPHA = 16'sd31130;   // ~0.95 Q15
//
//always @(posedge clk or negedge rst) begin
//    if (!rst) begin
//        x_reg    <= 0;
//        x_prev   <= 0;
//        mult_reg <= 0;
//        y_out    <= 0;
//        pre_done <= 0;
//        stt      <= 0;
//        first    <= 0;
//    end
//    else begin
//        pre_done <= 0;
//
//        if (pre_run) begin
//            if (!first) begin
//                // mẫu đầu tiên: không có mẫu trước
//                y_out  <= x_in;
//                x_prev <= x_in;
//                first  <= 1;
//                stt    <= 0;
//                pre_done <= 1;
//            end
//            else begin
//                case (stt)
//                    4'd0: begin
//                        x_reg <= x_in;
//                        mult_reg <= ALPHA * x_prev;
//                        stt <= 1;
//                    end
//
//                    4'd1: begin
//                        y_out <= x_reg - (mult_reg >>> 15);
//                        stt <= 2;
//                    end
//
//                    4'd2: begin
//                        x_prev <= x_reg;
//                        pre_done <= 1;
//                        stt <= 0;
//                    end
//
//                    default: stt <= 0;
//                endcase
//            end
//        end
//    end
//end
//
//endmodule
