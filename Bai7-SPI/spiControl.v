module spiControl(	input 	clk_50mhz,
							input 	reset,
							input 	MISO,
							output 	MOSI,
							output 	SCLK,
							output 	SS
);

   spi u0 (
        .clk_clk       (clk_50mhz),       //   clk.clk
        .reset_reset_n (reset), // reset.reset_n
        .spi_MISO      (MISO),      //   spi.MISO
        .spi_MOSI      (MOSI),      //      .MOSI
        .spi_SCLK      (SCLK),      //      .SCLK
        .spi_SS_n      (SS)       //      .SS_n
    );


endmodule
