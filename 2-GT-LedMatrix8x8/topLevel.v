module topLevel(
						input 	clock_50mhz,
						output reg [7:0] row,
						output reg	[7:0] col
	
);

reg 	[3:0] stt;
reg	[14:0] counter;
reg	[7:0]	data_col[10:0];
reg clock;

initial 
	begin 

		data_col[0] = 8'hFF;
		data_col[1] = 8'h99;
		data_col[2] = 8'h66;
		data_col[3] = 8'h7E;
		data_col[4] = 8'hBD;
		data_col[5] = 8'hDB;
		data_col[6] = 8'hE7;
		data_col[7] = 8'hFF;

//============ HINH MAT CUOI ============
		
//		data_col[0] = ~8'b00111100;
//		data_col[1] = ~8'b01000010;
//		data_col[2] = ~8'b10100101;
//		data_col[3] = ~8'b10000001;
//		data_col[4] = ~8'b10100101;
//		data_col[5] = ~8'b10011001;
//		data_col[6] = ~8'b01000010;
//		data_col[7] = ~8'b00111100;
	end

//===========================================
//=============== CLOCK 1Khz ================
//===========================================

	
always@ (posedge clock_50mhz)
begin
	if(counter == 15'd25000)
		begin
			clock <= ~clock;
			counter <= 0;
		end
	else
		counter <= counter + 1;

end	
	
//===========================================
//=============== QUET LED ==================
//===========================================
	
always@ (posedge clock)	
	begin
		if(stt < 8)
			begin
				col <= data_col[stt];
				row <= (8'h01 << stt);
				stt <= stt + 1;
			end
		else
			begin
				stt <= 0;
				col <= 8'hff;
			end
	end
	
endmodule


