module magnitude_calc
(
    input clk,
    input valid,

    input signed [23:0] re,
    input signed [23:0] im,

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





//reg signed [31:0] re_sq, im_sq;
//reg signed [31:0] sum;
//
//always @(posedge clk)
//begin
//    if(valid) begin
//        re_sq <= re * re;
//        im_sq <= im * im;
//    end
//end
//
//always @(posedge clk)
//begin
//    if(valid) begin
//        sum <= re_sq + im_sq;
//        mag <= sum[31:8];   // thay vì >>8
//        mag_valid <= 1;
//    end
//    else
//        mag_valid <= 0;
//end