module gpio (
		input  wire       bt,      //      bt.export
		input  wire       clk_50mhz,        //     clk.clk
		output wire       led_don, // led_don.export
		output wire [7:0] o_reg,   //   o_reg.export
//		input  wire       reset,  //   reset.reset_n
		input  wire [2:0] sw_reg   //  sw_reg.export
	);
	
	
	
 mcu u0 (
        .bt_export      (bt),      //      bt.export
        .clk_clk        (clk_50mhz),        //     clk.clk
        .led_don_export (led_don), // led_don.export
        .o_reg_export   (o_reg),   //   o_reg.export
        .reset_reset_n  (1'b1),  //   reset.reset_n
        .sw_reg_export  (sw_reg)   //  sw_reg.export
    );
	
	
	
endmodule	
	