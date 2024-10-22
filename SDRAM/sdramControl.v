module sdramControl(
		input          clk_50mhz,       //       clk.clk
		input          reset,   //     reset.reset
		output  [12:0] SDRAM_addr,    //     sdram.addr
		output  [1:0]  SDRAM_ba,      //          .ba
		output         SDRAM_cas_n,   //          .cas_n
		output         SDRAM_cke,     //          .cke
		output         SDRAM_cs_n,    //          .cs_n
		inout   [31:0] SDRAM_dq,      //          .dq
		output  [3:0]  SDRAM_dqm,     //          .dqm
		output         SDRAM_ras_n,   //          .ras_n
		output         SDRAM_we_n,    //          .we_n
		output         SDRAM_clk_clk,  // sdram_clk.clk
		
		//data port in_out
		input 		[15:0] sw_data,
		output		[15:0] led,
		input 				 button_write,
		input					 button_read,
		output		[7:0]	 led_addr,
		input					 button_addr
);

reg [24:0] 	SDRAM_1_address;       //   sdram_1.address
reg [3:0]  	SDRAM_1_byteenable_n = 4'b0000;  //          .byteenable_n
reg        	SDRAM_1_chipselect = 1'b1;    //          .chipselect
reg [31:0] 	SDRAM_1_writedata;     //          .writedata
reg        SDRAM_1_read_n;        //          .read_n
reg        	SDRAM_1_write_n;       //          .write_n
wire [31:0] SDRAM_1_readdata;      //          .readdata
wire        SDRAM_1_readdatavalid; //          .readdatavalid
wire        SDRAM_1_waitrequest;   //          .waitrequest

reg [1:0]	byteRW;					  //	= 0 Write, =1 Read
reg [31:0]	dataRead;

always @(negedge button_addr or negedge reset)
begin
	if(!reset) begin SDRAM_1_address <=0; end
	else
	SDRAM_1_address <= SDRAM_1_address + 1;
end

always @(posedge clk_50mhz or negedge reset or negedge button_write or negedge button_read )
begin
	if(!reset)
		begin
			byteRW <= 2'd2;
		end

	if(!button_write) byteRW <= 0;
	if(!button_read)  byteRW  <= 1;
	
	case (byteRW)
		2'd0: begin
					if (SDRAM_1_waitrequest == 0)
						begin
							SDRAM_1_write_n<= 0;
							SDRAM_1_read_n<= 1;
						end
					SDRAM_1_writedata <= sw_data;
				end
		2'd1: begin
					SDRAM_1_write_n<=1;
					if (SDRAM_1_waitrequest == 0) SDRAM_1_read_n<= 0;
					dataRead	<= SDRAM_1_readdata;		
				end
		2'd2: begin
					if (SDRAM_1_waitrequest == 0)
						begin
							SDRAM_1_write_n <= 1;
							SDRAM_1_read_n <= 1;
						end
				end	
	endcase
end
		
assign led = dataRead[15:0];
assign led_addr = SDRAM_1_address[7:0];

 sdram u0 (
        .wire_addr             (SDRAM_addr),             //      wire.addr
        .wire_ba               (SDRAM_ba),               //          .ba
        .wire_cas_n            (SDRAM_cas_n),            //          .cas_n
        .wire_cke              (SDRAM_cke),              //          .cke
        .wire_cs_n             (SDRAM_cs_n),             //          .cs_n
        .wire_dq               (SDRAM_dq),               //          .dq
        .wire_dqm              (SDRAM_dqm),              //          .dqm
        .wire_ras_n            (SDRAM_ras_n),            //          .ras_n
        .wire_we_n             (SDRAM_we_n),             //          .we_n
        .sdram_clk_clk         (SDRAM_clk_clk),         // sdram_clk.clk
        .clk_clk               (clk_50mhz),               //       clk.clk
        .reset_reset           (reset),           //     reset.reset
        .sdram_1_address       (SDRAM_1_address),       //   sdram_1.address
        .sdram_1_byteenable_n  (SDRAM_1_byteenable_n),  //          .byteenable_n
        .sdram_1_chipselect    (SDRAM_1_chipselect),    //          .chipselect
        .sdram_1_writedata     (SDRAM_1_writedata),     //          .writedata
        .sdram_1_read_n        (SDRAM_1_read_n),        //          .read_n
        .sdram_1_write_n       (SDRAM_1_write_n),       //          .write_n
        .sdram_1_readdata      (SDRAM_1_readdata),      //          .readdata
        .sdram_1_readdatavalid (SDRAM_1_readdatavalid), //          .readdatavalid
        .sdram_1_waitrequest   (SDRAM_1_waitrequest)    //          .waitrequest
    );

endmodule 
