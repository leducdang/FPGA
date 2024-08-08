module i2c(
				clock_100Khz,			// xung cấp cho i2c
				i_sda,
				i_scl,
				i_addr_ic,
				i_addr_reg,
				i_data_wr,
				o_data_read,
				i_wr_en,					// = 1 write, 0 read
				o_flag_w,					// = 1 done write data, 0 - wait write
				o_flag_r,					// = 1 done read, 0 - wait read
				i_en_I2C,						// 1 cho phép i2c hoạt động, 0 dừng
				i_reset
				);
				
input				clock_100Khz;			// xung cấp cho i2c
inout				i_sda;
input				i_scl;
input 	[6:0]	i_addr_ic;
input		[7:0]	i_addr_reg;
input		[7:0]	i_data_wr;
output	[7:0]	o_data_read;
input				i_wr_en;			// = 1 write, 0 read
output			o_flag_w;					// = 1 done write data, 0 - wait write
output			o_flag_r;	
input 			i_en_I2C;
input				i_reset;


reg 		[6:0] counter_i2c;

always @(posedge clock_100Khz)
begin
	case (counter_i2c)
		7'd0: 
end		

				
				
				
				
endmodule