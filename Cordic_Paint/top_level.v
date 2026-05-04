module top_level(
						clock_50mhz,
						reset,
						phase,
						sin,
						cos,
						
						//vga
						pin_r,
						pin_g,
						pin_b,
						pin_vga_clock,
						pin_sync,
						pin_bank,
						pin_hs,
						pin_vs,
						
						//sdram
						SDRAM_addr,    //     sdram.addr
						SDRAM_ba,      //          .ba
						SDRAM_cas_n,   //          .cas_n
						SDRAM_cke,     //          .cke
						SDRAM_cs_n,    //          .cs_n
						SDRAM_dq,      //          .dq
						SDRAM_dqm,     //          .dqm
						SDRAM_ras_n,   //          .ras_n
						SDRAM_we_n,    //          .we_n
						SDRAM_clk_clk,  // sdram_clk.clk
						
						key3,
						key2,
						LEDR17
);

input				clock_50mhz;
input 			reset;
input	signed [9:0]	phase;
output [7:0]	sin;
output [7:0]	cos;
reg [9:0]	phase_input;


// VGA

output [7:0] 	pin_r;
output [7:0] 	pin_g;
output [7:0] 	pin_b;
output			pin_vga_clock;
output			pin_sync;
output			pin_bank;
output			pin_hs;
output			pin_vs;

reg [7:0] data_r;
reg [7:0] data_g;
reg [7:0] data_b;
wire 		 clock_vga;
wire [10:0] oCurrent_X;
wire [10:0]	oCurrent_Y;
wire [18:0] oAddress;

reg clock;

// SDRAM


output  [12:0] SDRAM_addr;    //     sdram.addr
output  [1:0]  SDRAM_ba;      //          .ba
output         SDRAM_cas_n;   //          .cas_n
output         SDRAM_cke;     //          .cke
output         SDRAM_cs_n;    //          .cs_n
inout   [31:0] SDRAM_dq;      //          .dq
output  [3:0]  SDRAM_dqm;     //          .dqm
output         SDRAM_ras_n;   //          .ras_n
output         SDRAM_we_n;    //          .we_n
output         SDRAM_clk_clk;  // sdram_clk.clk

reg [24:0] 	SDRAM_1_address;       //   sdram_1.address
reg [3:0]  	SDRAM_1_byteenable_n = 4'b0000;  //          .byteenable_n
reg        	SDRAM_1_chipselect = 1'b1;    //          .chipselect
reg [31:0] 	SDRAM_1_writedata;     //          .writedata
reg         SDRAM_1_read_n;        //          .read_n
reg        	SDRAM_1_write_n;       //          .write_n
wire [31:0] SDRAM_1_readdata;      //          .readdata
wire        SDRAM_1_readdatavalid; //          .readdatavalid
wire        SDRAM_1_waitrequest;   //          .waitrequest   =1 sdram dang xu ly, = 0 duoc phep ghi lenh

reg [2:0]	byteRW;					  //	= 0 Write, =1 Read
reg [31:0]	dataRead;

// Fifo dual clock

reg [7:0] 	data_a;
reg [7:0] 	data_b_ram;
reg [18:0]	addr_a;
reg [18:0]	addr_b;
reg			we_a = 1; 		//= 1 write, 0 read
reg			we_b = 0; 		//= 1 write, 0 read
wire	[7:0]	q_a;
wire	[7:0] q_b;


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

/************************************************/


// input key0 = 0  enable write SDRAM
input key3;       // write data sdram
input key2;			// read data sdram
output LEDR17;


reg [3:0] fsm;
reg done_write;

wire clock_100mhz;
reg	[9:0] pointX;
reg 	[9:0]	pointY;

reg	[9:0] max_X;
reg 	[9:0]	max_Y;
reg 	[9:0]	min_X;
reg 	[9:0]	min_Y;

reg	[24:0] counter;
reg	[25:0] counter1;
reg 	clock_1s;
reg 	stt = 0; 

//////////////////////////////////////////////////////////////////////////////////////////
always@( posedge clock_50mhz)
begin
	if(counter < 5000000) counter <= counter +1;
		else
			begin
				counter <= 0;
				clock_1s <= ~clock_1s;
//				byteRW <= 1;
			end	
end


always@( negedge reset or posedge clock_1s)
begin
	if(!reset)
		begin
			max_X <= 40;
			max_Y <= 40;
			min_X <= 0;
			min_Y <= 0;
			
		end
	else
		begin
			min_X <= min_X+10;
			if(min_X > 600)
				begin
					min_X <=0;
					min_Y <= min_Y + 10;
				end
			if(min_Y>440)
				begin
					min_Y <= 0;
				end
			max_X <= min_X + 40;
			max_Y <= min_Y + 40;
			stt <= 1;
		end
end

always@( posedge clock_50mhz or negedge reset or negedge key2 or negedge key3)
begin
	if(!reset)
		begin
			byteRW <= 0;
			done_write <= 0;
//			fsm <= 0;
		end
	else if(!key3) 
		begin 
			byteRW <= 1;
		end
	else if(!key2)
		begin
			byteRW <= 2;
		end
	else
		begin			
		case(byteRW)
			2'd0: 
				begin
					SDRAM_1_read_n <= 1;        //          .read_n
					SDRAM_1_write_n <= 1;
					SDRAM_1_address <= 0;
					pointX <= 0;
					pointY <= 0;
					byteRW <= 1;
				end
			2'd1:
				begin
					SDRAM_1_read_n <= 1;        //          .read_n
					if(!SDRAM_1_waitrequest)
						begin
							SDRAM_1_write_n <= 0;
							
							if(pointX <640) pointX <= pointX+1;
							else 
								begin
									pointX <= 0;
									if(pointY <480)pointY <= pointY+1;
									else pointY <= 0;		
								end
							
							if((pointX >min_X) && (pointX<max_X) && (pointY>min_Y) && (pointY<max_Y))
//							if((pointX >299) && (pointX<341) && (pointY>219) && (pointY<261))
								begin
									SDRAM_1_writedata <= 8'hff;	
								end
							else
								begin
									SDRAM_1_writedata <= 16'hff00;
								end
								
//							SDRAM_1_address <= SDRAM_1_address+1;
							SDRAM_1_address <= 640*pointY + pointX;
						end
						
					if(SDRAM_1_address > (640*480-1))
						begin
							done_write <= 1;
							byteRW <= 2;
							SDRAM_1_address <= 0;
						end
				end
					
//			2'd2:
//				begin
//					SDRAM_1_write_n <= 1;
//					
//					if(!SDRAM_1_waitrequest)
//						begin
//							SDRAM_1_read_n <= 0;        //          .read_n
//							addr_a <= SDRAM_1_address;
//							data_a <= SDRAM_1_readdata[7:0];
//							if(SDRAM_1_readdatavalid)
//								begin
//									SDRAM_1_address <= SDRAM_1_address + 1;
//									if(SDRAM_1_address > 307000)
//										begin
//											byteRW <= 0;
//											SDRAM_1_address <= 0;
//											done_write <= 1;
//										end
//								end
//						end
//				end
			
			2'd2:
				begin
					SDRAM_1_write_n <= 1;
					if(!SDRAM_1_waitrequest)
						begin
							SDRAM_1_read_n <= 0;
							if(SDRAM_1_readdatavalid)
								begin
									data_r <= SDRAM_1_readdata[7:0];
									SDRAM_1_address <= oAddress;
									if(oAddress == (640*480-1))
										byteRW <= 0;
								end
						end
				end
			

		endcase
		end
end





assign LEDR17 = done_write;
//assign data_r = {q_b,5'b00000};
assign cos = counter1[7:0];


always@(posedge clock_50mhz)
begin
	clock <= ~clock;
end

//always@(posedge clock_50mhz)
//begin
//	phase_input <= phase*2234/1000;                         //2.234
//end


true_dual_port_ram_dual_clock u3
(
	 .data_a(data_a), 
	 .data_b(data_b_ram),
	 .addr_a(addr_a), 
	 .addr_b(oAddress),
	 .we_a(we_a), 
	 .we_b(we_b), 
	 .clk_a(clock_100mhz), 
	 .clk_b(clock),
	 .q_a(q_a), 
	 .q_b(q_b)
);


ip_cordic u0 (
      .a      (phase_input),      //      a.a
      .areset (reset), // areset.reset
//      .c      (cos),      //      c.c
      .clk    (clock_50mhz),    //    clk.clk
      .s      (sin)       //      s.s
);


ip_pll u2(
		.inclk0(clock_50mhz),
		.c0(clock_vga),
		.c1(clock_100mhz)
	);



VGA_Ctrl	vga(	//	Host Side
				.iRed(data_r),
				.iGreen(data_g),
				.iBlue(data_b),
				.oCurrent_X(oCurrent_X),
				.oCurrent_Y(oCurrent_Y),
				.oAddress(oAddress),
//				oRequest,
				//	VGA Side
				.oVGA_R(pin_r),
				.oVGA_G(pin_g),
				.oVGA_B(pin_b),
				.oVGA_HS(pin_hs),
				.oVGA_VS(pin_vs),
				.oVGA_SYNC(pin_sync),
				.oVGA_BLANK(pin_bank),
				.oVGA_CLOCK(pin_vga_clock),
				//	Control Signal
				.iCLK(clock),
				.iRST_N(reset)	
				);
	

ip_sdram u1 (
        .clk_clk               (clock_50mhz),               //       clk.clk
        .reset_reset_n          (reset),           //     reset.reset
        .sdram_1_address       (SDRAM_1_address),       //   sdram_1.address
        .sdram_1_byteenable_n  (SDRAM_1_byteenable_n),  //          .byteenable_n
        .sdram_1_chipselect    (SDRAM_1_chipselect),    //          .chipselect
        .sdram_1_writedata     (SDRAM_1_writedata),     //          .writedata
        .sdram_1_read_n        (SDRAM_1_read_n),        //          .read_n
        .sdram_1_write_n       (SDRAM_1_write_n),       //          .write_n
        .sdram_1_readdata      (SDRAM_1_readdata),      //          .readdata
        .sdram_1_readdatavalid (SDRAM_1_readdatavalid), //          .readdatavalid
        .sdram_1_waitrequest   (SDRAM_1_waitrequest),   //          .waitrequest
        .sdram_clk_clk         (SDRAM_clk_clk),         // sdram_clk.clk
        .wire_addr             (SDRAM_addr),             //      wire.addr
        .wire_ba               (SDRAM_ba),               //          .ba
        .wire_cas_n            (SDRAM_cas_n),            //          .cas_n
        .wire_cke              (SDRAM_cke),              //          .cke
        .wire_cs_n             (SDRAM_cs_n),             //          .cs_n
        .wire_dq               (SDRAM_dq),               //          .dq
        .wire_dqm              (SDRAM_dqm),              //          .dqm
        .wire_ras_n            (SDRAM_ras_n),            //          .ras_n
        .wire_we_n             (SDRAM_we_n)              //          .we_n
    );

	
    Sram u0 (
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
		      .reset(reset)          //              reset.reset
    );
	

endmodule

