module top(clock_50mhz,
				pin_addr,
				pin_dataOut,
				pin_write,
				pin_dataIn,
				);

				
input clock_50mhz;						// DAU VAO XUNG CLOCK
input	[7:0]	pin_addr;					// DAU VAO DIA CHI
input	pin_write;							// CHON CHE DO DOC, GHI - 0 DOC 1 GHI
input [7:0]	pin_dataIn;					//	DU LIEU DAU VAO 
output	[7:0]	pin_dataOut;			// DAU RA DU LIEU		
				
wire [7:0]	data_out;					// BIEN DU LIEU DAU RA


// KHOI TAO MODULE CON

ram1	u1(
			.address(pin_addr),			// Dia chi
			.clock(clock_50mhz),			// xung clock
			.data(pin_dataIn),			// Data in
			.wren(pin_write),				// chan dieu khien - 0 doc 1 ghi
			.q(data_out)					// dau ra du lieu
			);			
				
				
assign pin_dataOut = data_out;		// GAN CHAN DATA OUT VOI BIEN DAU RA			

					
endmodule			
				
/*				
module ram1 (
	address,
	clock,
	data,
	wren,
	q);
*/