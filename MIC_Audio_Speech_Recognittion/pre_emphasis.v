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
//parameter signed [15:0] ALPHA = 16'sd31130; 
//reg signed [31:0] mult_reg;
//reg [3:0] stt;
//reg first;
//
//always @(posedge clk or negedge rst) 
//begin
//  if (!rst) begin
//        x_prev <= 0;
//        x_reg  <= 0;
//        mult_reg <= 0;
//        y_out <= 0;
//        pre_done <= 0;
//		  stt <= 1;
//		  first <= 0;
//    end
//	else if(pre_run)
//			begin
//				if (!first) 
//					begin
//						// mẫu đầu tiên: không có mẫu trước
//						y_out  <= x_in;
//						x_prev <= x_in;
//						first  <= 1;
//						stt    <= 0;
//						pre_done <= 1;
//					end
//				else
//					begin
//						case(stt)
//							4'd1: begin
//								mult_reg <= ALPHA * x_prev;
//								x_reg <= x_in;
//								stt <= 2;
//							end
//							4'd2: begin
//								y_out <= x_reg - (mult_reg >>> 15);
//								stt <= 3;
//							end
//							4'd3: begin
//								x_prev <= x_reg;
//								stt <= 0;
//								pre_done <= 1;
//							end
//						endcase
//					end
//			end
//	else if(!pre_run)
//			begin
//				pre_done <= 0;
//				stt <= 1;
//			end
//end
//endmodule


module pre_emphasis(
    input  wire clk,
    input  wire rst,

    input  wire pre_run,
    input  wire signed [15:0] x_in,

    output reg signed [15:0] y_out,
    output reg pre_done,
	 
	 input wire frame_new
);

    parameter signed [15:0] ALPHA = 16'sd31130; // 0.95 Q1.15

    localparam IDLE = 2'd0;
    localparam MUL  = 2'd1;
    localparam SUB  = 2'd2;
    localparam DONE = 2'd3;

    reg [1:0] state;

    reg signed [15:0] x_reg;
    reg signed [15:0] x_prev;
    reg signed [31:0] mult_reg;


    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            state    <= IDLE;
            x_reg    <= 16'sd0;
            x_prev   <= 16'sd0;
            mult_reg <= 32'sd0;
            y_out    <= 16'sd0;
            pre_done <= 1'b0;
        end
        else begin
            pre_done <= 1'b0;

            case(state)

                IDLE: begin
                    if(pre_run) begin
                        x_reg <= x_in;

                        if(frame_new) begin
                            y_out  <= x_in;
                            x_prev <= x_in;
                            state  <= DONE;
                        end
                        else begin
                            state <= MUL;
                        end
                    end
                end

                MUL: begin
                    mult_reg <= x_prev * ALPHA;
                    state <= SUB;
                end

                SUB: begin
                    y_out <= x_reg - (mult_reg >>> 15);
                    state <= DONE;
                end

                DONE: begin
                    x_prev   <= x_reg;
                    pre_done <= 1'b1;

                    // chờ pre_run hạ xuống rồi mới nhận mẫu mới
                    if(!pre_run)
                        state <= IDLE;
                end

            endcase
        end
    end

endmodule
