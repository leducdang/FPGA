module sdram_controller(	clock_50mhz,
									pin_DQ,
									pin_DQM0,
									pin_DQM1,
									pin_DQM2,
									pin_DQM3,
									pin_CKE,
									pin_CLK,
									pin_WE_N,
									pin_CAS_N,
									pin_RAS_N,
									pin_CS_N,
									pin_BA,
									pin_ADDR,
									
									pin_reset,
									pin_read,
									pin_write,
									pin_led,
									pin_sw
								);

									
input					clock_50mhz;
inout		[31:0]	pin_DQ;
output				pin_DQM0;
output				pin_DQM1;
output				pin_DQM2;
output				pin_DQM3;
output				pin_CKE;
output				pin_CLK;
output				pin_WE_N;
output				pin_CAS_N;
output				pin_RAS_N;
output				pin_CS_N;
output	[1:0]		pin_BA;
output	[12:0]	pin_ADDR;
output	[31:0]	pin_led;
									
input					pin_reset;
input					pin_read;
input					pin_write;
input		[1:0] 	pin_sw;

reg	[31:0]		dataWrite;
reg	[31:0]		dataRead;
reg					DQM0;
reg					DQM1;
reg					DQM2;
reg					DQM3;
reg					CKE;
reg					CLK;
reg					WE_N;
reg					CAS_N;
reg					RAS_N;
reg					CS_N;
reg	[1:0]			BA;
reg	[12:0]		ADDR;

reg	[3:0]			STT_READ;
reg	[3:0]			STT_WRITE;
//reg	[31:0]		DQ_PIN;



always@(posedge clock_50mhz or negedge pin_reset)
begin
	if(!pin_reset)	begin 
							STT_READ <= 4'd8;
							STT_WRITE<=4'd8;
							CS_N 	<= 0;
							RAS_N <= 1;
							CAS_N <= 1;
							WE_N	<= 1;
							dataWrite <= 32'bzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz;	
						end
	else if(STT_WRITE <= 8 && pin_write == 0) begin STT_WRITE <= 4'd0;  end
	else if(STT_READ <= 8 && pin_read == 0) 	begin STT_READ <= 4'd0;   end
	else
	begin
	case(STT_WRITE)
		4'd0:	begin
					CKE <= 1;
					CS_N 	<= 0;
					RAS_N <= 0;
					CAS_N <= 1;
					WE_N	<= 1;
					//ADDR <= 13'b0010000000001;
					//ADDR[10:10]<=1;
					BA		<= 2'b00;
					STT_WRITE <= 4'd1;
				end
		4'd1: begin CS_N 	<= 0;  RAS_N <= 1; CAS_N <= 1; WE_N	<= 1; STT_WRITE <= 4'd2;  end

		
		//	write data
		
		4'd2:	begin 
					CS_N 	<= 0;
					RAS_N <= 1;
					CAS_N <= 0;
					WE_N	<= 0;
					BA		<= 2'b00;
					//ADDR  <= 13'b0010000000001;
					//ADDR[10:10]<=1;
					DQM0 	<= 0;
					DQM1 	<= 0;
					DQM2 	<= 0;
					DQM3 	<= 0;
					//ADDR[10:10]	<=0;
					dataWrite <=32'b00001111000011110000111100001111;
					STT_WRITE <= 4'd3;
				end
		4'd3:	begin
					STT_WRITE <= 4'd4;
					CS_N 	<= 0;
					RAS_N <= 1;
					CAS_N <= 1;
					WE_N	<= 1;
				end
		4'd4:	begin
					CS_N 	<= 0;
					RAS_N <= 1;
					CAS_N <= 1;
					WE_N	<= 1;
					STT_WRITE <= 4'd5;
				end
				
		4'd5:	begin
					CS_N 	<= 0;
					RAS_N <= 0;
					CAS_N <= 1;
					WE_N	<= 0;
					DQM0 	<= 1;
					DQM1 	<= 1;
					DQM2 	<= 1;
					DQM3 	<= 1;
					BA		<= 2'b00;
					//ADDR[10:10]	<=0;
					STT_WRITE 	<= 4'd6;
				end
		4'd6:	begin
					CS_N 	<= 0;
					RAS_N <= 1;
					CAS_N <= 1;
					WE_N	<= 1;
					STT_WRITE <= 4'd7;
				end
		4'd7:	begin
				CS_N 	<= 0;
				RAS_N <= 1;
				CAS_N <= 1;
				WE_N	<= 1;
				STT_WRITE <= 4'd8;
				//dataWrite <= 32'bzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz;
				end
	endcase
	
	
	
	
	
	///////////////////////////////////////////////////////////////////////////////////////////////
	
	case(STT_READ)
		4'd0:	begin
					CKE <= 1;
					CS_N 	<= 0;
					RAS_N <= 0;
					CAS_N <= 1;
					WE_N	<= 1;
					//ADDR  <= 13'b0010000000001;
					//ADDR[10:10]<=1;
					BA		<= 2'b00;
					STT_READ <= 4'd1;
					dataWrite <= 32'bzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz;
				end
		4'd1: begin CS_N 	<= 0;  RAS_N <= 1; CAS_N <= 1; WE_N	<= 1; STT_READ <= 4'd2; BA<= 2'b00; end

		
		//	READ DATA
		
		4'd2:	begin 
					CS_N 	<= 0;
					RAS_N <= 1;
					CAS_N <= 0;
					WE_N	<= 1;
					BA		<= 2'b00;
					//ADDR  <= 13'b0010000000001;
					//ADDR[10:10]<=1'b0;
					DQM0 	<= 0;
					DQM1 	<= 0;
					DQM2 	<= 0;
					DQM3 	<= 0;
					//dataWrite <=32'b00001111000011110000111100001111;
					STT_READ <= 4'd3;
				end
		4'd3:	begin
					CS_N 	<= 0;
					RAS_N <= 1;
					CAS_N <= 1;
					WE_N	<= 1;
					STT_READ <= 4'd4;
				end
		4'd4:	begin
					CS_N 	<= 0;
					RAS_N <= 1;
					CAS_N <= 1;
					WE_N	<= 1;
					STT_READ <= 4'd5;
					dataRead <= pin_DQ;
				end
		4'd5:	begin
					CS_N 	<= 0;
					RAS_N <= 0;
					CAS_N <= 1;
					WE_N	<= 0;
					DQM0 	<= 1;
					DQM1 	<= 1;
					DQM2 	<= 1;
					DQM3 	<= 1;
					STT_READ <= 4'd6;
					BA		<= 2'b00;
					//ADDR[10:10]<=1'b0;
				end
		4'd6:	begin 
					CS_N 	<= 0;
					RAS_N <= 1;
					CAS_N <= 1;
					WE_N	<= 1;
					STT_READ <= 4'd7;	
				end
					
		4'd7:	STT_READ <= 4'd8;
	endcase
	end	
end



always@(posedge clock_50mhz)
begin
			case(pin_sw)				// kiem tra cac dau vao chan dia chi
				2'b00: ADDR <= 13'b0000000000001;		// gan dia chi neu 2 chan == 00
				2'b01: ADDR <= 13'b0000000000010;		// gan dia chi neu 2 chan == 01
				2'b10: ADDR <= 13'b0000000000011;		// gan dia chi neu 2 chan == 10
				2'b11: ADDR <= 13'b0000000000100;		// gan dia chi neu 2 chan == 11
			endcase
end

assign	pin_DQ = dataWrite ;
assign	pin_DQM0 = DQM0;
assign	pin_DQM1 = DQM1;
assign	pin_DQM2 = DQM2;
assign	pin_DQM3 = DQM3;
assign	pin_CKE  = CKE;
assign	pin_CLK	= clock_50mhz;
assign	pin_WE_N = WE_N;
assign	pin_CAS_N= CAS_N;
assign	pin_RAS_N= RAS_N;
assign	pin_CS_N = CS_N;
assign	pin_BA	= BA;
assign	pin_ADDR = ADDR;
assign	pin_led	= dataRead;					




endmodule