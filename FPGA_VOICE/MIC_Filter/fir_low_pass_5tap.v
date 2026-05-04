module fir_low_pass_5tap (
    input clk,
    input rst_n,
    input sample_valid,
    input signed [15:0] x_in,
    output reg signed [15:0] y_out
);

reg signed [15:0] x0, x1, x2, x3, x4;
reg signed [18:0] acc;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        x0 <= 0; x1 <= 0; x2 <= 0; x3 <= 0; x4 <= 0;
        y_out <= 0;
    end
    else if (sample_valid) begin
        x4 <= x3;
        x3 <= x2;
        x2 <= x1;
        x1 <= x0;
        x0 <= x_in;

        acc = x0 + (x1 <<< 1) + (x2 <<< 1) + (x3 <<< 1) + x4;
        y_out <= acc >>> 3; // divide by 8
    end
end

endmodule

