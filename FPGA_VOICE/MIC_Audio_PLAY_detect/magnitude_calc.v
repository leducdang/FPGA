module magnitude_calc
(
    input clk,
    input valid,

    input signed [15:0] re,
    input signed [15:0] im,

    output reg [31:0] mag,
    output reg mag_valid
);

always @(posedge clk)
begin
    if(valid)
    begin
        mag <= re*re + im*im;
        mag_valid <= 1;
    end
    else
        mag_valid <= 0;
end

endmodule
