module top(
				clock_50mhz,
				data_in,
				pin_data_out,
				wr_en,
				rd_en,
				pin_out_empty,
				pin_out_full,
				pin_out_usedw
				);
				
input 			clock_50mhz;
input 	[7:0]	data_in;
output	[7:0]	pin_data_out;
input 			wr_en;
input 			rd_en;
output			pin_out_empty;
output			pin_out_full;
output	[7:0]	pin_out_usedw;

reg 	read_en;
reg	write_en;
wire	pin_empty;
wire	pin_full;
wire 	[7:0] data_out;
wire	[7:0] usedw;
reg	stt_wire;
reg	stt_read;
reg 	clock;
reg	[23:0] count;


always@(posedge clock_50mhz)
begin
	if(count == 24'd12499999)
		begin
			count <= 0;
			clock <= ~clock;
		end
	else
		count <= count + 1;
end

always@(posedge clock_50mhz or negedge wr_en)
begin
		if(!wr_en)
			begin
			if(stt_wire == 0)	begin write_en <= 1'b1; stt_wire <= 1;	end
			end
		else if(wr_en)
		begin 
		write_en <= 1'b0;
		stt_wire <= 0;
		end
end

always@(posedge clock_50mhz or negedge rd_en)
begin
		if(!rd_en)
			begin
				if (stt_read == 0)	begin read_en <= 1'b1;	stt_read <= 1;	end
			end
		else if (rd_en)
		begin
		read_en <= 1'b0;
		stt_read <= 0;
		end
end

fifo u0(
	.clock(clock),
	.data(data_in),
	.rdreq(read_en),
	.wrreq(write_en),
	.empty(pin_empty),
	.full(pin_full),
	.q(data_out),
	.usedw(usedw)
	);
	
assign	pin_data_out = data_out;
assign 	pin_out_empty = pin_empty;
assign 	pin_out_full = pin_full;	
assign	pin_out_usedw = usedw;
endmodule