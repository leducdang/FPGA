module top(
				clock_50mhz,
				pin_reset,
				pin_sw_addr,
				pin_sw_data,
				pin_led_odata,
				pin_read,
				pin_write,
				
				SRAM_DQ,
				SRAM_ADDR,
				SRAM_LB_N,
				SRAM_UB_N,
				SRAM_CE_N,
				SRAM_OE_N,
				SRAM_WE_N
				);
				
//**************** PORT MAIN **************//

input 			clock_50mhz;
input 			pin_reset;
input  [1:0] 	pin_sw_addr;
input	 [15:0]	pin_sw_data;
output [15:0]	pin_led_odata;			
input 			pin_read;
input				pin_write;				
				
//**************** PORT SRAM **************//

reg 	[19:0] 	address;       //  avalon_sram_slave.address
reg 	[1:0]  	byteenable;    //                   .byteenable
reg        		read;          //                   .read
reg        		write;         //                   .write
reg  	[15:0] 	writedata;     //                   .writedata
wire 	[15:0]	readdata;      //                   .readdata
wire        	readdatavalid; //                   .readdatavalid
wire        	clk_sram;           //                clk.clk

inout  wire [15:0] SRAM_DQ;       // external_interface.DQ
output wire [19:0] SRAM_ADDR;     //                   .ADDR
output wire        SRAM_LB_N;     //                   .LB_N
output wire        SRAM_UB_N;     //                   .UB_N
output wire        SRAM_CE_N;     //                   .CE_N
output wire        SRAM_OE_N;     //                   .OE_N
output wire        SRAM_WE_N;     //                   .WE_N



//**************** PROGRAM ***************//

always@(posedge clock_50mhz or negedge pin_reset)
begin
	if(!pin_reset)
		begin
			read 	<= 1'b0;
			write <= 1'b0;
			byteenable <= 2'b00;
		end
	else
		begin
			if(!pin_read)
				begin
					read 	<= 1'b1;
					byteenable <= 2'b11;
				end
			else if(!pin_write)
				begin
					write <= 1'b1;
					byteenable 	<= 2'b11;
					writedata 	<= pin_sw_data;
				end
			else
				begin
					read 	<= 1'b0;
					write <= 1'b0;
					byteenable 	<= 2'b00;
				end
				
			case(pin_sw_addr)
				2'b00:	address <= 20'd0; 
				2'b01:	address <= 20'd1;
				2'b10:	address <= 20'd2;
				2'b11:	address <= 20'd3;
			endcase
		end
end

IP_SRAM u1(
				.address(address),       //  avalon_sram_slave.address
				.byteenable(byteenable),    //                   .byteenable
		      .read(read),          //                   .read
		      .write(write),         //                   .write
				.writedata(writedata),     //                   .writedata
				.readdata(readdata),      //                   .readdata
		      .readdatavalid(readdatavalid), //                   .readdatavalid
		      .clk(clock_50mhz),           //                clk.clk
				.SRAM_DQ(SRAM_DQ),       // external_interface.DQ
				.SRAM_ADDR(SRAM_ADDR),     //                   .ADDR
		      .SRAM_LB_N(SRAM_LB_N),     //                   .LB_N
		      .SRAM_UB_N(SRAM_UB_N),     //                   .UB_N
		      .SRAM_CE_N(SRAM_CE_N),     //                   .CE_N
		      .SRAM_OE_N(SRAM_OE_N),     //                   .OE_N
		      .SRAM_WE_N(SRAM_WE_N),     //                   .WE_N
		      .reset(pin_reset)          //              reset.reset
	);


assign pin_led_odata = readdata;
				
				
endmodule