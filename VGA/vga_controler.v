//module vga_controler( clock_50mhz,
//								vga_r,
//								vga_g,
//								vga_b,
//								pin_rgb_r,
//								pin_rgb_g,
//								pin_rgb_b,
//								vga_clk,
//								vga_sync,
//								vga_blank,
//								vga_vs,
//								vga_hs,
//								reset,
//							);
//	
//input clock_50mhz;
//input [7:0] vga_r;
//input [7:0] vga_g;
//input [7:0] vga_b;
//output [7:0] pin_rgb_r;
//output [7:0] pin_rgb_g;
//output [7:0] pin_rgb_b;
//
//input 		reset;
//output 		vga_clk;
//output		vga_sync;
//output		vga_blank;
//output		vga_vs;
//output		vga_hs;
//	
//reg clock;	
//
//parameter HD = 640;             // horizontal display area width in pixels
//parameter HB = 16;              // horizontal back porch width in pixels
//parameter HR = 96;              // horizontal retrace width in pixels
//parameter HF = 48;              // horizontal front porch width in pixels
//parameter HMAX = HD+HF+HB+HR-1; // max value of horizontal counter = 799
//
//
//   // Total vertical length of screen = 525 pixels, partitioned into sections
//	
//parameter VD = 480;             // vertical display area length in pixels 
//parameter VF = 10;              // vertical front porch length in pixels  
//parameter VR = 2;					  // vertical retrace length in pixels  
//parameter VB = 33;              // vertical back porch length in pixels 
//  
//               
//parameter VMAX = VD+VF+VB+VR-1; // max value of vertical counter = 524  
//
////parameter VD = 400;             // vertical display area length in pixels 
////parameter VF = 12;              // vertical front porch length in pixels  
////parameter VB = 35;              // vertical back porch length in pixels   
////parameter VR = 2;               // vertical retrace length in pixels  
////parameter VMAX = VD+VF+VB+VR-1; // max value of vertical counter = 524  
//
//reg [9:0] h_count_reg, h_count_next;
//reg [9:0] v_count_reg, v_count_next;
//reg [7:0] r_reg;
//reg [7:0] g_reg;
//reg [7:0] b_reg;
//reg 		vga_sync_reg;
//reg 		vga_blank_reg;
//    
//    // Output Buffers
//reg v_sync_reg, h_sync_reg;
//wire v_sync_next, h_sync_next;
//
//
//
//
//
//	always@(posedge clock_50mhz or negedge reset)
//		begin 
//			if(!reset) clock <= 0;
//			else
//			clock <= ~clock;
//		
//		end							
//							
//
//
//    always @(posedge clock or negedge reset)      // pixel tick
//		begin
//        if(!reset)
//            h_count_next <= 0;
//        else
//				begin
//					if(h_count_next == HMAX)                 // end of horizontal scan
//						begin
//							h_count_next <= 0;
//							if((v_count_next == VMAX))           // end of vertical scan
//								v_count_next <= 0;
//							else
//								v_count_next <= v_count_next + 1;
//						end 
//					else
//						h_count_next <= h_count_next + 1; 
//				end
//		end	 
//							
//	always@(posedge clock)
//		begin
//			if(h_count_next < (HD +HF -1) ) h_sync_reg <= 1;
//			else if(h_count_next < (HD +HF +HR - 1)) h_sync_reg <= 0;
//			else if(h_count_next < HMAX)	h_sync_reg <= 1;
//		end
//		
//							
//	always@(posedge clock)
//		begin
//			if(v_count_next < (VD +VF -1) ) v_sync_reg <= 1;
//			else if(v_count_next < (VD +VF +VR -1)) v_sync_reg <= 0;
//			else if(v_count_next < VMAX)	v_sync_reg <= 1;
//		end						
//				
//	
//	always@(posedge clock)
//		begin
//			if((v_count_next < VD + VF - 1) && (h_count_next < HD + HF - 1))
//				begin
//					if(v_count_next <160)
//						begin
//							r_reg <= 8'd255;
//							g_reg <= 8'd0;
//							b_reg <= 8'd0;
//						end
//					else if(v_count_next >159 && v_count_next <320)
//						begin
//							r_reg <= 8'd0;
//							g_reg <= 8'd255;
//							b_reg <= 8'd0;
//						end
//					else
//						begin
//							r_reg <= 8'd0;
//							g_reg <= 8'd0;
//							b_reg <= 8'd255;
//						end						
//					vga_sync_reg <= 1;
//					vga_blank_reg <= 1;
//				end
//			else
//				begin
//					r_reg <= 8'd0;
//					g_reg <= 8'd0;
//					b_reg <= 8'd0;
//					vga_sync_reg <= 1;
//					vga_blank_reg <= 0;
//				end
//		end
//	
//	
//assign pin_rgb_r = r_reg;
//assign pin_rgb_g = g_reg;
//assign pin_rgb_b = b_reg;
//assign vga_sync = vga_sync_reg;
//assign vga_blank = vga_blank_reg;	
//assign vga_clk = ~clock;
//assign vga_vs	= v_sync_reg;
//assign vga_hs	= h_sync_reg;
//
//endmodule


































module	VGA_Ctrl	(	//	Host Side
						iRed,
						iGreen,
						iBlue,
//						oCurrent_X,
//						oCurrent_Y,
//						oAddress,
//						oRequest,
						//	VGA Side
						oVGA_R,
						oVGA_G,
						oVGA_B,
						oVGA_HS,
						oVGA_VS,
						oVGA_SYNC,
						oVGA_BLANK,
						oVGA_CLOCK,
						//	Control Signal
						iCLK,
						iRST_N	);
//	Host Side
input		[7:0]	iRed;
input		[7:0]	iGreen;
input		[7:0]	iBlue;
//output		[21:0]	oAddress;
//output		[10:0]	oCurrent_X;
//output		[10:0]	oCurrent_Y;
//output				oRequest;
//	VGA Side


output		[7:0]	oVGA_R;
output		[7:0]	oVGA_G;
output		[7:0]	oVGA_B;
output	reg		oVGA_HS;
output	reg		oVGA_VS;
output				oVGA_SYNC;
output				oVGA_BLANK;
output				oVGA_CLOCK;
//	Control Signal
input				iCLK;
input				iRST_N;	
//	Internal Registers
reg			[10:0]	H_Cont;
reg			[10:0]	V_Cont;

////////////////////////////////////////////////////////////
//	Horizontal	Parameter
parameter	H_FRONT	=	16;
parameter	H_SYNC	=	96;
parameter	H_BACK	=	48;
parameter	H_ACT	=	640;
parameter	H_BLANK	=	H_FRONT+H_SYNC+H_BACK;
parameter	H_TOTAL	=	H_FRONT+H_SYNC+H_BACK+H_ACT;
////////////////////////////////////////////////////////////
//	Vertical Parameter
parameter	V_FRONT	=	11;
parameter	V_SYNC	=	2;
parameter	V_BACK	=	31;
parameter	V_ACT	=	480;
parameter	V_BLANK	=	V_FRONT+V_SYNC+V_BACK;
parameter	V_TOTAL	=	V_FRONT+V_SYNC+V_BACK+V_ACT;
////////////////////////////////////////////////////////////
assign	oVGA_SYNC	=	1'b1;			//	This pin is unused.
assign	oVGA_BLANK	=	~((H_Cont<H_BLANK)||(V_Cont<V_BLANK));
assign	oVGA_CLOCK	=	~iCLK;
assign	oVGA_R		=	iRed;
assign	oVGA_G		=	iGreen;
assign	oVGA_B		=	iBlue;

//assign	oAddress	=	oCurrent_Y*H_ACT+oCurrent_X;
//assign	oRequest	=	((H_Cont>=H_BLANK && H_Cont<H_TOTAL)	&&
//						 (V_Cont>=V_BLANK && V_Cont<V_TOTAL));
//assign	oCurrent_X	=	(H_Cont>=H_BLANK)	?	H_Cont-H_BLANK	:	11'h0	;
//assign	oCurrent_Y	=	(V_Cont>=V_BLANK)	?	V_Cont-V_BLANK	:	11'h0	;

//	Horizontal Generator: Refer to the pixel clock
always@(posedge iCLK or negedge iRST_N)
begin
	if(!iRST_N)
	begin
		H_Cont		<=	0;
		oVGA_HS		<=	1;
	end
	else
	begin
		if(H_Cont<H_TOTAL)
		H_Cont	<=	H_Cont+1'b1;
		else
		H_Cont	<=	0;
		//	Horizontal Sync
		if(H_Cont==H_FRONT-1)			//	Front porch end
		oVGA_HS	<=	1'b0;
		if(H_Cont==H_FRONT+H_SYNC-1)	//	Sync pulse end
		oVGA_HS	<=	1'b1;
	end
end

//	Vertical Generator: Refer to the horizontal sync
always@(posedge oVGA_HS or negedge iRST_N)
begin
	if(!iRST_N)
	begin
		V_Cont		<=	0;
		oVGA_VS		<=	1;
	end
	else
	begin
		if(V_Cont<V_TOTAL)
		V_Cont	<=	V_Cont+1'b1;
		else
		V_Cont	<=	0;
		//	Vertical Sync
		if(V_Cont==V_FRONT-1)			//	Front porch end
		oVGA_VS	<=	1'b0;
		if(V_Cont==V_FRONT+V_SYNC-1)	//	Sync pulse end
		oVGA_VS	<=	1'b1;
	end
end


endmodule
