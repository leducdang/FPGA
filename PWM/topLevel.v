module topLevel(
						clk_50mhz,
						sw,
						led_duty,
						led_pwm,
						reset
					);

input  clk_50mhz;
input  [6:0] sw;
input 		 reset;
output [6:0] led_duty;
output 		 led_pwm;				
					
assign led_duty = sw;



reg [6:0] period;
reg [8:0] counter;




	//1khz = 50000000/1000 = 50000 xung
	// 100 level duty => 500 xung      <=> 100 period
	
always@ (posedge clk_50mhz or negedge reset)
begin
	if(!reset)
		begin
			counter  <= 0;
			period	<= 0;
		end
	else
		begin

			if (counter < 499) counter <= counter + 1;
				else 
					begin
						counter <= 0;
						period <= period + 1;
					end
			if(period > 99) 	period <= 0;	
			
		end
	
end	
					
					
assign led_pwm = (sw > period) ? 1 : 0;
					
					
endmodule					
