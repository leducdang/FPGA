module sdCardControl(
							input 	clk_50mhz,
							input 	reset,
							inout 	SD_cmd,
							inout 	SD_dat,
							inout 	SD_dat3,
							output 	SD_clock
);



SDCard u0 (
        .clk_clk           (clk_50mhz),           //    clk.clk
        .reset_reset_n     (reset),     //  reset.reset_n
        .sdcard_b_SD_cmd   (SD_cmd),   // sdcard.b_SD_cmd
        .sdcard_b_SD_dat   (SD_dat),   //       .b_SD_dat
        .sdcard_b_SD_dat3  (SD_dat3),  //       .b_SD_dat3
        .sdcard_o_SD_clock (SD_clock)  //       .o_SD_clock
    );

endmodule
