module topSRAM(clock_200mhz, 		
					pinData,
					pinAddr,
					pinCE,
					pinOE,
					pinWE,
					pinUB,
					pinLB,
					bit_Read,
					bit_Write,
					pinReset,
					addr,
					i_data,
					o_data
					);

input				clock_200mhz;		//	xung vao
inout	[15:0]	pinData;				//	pin data
output[19:0]	pinAddr;				//	pin dia chi
output 			pinCE;				// pin chọn chip = 0 cho phép chip hoạt động, = 1 ko hoat dong
output			pinOE;				// Output Enable = 0 cho phép xuất data, =1 ko cho phép
output			pinWE;				// Write Enable  = 0 cho phép ghi dữ liệu, = 1 không cho phép
output			pinUB;				// upper byte	  = 0 cho phép ghi 8 bit cao
output			pinLB;				// Lower byte	  = 0 cho phép ghi 8 bit thấp
input				bit_Read;			// chan dieu khien chuong trinh doc du lieu
input				bit_Write;			// chan dieu khien chương trinh ghi du lieu
input 			pinReset;			// chan dieu khien reset chuong trinh
input [19:0]	addr;		
input	[15:0]	i_data;
output	[15:0]	o_data;

// cac bien phu
reg 	[15:0]	dataWrite;			// bien du lieu ghi xuong SRAM
reg	[15:0]	dataRead;			// bien data Read duoc
reg	[3:0]		sttWrite;			// trang thai Ghi
reg	[3:0]		sttRead;				// trang thai doc
reg				OE;					//	bien trang thai cho phep xuất tin hieu de gan vao chan OE
reg				CE;					// bien trang thai cho phep chon chip de gan vao chan CE
reg				WE;					// bien trang thai cho phep ghi du lieu de gan vao chan WE
reg				UB;					// bien trang thai UB dieu khien 8 bit cao, de gan vao chan UB
reg				LB;					// bien trang thai LB dieu khien 8 bit thap de gan vao chan LB

// RUN PROGRAM 

always@(posedge clock_200mhz or negedge pinReset)
begin
	if(!pinReset) begin sttWrite <= 4; sttRead <= 5; UB<=1; LB<=1; 	CE <= 1; OE <= 1; WE <= 1; end 
	else
		begin
			
			// GHI GIA TRI VAO SRAM
			
			if(sttWrite == 4 && bit_Write == 1) sttWrite <= 0;							// chan dieu khien pinWrite duoc nhan se băt dau ghi du lieu vao Sram
			case(sttWrite)														
			4'd0:	begin dataWrite <= i_data;  sttWrite <= 1; end						//	gan du lieu duoc ghi tu switch vao bien lưu data
			4'd1:	begin CE<=0; WE <= 0; sttWrite <= 2; UB<=0; LB<=0; end			// keo chan CE, WE, UB, LB xuong 0 de cho phep ghi du lieu
			4'd2:	sttWrite <= 3;																	// delay 1 chu ky xung
			4'd3: begin sttWrite <= 4; CE<= 1; WE <= 1; UB<=1; LB<=1; end			// keo chan CE, WE, UB, LB lên 1 de ket thuc qua trinh ghi du lieu
			endcase
	
			// DOC GIA TRI TU SRAM
			
			if(sttRead == 5 && bit_Read == 1) sttRead <= 0;								// kiểm tra chan dieu khien pinRead = 0 de bat dau quá trình doc dữ liệu
			case(sttRead)
			4'd0:	begin sttRead <= 1;  dataWrite <= 16'bzzzzzzzzzzzzzzzz; end		// đưa các chân data ve trang thai tro treo, cho phep nhan du lieu
			4'd1:	begin CE<=0; OE <= 0; UB<=0; LB<=0; sttRead <= 2; end				// keo chan CE, OE, UB, LB, xuong 0 de cho phep doc du lieu
			4'd2:	begin dataRead  <= pinData;		sttRead <= 3; end					// doc du lieu tai chan data, gan vao bien du lieu doc duoc
			4'd3:	sttRead <= 4;
			4'd4: begin sttRead <= 5; CE<= 1; OE <= 1; UB<=1; LB<=1;  end			// keo chan CE, OE, UB, LB len muc 1 ket thuc qua trinh ghi du lieu
			endcase
				
		end
	
end

// gan trang thai dau ra cho phan cung

assign pinData = dataWrite;
assign pinAddr = addr;		
assign pinCE = CE;
assign pinOE = OE;
assign pinWE = WE;
assign pinUB = UB;
assign pinLB = LB;
assign o_data = dataRead;	
					
endmodule