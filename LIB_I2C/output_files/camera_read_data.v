module camera_read_data(clock_pclk,
								vs,
								href,
								data,
								o_data,
								flag,
								pin_reset,
								o_row,
								o_col
								);

input 	clock_pclk;
input 	vs;
input 	href;
input 	[7:0] data;
output 	[15:0] o_data;
output 	flag;
input 	pin_reset;
output 	[8:0]	o_row;
output	[9:0]	o_col;

reg				flag_o_data;
reg	[9:0]  	counter_col;
reg	[8:0]		counter_row;
reg				stt_byte;
reg 	[15:0] 	o_data_2_byte;

assign o_data 	= 	o_data_2_byte;
assign flag 	=	flag_o_data;
assign o_row	= 	counter_row;
assign o_col	= 	counter_col;
 


always@(negedge clock_pclk or negedge pin_reset)
begin
	if(!pin_reset)
		begin
			counter_col 	<= 0;
			//counter_row 	<= 0;
			flag_o_data		<= 0;
		end
	else
		begin
			if(!vs && counter_row < 9'd480)
				begin
					if(href && counter_col < 10'd640 )
						begin
							if(stt_byte == 0)
								begin
									o_data_2_byte[15:8] <= data;
									stt_byte <= 1;
									flag_o_data <= 0;
								end
							else
								begin
									o_data_2_byte[7:0] <= data;
									stt_byte <= 0;
									flag_o_data <= 1;
									counter_col <= counter_col + 1;
								end
						end
					else
						begin
							counter_col <= 0;
							flag_o_data <= 0;
							counter_row <= counter_row + 1;
						end
				end
			else
				begin
					counter_row <= 0;
				end
		end
end
								


								
endmodule