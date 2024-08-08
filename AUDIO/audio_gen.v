module audio_gen( clock_12Mhz,
						//audio_bk,
						audio_dalr,
						audio_datat,
						audio_data_in
);

input 		clock_12Mhz;
//output		audio_bk;
output		audio_dalr;
output		audio_datat;
input		[31:0]	audio_data_in;

reg [7:0]   audio_prs;
reg 			clk_en;
reg [31:0]  da_data_out;  //bien data coppy du lieu vao de chuyen thanh data ra
reg 			sample_flag;
reg [5:0] 	data_index;
reg 			audio_data;


always@(negedge clock_12Mhz)
begin
	
	if(audio_prs < 250)
		begin
			audio_prs <= audio_prs+1;
			clk_en 	 <= 0;
		end
	else
		begin
			audio_prs <= 0;
			da_data_out <= audio_data_in;
			clk_en 	 <= 1;
		end
	
	if(clk_en == 1)
		begin
			sample_flag <= 1;
			data_index <= 31;
		end	
	
	if(sample_flag == 1)
		begin
			if(data_index > 0)
				begin
					audio_data <= da_data_out[data_index];
					data_index <= data_index - 6'd1;
				end
			else
				begin
					audio_data <=  da_data_out[data_index];
					sample_flag <= 0;
				end
		end
end

assign audio_dalr = clk_en;
assign audio_datat = audio_data;

endmodule