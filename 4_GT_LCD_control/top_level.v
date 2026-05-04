module top_level (
    input clk_50mhz,
    input rst_n,
    input clear,              
    output rs,
    output rw,
    output en,
    output [7:0] pin_data
);

    //==========================================================
    // Khai báo tín hiệu
    //==========================================================
    reg [3:0] col;           
    reg [1:0] row;           
    reg [7:0] data_in;       
    reg [3:0] state;
	 reg [3:0] step;
    reg [3:0] state_lcd;
    reg [4:0] counter;
    wire done_write;

    //==========================================================
    // Chuỗi ký tự hiển thị
    //==========================================================
    wire [7:0] data_write1[4:0], data_write2[12:0];
    wire [39:0] chuoikitu1 = "UNETI";
    wire [103:0] chuoikitu2 = "KHOA DIEN-TDH";
	 
	 
	 
	 //==================== STATE MACHINE ====================
	 parameter IDLE        			= 3'd0;
	 parameter SET_CURSOR_LINE_1  = 3'd1;
	 parameter WRITE_DATA_LINE_1  = 3'd2;
	 parameter SET_CURSOR_LINE_2  = 3'd3;
	 parameter WRITE_DATA_LINE_2	= 3'd4;
	 parameter DONE					= 3'd5;

	 //==============CHUYEN CHUOI THANH MANG KY TU ====================
    generate
        genvar i;
        for(i = 1; i < 6; i = i + 1) begin : gen_text
            assign data_write1[5 - i] = chuoikitu1[i*8 - 1 : i*8 - 8];
        end
    endgenerate
	 
	 generate
        genvar x;
        for(x = 1; x < 14; x = x + 1) begin : gen_text2
            assign data_write2[13 - x] = chuoikitu2[x*8 - 1 : x*8 - 8];
        end
    endgenerate

    //==========================================================
    // FSM chính: hiển thị 2 dòng LCD
    //==========================================================
    always @(posedge clk_50mhz or negedge rst_n) begin
        if(!rst_n) begin
            state <= IDLE;
            counter <= 0;
				step <= 0;
        end else begin
            case(state)
                // ---------- Ghi dòng 1 ----------
				IDLE: begin
                  if(done_write) state <= SET_CURSOR_LINE_1;
				end
				SET_CURSOR_LINE_1: begin
					case(step)
						0: begin
                        row <= 0; col <= 6;			// gan vi tri hang 0 cot 6
                        state_lcd <= 0;        		// Mode Set Vi tri
                        if(!done_write) step <= 1;
							end
						1: if(done_write)
								begin
								state <= WRITE_DATA_LINE_1;
								step <= 2;
								end
					endcase
				end
				WRITE_DATA_LINE_1: begin
					case(step)
						2: begin
                        data_in <= data_write1[counter]; 	// lay data can gui
                        state_lcd <= 1;        					// Mode Gui Data
                        if(!done_write) step <= 3;
                   end
						3: if(done_write) begin
                        counter <= counter + 1;
                        if(counter < 4) step <= 2;
                        else begin
                            counter <= 0;
                            state <= SET_CURSOR_LINE_2;
									 state_lcd <= 4;
									 step<= 4;
                        end
                   end
					endcase
				end
				
                // ---------- Ghi dòng 2 ----------
				SET_CURSOR_LINE_2: begin
					case(step)
						4: begin
                        row <= 1; col <= 2;			// gan vi tri hang 1 cot 2
                        state_lcd <= 0;
                        if(!done_write) step <= 5;	// Mode Set Vi tri
							end
						5: if(done_write) 
								begin
								state <= WRITE_DATA_LINE_2;
								step <= 6;
								end
					endcase
				end
				WRITE_DATA_LINE_2: begin
					case(step)
						6: begin
                        data_in <= data_write2[counter];	// lay data can gui
                        state_lcd <= 1;						// Mode Gui Data
                        if(!done_write) step <= 7;
							end
						7: if(done_write) begin
                        counter <= counter + 1;
                        if(counter < 12) step <= 6;
                        else begin
									state <= DONE;
									step <= 8;
								end// kết thúc
							end
					endcase
				 end
				DONE: begin
							state_lcd <= 4;  // idle
						end
           endcase
        end
    end

    //==========================================================
    // Gọi module LCD
    //==========================================================
    lcdController_pos lcd (
        .clk_50mhz(clk_50mhz),
        .rst_n(rst_n),
        .state_input(state_lcd),
        .col(col),
        .row(row),
        .data_in(data_in),
        .rs(rs),
        .rw(rw),
        .en(en),
        .data(pin_data),
        .done_write(done_write)
    );

endmodule


