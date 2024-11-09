module gpio( clock_50mhz,
				 led_out,
				 button,
				 lcd_data,
				 //lcd_on,
				 lcd_EN,
				 lcd_RS,
				 lcd_RW
				);

input clock_50mhz;
output [7:0] 	led_out;
input 			button;
inout [7:0] 	lcd_data;
				 //lcd_on,
output			lcd_EN;
output		 	lcd_RS;
output		 	lcd_RW;

    led_blink u0 (
        .button_export  (button),  //  button.export
        .clk_clk        (clock_50mhz),        //     clk.clk
        .lcd1602_DATA   (lcd_data),   // lcd1602.DATA
        .lcd1602_ON     (1'b0),     //        .ON
        .lcd1602_BLON   (1'b0),   //        .BLON
        .lcd1602_EN     (lcd_EN),     //        .EN
        .lcd1602_RS     (lcd_RS),     //        .RS
        .lcd1602_RW     (lcd_RW),     //        .RW
        .led_out_export (led_out), // led_out.export
        .reset_reset_n  (1'b1)   //   reset.reset_n
    );


endmodule
				
				
				
				
				