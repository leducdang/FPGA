module low_pass_filter (
    input clk,
    input rst_n,
    input sample_valid,
    input signed [15:0] x_in,
    output reg signed [15:0] y_out
);

reg signed [15:0] y_prev;
reg signed [16:0] err;
reg signed [16:0] delta;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        y_prev <= 0;
        y_out  <= 0;
    end
    else if (sample_valid) begin
        err   = x_in - y_prev;
        delta = err >>> 3;           // divide by 8
        y_out <= y_prev + delta;
        y_prev <= y_prev + delta;
    end
end

endmodule

