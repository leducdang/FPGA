module energy_calc
(
    input clk,
    input reset,

    input valid,
    input signed [15:0] sample,

    output reg [31:0] energy
);

always @(posedge clk or negedge reset)
begin
    if(!reset)
        energy <= 0;
    else if(valid)
        energy <= energy + sample*sample;
end

endmodule
