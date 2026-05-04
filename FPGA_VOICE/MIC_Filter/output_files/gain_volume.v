module gain_volume (
    input  signed [15:0] x_in,
    output reg signed [15:0] y_out
);
    reg signed [17:0] temp;

    always @(*) begin
			temp = x_in <<< 1; 				// x2
//			temp = x_in + (x_in >>> 1);   // x1.5 
//			temp = x_in + (x_in >>> 2);	// x1.25

        if (temp > 32767)
            y_out = 16'sd32767;
        else if (temp < -32768)
            y_out = -16'sd32768;
        else
            y_out = temp[15:0];
    end
endmodule


