module led7seg(
    input  [3:0] digit,
    output reg [6:0] led
);
always @(*) begin
    case(digit)
        4'd0: led = 7'b1000000;
        4'd1: led = 7'b1111001;
        4'd2: led = 7'b0100100;
        4'd3: led = 7'b0110000;
        4'd4: led = 7'b0011001;
        4'd5: led = 7'b0010010;
        4'd6: led = 7'b0000010;
        4'd7: led = 7'b1111000;
        4'd8: led = 7'b0000000;
        4'd9: led = 7'b0010000;
        4'd10: led = 7'b0001000;  // A
        4'd11: led = 7'b0000011;  // b
        4'd12: led = 7'b1000110;  // C
        4'd13: led = 7'b0100001;  // d
        4'd14: led = 7'b0000110;  // E
        4'd15: led = 7'b0001110;  // F
        default: led = 7'b1111111;
    endcase
end
endmodule
