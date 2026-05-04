module lcdController_pos(
    input clk_50mhz,					// PIN CLOCK 50MHZ
    input rst_n,						// PIN RESET
	 input [2:0] state_input,		// 0: set cursor, 1: write_data, 2: write_cmd, 3: clear_display, 4: IDE
    input [3:0] col,          	// VI TRI CỘT (0–15)
    input [1:0] row,          	// VI TRI HÀNG (0 hoặc 1)
    input [7:0] data_in,      	// DATA IN
    output reg rs,					// PIN RS LCD
    output reg rw,					// PIN RW LCD
    output reg en,					// PIN EN LCD
    output reg [7:0] data,			// PIN DATA LCD
	 output reg done_write			// = 1 HOAN THANH GHI DU LIEU, = 0 DANG GHI DU LIEU
);

//==================== CLOCK 1ms ====================
reg [15:0] cnt_1ms;
reg tick_1ms;
always @(posedge clk_50mhz or negedge rst_n) begin
    if(!rst_n) begin
        cnt_1ms <= 0;
        tick_1ms <= 0;
    end else if (cnt_1ms == 16'd49999) begin
        cnt_1ms <= 0;
        tick_1ms <= 1;
    end else begin
        cnt_1ms <= cnt_1ms + 1;
        tick_1ms <= 0;
    end
end

//==================== STATE MACHINE ====================
parameter IDLE        = 3'd0;
parameter INIT_LCD    = 3'd1;
parameter SET_CURSOR  = 3'd2;
parameter WRITE_DATA  = 3'd3;
parameter CLEAR_LCD   = 3'd4;
parameter CMD_DATA	 = 3'd5;

reg [2:0] state;
reg [3:0] init_step;
reg [3:0] step;

//==================== MAIN FSM ====================
always @(posedge clk_50mhz or negedge rst_n) begin
    if(!rst_n) begin
        state <= INIT_LCD;
        init_step <= 0;
		  step <= 0;
        rs <= 0; rw <= 0; en <= 0; data <= 8'h00; done_write <= 0;
    end
    else if(tick_1ms) begin
        case(state)
        //----------------------------------------------------------
        // 1: KHOI TAO LCD
        //----------------------------------------------------------
        INIT_LCD: begin
            case(init_step)
                0: begin rs<=0; rw<=0; data<=8'h38; en<=1; end // 8-BIT, 2 DONG
                1: en<=0;
                2: begin data<=8'h0C; en<=1; end               // BAT HIEN THI, TAT CON TRO
                3: en<=0;
                4: begin data<=8'h01; en<=1; end               // XOA MAN HINH
                5: en<=0;
                6: begin data<=8'h06; en<=1; end               // TANG DIA CHI TU DONG
                7: begin en<=0; done_write = 1; end				// KHOI TAO XONG
                8: state <= IDLE;  
            endcase
            if(init_step < 8) init_step <= init_step + 1;
        end
        //----------------------------------------------------------
        // 2: XOA MAN HINH
        //----------------------------------------------------------
        CLEAR_LCD: begin
				case(step)
					0: begin
							rs <= 0;
							rw <= 0;
							data <= 8'h01;  						// LENH CLEAR LCD
							en <= 1;
							step <= 1;
						end
					1: begin
							en <= 0;
							state <= IDLE;
							done_write <= 1;
						end
				endcase
        end
        //----------------------------------------------------------
        // 3: SET VI TRI CON TRO
        //----------------------------------------------------------
        SET_CURSOR: begin
				case(step)
					0: begin
							rs <= 0; 
							rw <= 0;
							if(row == 0)
								data <= 8'h80 + col;				// GUI VI TRI HANG 0 + CỘT
							else
								data <= 8'hC0 + col;				// GUI VI TRI HANG 1 +  CỘT
							en <= 1;
							step <= 1;
							
						end
					1: begin
							en<= 0;
							state <= IDLE;
							done_write <= 1;
						end
				endcase
        end
        //----------------------------------------------------------
        // 4: GHI DATA HIEN THI
        //----------------------------------------------------------
        WRITE_DATA: begin
				case(step)
					0: begin
							rs <= 1; 
							rw <= 0;
							data <= data_in;     // GUI KY TU CAN HIEN THI
							en <= 1;
							step <= 1;
						end
					1: begin
							en <= 0;
							state <= IDLE;
							done_write <= 1;
						end
				endcase
        end
		  //----------------------------------------------------------
        // 5: GUI LENH CMD
        //----------------------------------------------------------
		  CMD_DATA: begin
				case(step)
					0: begin
							rs <= 0; 
							rw <= 0;
							data <= data_in;     // GUI LENH DIEU KHIEN
							en <= 1;
							step <= 1;
						end
					1: begin
							en <= 0;
							state <= IDLE;
							done_write <= 1;
						end
				endcase
        end
        //----------------------------------------------------------
        // 6: IDLE CHO LENH
		  //	STATE:  0: set cursor, 1: write_data, 2: write_cmd, 3: clear_display
        //----------------------------------------------------------
        IDLE: begin
            en <= 0;
				init_step 	<= 0;
				step <= 0;
				case(state_input)
					0:begin state <=	SET_CURSOR; done_write  <= 0; end
					1:begin state <=	WRITE_DATA; done_write  <= 0;	end
					2:begin state <= CMD_DATA;		done_write  <= 0;	end
					3:begin state <= CLEAR_LCD;	done_write  <= 0;	end
					4:state <= IDLE;
				endcase
        end
        endcase
    end
end

endmodule
