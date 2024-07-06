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
									pin_write
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
									
input					pin_reset;
input					pin_read;
input					pin_writ;

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
reg	[]







endmodule