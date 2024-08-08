// IP_SRAM.v

// Generated using ACDS version 22.1 915

`timescale 1 ps / 1 ps
module IP_SRAM (
		input  wire [19:0] address,       //  avalon_sram_slave.address
		input  wire [1:0]  byteenable,    //                   .byteenable
		input  wire        read,          //                   .read
		input  wire        write,         //                   .write
		input  wire [15:0] writedata,     //                   .writedata
		output wire [15:0] readdata,      //                   .readdata
		output wire        readdatavalid, //                   .readdatavalid
		input  wire        clk,           //                clk.clk
		inout  wire [15:0] SRAM_DQ,       // external_interface.DQ
		output wire [19:0] SRAM_ADDR,     //                   .ADDR
		output wire        SRAM_LB_N,     //                   .LB_N
		output wire        SRAM_UB_N,     //                   .UB_N
		output wire        SRAM_CE_N,     //                   .CE_N
		output wire        SRAM_OE_N,     //                   .OE_N
		output wire        SRAM_WE_N,     //                   .WE_N
		input  wire        reset          //              reset.reset
	);

	IP_SRAM_sram_0 sram_0 (
		.clk           (clk),           //                clk.clk
		.reset         (reset),         //              reset.reset
		.SRAM_DQ       (SRAM_DQ),       // external_interface.export
		.SRAM_ADDR     (SRAM_ADDR),     //                   .export
		.SRAM_LB_N     (SRAM_LB_N),     //                   .export
		.SRAM_UB_N     (SRAM_UB_N),     //                   .export
		.SRAM_CE_N     (SRAM_CE_N),     //                   .export
		.SRAM_OE_N     (SRAM_OE_N),     //                   .export
		.SRAM_WE_N     (SRAM_WE_N),     //                   .export
		.address       (address),       //  avalon_sram_slave.address
		.byteenable    (byteenable),    //                   .byteenable
		.read          (read),          //                   .read
		.write         (write),         //                   .write
		.writedata     (writedata),     //                   .writedata
		.readdata      (readdata),      //                   .readdata
		.readdatavalid (readdatavalid)  //                   .readdatavalid
	);

endmodule
