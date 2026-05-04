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

always @(posedge clk or negedge rst) 
begin
  if (!rst) begin
        x_prev <= 0;
        x_reg  <= 0;
        mult_reg <= 0;
        y_out <= 0;
        pre_done <= 0;
		  stt <= 1;
    end
	else if(pre_run)
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
	else if(!pre_run)
			begin
				pre_done <= 0;
				stt <= 1;
			end
end
endmodule

