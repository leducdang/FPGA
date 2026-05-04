//module keypad4x4(
//    input        clk,         // clock 50MHz
//    input        rst_n,
//    input  [3:0] col,         // cột từ keypad
//    output reg [3:0] row,     // hàng xuất xuống keypad
//    output reg [3:0] key_val, // giá trị key (0–15)
//    output reg   key_pressed  // xung báo nhấn phím
//);
//
//    reg        stable;
//    reg [1:0]  scan_row = 0;
//    reg [3:0]  col_reg;
//	 reg [15:0] counter;
//	 
//	 
//    // --------------------------- QUÉT HÀNG ---------------------------
//    always @(posedge clk or negedge rst_n) begin
//        if(!rst_n) begin
//            scan_row <= 0;
//				counter  <= 0;
//        end else begin
//				if(counter == 16'd500000)				//10ms
//					begin
//						scan_row <= scan_row + 2'd1;
//						counter <= 0;
//					end
//				else begin counter <= counter + 16'd1; end
//        end
//    end
//
//    always @(*) begin
//        case(scan_row)
//            0: row = 4'b1110;
//            1: row = 4'b1101;
//            2: row = 4'b1011;
//            3: row = 4'b0111;
//            default: row = 4'b1111;
//        endcase
//    end
//
//    // Chốt cột đọc được
//    always @(posedge clk)
//        col_reg <= col;
//
//    // --------------------------- DEBOUNCE ---------------------------
//    always @(posedge clk or negedge rst_n) begin
//        if(!rst_n) begin
//            stable       <= 0;
//        end else begin
//            if(col_reg != 4'b1111) begin
//                stable <= 1;
//            end else begin
//                stable       <= 0;
//            end
//        end
//    end
//
//    // --------------------------- GIẢI MÃ PHÍM ---------------------------
//    always @(posedge clk or negedge rst_n) begin
//        if(!rst_n) begin
//            key_pressed <= 0;
//            key_val <= 4'h0;
//        end
//        else begin
//            if(stable && !key_pressed) begin
//                 // tạo 1 xung duy nhất
//					key_pressed <= 1;
//                
//					 case({row, col_reg})
//                    // row=0 (1110)
//                    8'b1110_1110:  key_val <= 4'd1;    // phím 1
//                    8'b1110_1101:  key_val <= 4'd2;  
//                    8'b1110_1011:  key_val <= 4'd3;	 
//                    8'b1110_0111:  key_val <= 4'd4;	 
//
//                    // row=1 (1101)
//                    8'b1101_1110:  key_val <= 4'd5;	 
//                    8'b1101_1101:  key_val <= 4'd6;	 
//                    8'b1101_1011:  key_val <= 4'd7;	 
//                    8'b1101_0111:  key_val <= 4'd8;	 
//
//                    // row=2 (1011)
//                    8'b1011_1110:  key_val <= 4'd9;	 
//                    8'b1011_1101:  key_val <= 4'd10; 
//                    8'b1011_1011:  key_val <= 4'd11; 
//                    8'b1011_0111:  key_val <= 4'd12; 
// 
//                    // row=3 (0111)
//                    8'b0111_1110:  key_val <= 4'd13; 
//                    8'b0111_1101:  key_val <= 4'd14; 
//                    8'b0111_1011:  key_val <= 4'd15; 
//                    8'b0111_0111:  key_val <= 4'd0;  
//                endcase
//            end
//            else if(!stable)
//                key_pressed <= 0;
//        end
//    end
//endmodule



module keypad4x4(
    input        clk,         // clock 50MHz
    input        rst_n,
    input  [3:0] col,         // cột từ keypad
    output reg [3:0] row,     // hàng xuất xuống keypad
    output reg [3:0] key_val // giá trị phím (0–15)
);

    reg [1:0] scan_row;
    reg [15:0] scan_cnt;
    reg [3:0] col_reg;
    reg stable;
	 reg   key_pressed;
    // --------- Scan row (10ms mỗi hàng) ---------
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            scan_row <= 0;
            scan_cnt <= 0;
        end else begin
            if(scan_cnt == 16'd500_000) begin // 10ms @50MHz
                scan_row <= scan_row + 1;
                scan_cnt <= 0;
            end else
                scan_cnt <= scan_cnt + 1;
        end
    end

    always @(*) begin
        case(scan_row)
            2'd0: row <= 4'b1110;
            2'd1: row <= 4'b1101;
            2'd2: row <= 4'b1011;
            2'd3: row <= 4'b0111;
            default: row <= 4'b1111;
        endcase
    end

    // Latch cột đọc được
    always @(posedge clk) col_reg <= col;

    // --------- Debounce: chỉ cần phím khác 1111 ---------
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n)
            stable <= 0;
        else
            stable <= (col_reg != 4'b1111);
    end

    // --------- Giải mã phím và tạo xung ---------
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            key_pressed <= 0;
            key_val     <= 0;
        end else if(stable && !key_pressed) begin
            key_pressed <= 1;
            case({row, col_reg})
                8'b1110_1110: key_val <= 1; 8'b1110_1101: key_val <= 2;
                8'b1110_1011: key_val <= 3; 8'b1110_0111: key_val <= 4;
                8'b1101_1110: key_val <= 5; 8'b1101_1101: key_val <= 6;
                8'b1101_1011: key_val <= 7; 8'b1101_0111: key_val <= 8;
                8'b1011_1110: key_val <= 9; 8'b1011_1101: key_val <= 10;
                8'b1011_1011: key_val <= 11;8'b1011_0111: key_val <= 12;
                8'b0111_1110: key_val <= 13;8'b0111_1101: key_val <= 14;
                8'b0111_1011: key_val <= 15;8'b0111_0111: key_val <= 0;
                default: key_val <= 0;
            endcase
        end else if(!stable)
            key_pressed <= 0;
    end
endmodule
