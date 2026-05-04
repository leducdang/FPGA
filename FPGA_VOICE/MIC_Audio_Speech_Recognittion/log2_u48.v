module log2_u48
(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        in_valid,
    input  wire [47:0] x,

    output reg         out_valid,
    output reg  [23:0] y
);

parameter FRAC = 10;

reg [5:0]  exp;
reg [5:0]  exp_reg;
reg [47:0] norm;
reg [7:0]  index;
wire [FRAC-1:0] frac;

reg nz;
reg nz_reg;

reg [2:0] state;

localparam IDLE     = 3'd0,
           START    = 3'd1,
           CAL      = 3'd2,
           WAIT_ROM = 3'd3,
           DONE     = 3'd4;

// ---------------------------
// Leading One Detector
// ---------------------------
integer i;

always @(*) begin
    nz = 0;
    exp = 0;

    for(i=47;i>=0;i=i-1) begin
        if(!nz && x[i]) begin
            nz = 1;
            exp = i;
        end
    end
end

// ---------------------------
// FSM
// ---------------------------
always @(posedge clk or negedge rst_n)
begin
    if(!rst_n) begin
        state <= IDLE;
        norm  <= 0;
        index <= 0;
        y <= 0;
        out_valid <= 0;
        exp_reg <= 0;
        nz_reg  <= 0;
    end
    else begin

        case(state)

        //--------------------------------
        //			IDLE
        //--------------------------------
        IDLE: begin
            out_valid <= 0;
            if(in_valid) begin
                exp_reg <= exp;
                nz_reg  <= nz;
                state <= START;
            end
        end

        //--------------------------------
        //			START
        //--------------------------------
        START: begin
            norm <= x << (47-exp_reg);
            state <= CAL;
        end

        //--------------------------------
		  //        CAL
        //--------------------------------
        CAL: begin
            index <= norm[46:39];
            state <= WAIT_ROM;
        end
		  
        //--------------------------------
        // 			WAIT_ROM
        //--------------------------------
        WAIT_ROM: begin
            state <= DONE;
        end
		  
        //--------------------------------
        //			DONE
        //--------------------------------
        DONE: begin
            out_valid <= 1;
            if(!nz_reg)
                y <= 0;
            else
                y <= (exp_reg << FRAC) + frac;
				if(!in_valid)
            state <= IDLE;
        end
        endcase
    end

end

// ---------------------------
// ROM instance
// ---------------------------
log_lut log_lut_inst(
    .address(index),
    .clock(clk),
    .q(frac)
);

endmodule





















//module log2_u48
//(
//    input  wire        clk,
//    input  wire        rst_n,
//    input  wire        in_valid,
//    input  wire [47:0] x,
//
//    output reg         out_valid,
//    output reg  [15:0] y
//);
//
//parameter FRAC = 10;
//
//reg [5:0]  exp;
//reg [47:0] norm;
//reg [7:0]  index;
//wire [FRAC-1:0] frac;
//
//reg nz;
//reg in_valid_d;
//reg [2:0] state;
//localparam  IDLE  = 3'd0,
//				START = 3'd1,
//				CAL	= 3'd2,
//				DONE	= 3'd3;
//
//// ---------------------------
//// Leading One Detector
//// ---------------------------
//integer i;
//
//always @(*) begin
//    nz = 0;
//    exp = 0;
//
//    for(i=47;i>=0;i=i-1) begin
//        if(!nz && x[i]) begin
//            nz = 1;
//            exp = i;
//        end
//    end
//end
//
//always @(posedge clk or negedge rst_n) 
//begin
//	if(!rst_n) begin
//		state <= IDLE;
//		norm  <= 0;
//      index <= 0;
//		y <= 0;
//      out_valid <= 0;
//	end
//	else
//		case(state)
//			IDLE: begin
//				norm  <= 0;
//				index <= 0;
//				y <= 0;
//				out_valid <= 0;
//				if(in_valid) state <= START;
//			end
//			START: begin
//				norm  <= x << (47-exp);
//				state <= CAL;
//			end
//			CAL:	begin
//				index <= norm[46:39];
//				state <= DONE;
//			end
//			DONE: begin
//				out_valid <= 1;
//				if(!nz)
//					y <= 0;
//				else
//					y <= (exp << FRAC) + frac;
//				if(!in_valid) state <= IDLE;
//			end
//			
//		endcase
//end
//
//// ---------------------------
//// ROM instance
//// ---------------------------
//log_lut log_lut_inst(
//    .address(index),
//    .clock(clk),
//    .q(frac)
//);
//
//endmodule
//	
	
