module MFCC30_DTW_RECOG (
    input  wire clk,
    input  wire rst,              // active low

    input  wire mfcc_valid,
    input  wire [3:0] mfcc_index, // 0 -> 12
    input  wire signed [31:0] mfcc_in, // Q8.10

    output reg [2:0] result,      // 1 -> 4
    output reg recog_valid,
    output reg recog_done,
    output reg [63:0] best_distance,
    output reg [5:0] frame_count
);

    parameter FRAME_N = 30;
    parameter MFCC_N  = 12;
    parameter DATA_N  = 360;

    parameter [63:0] THRESHOLD = 64'd18874368000; // norm = 300
    localparam [63:0] INF = 64'd1000000000000;    // 1e12

    reg signed [31:0] input_mem [0:DATA_N-1];

    reg signed [31:0] tpl1 [0:DATA_N-1];
    reg signed [31:0] tpl2 [0:DATA_N-1];
    reg signed [31:0] tpl3 [0:DATA_N-1];
    reg signed [31:0] tpl4 [0:DATA_N-1];

    initial begin
        $readmemh("template_1_30frame_mfcc1_12_q810_hex.hex", tpl1);
        $readmemh("template_2_30frame_mfcc1_12_q810_hex.hex", tpl2);
        $readmemh("template_3_30frame_mfcc1_12_q810_hex.hex", tpl3);
        $readmemh("template_4_30frame_mfcc1_12_q810_hex.hex", tpl4);
    end

    reg signed [31:0] frame_buf [0:11];
    reg buffer_full;
    reg new_frame_ready;

    reg [63:0] prev [0:FRAME_N];
    reg [63:0] curr [0:FRAME_N];
    reg [63:0] dist [1:4];

    reg [5:0] i, j;
    reg [3:0] k;
    reg [2:0] tpl_id;

    reg signed [31:0] a_reg;
    reg signed [31:0] b_reg;
    reg signed [32:0] diff_reg;
    reg [65:0] diff_sq;
    reg [63:0] cost_acc;

    reg [63:0] best_calc;
    reg [2:0]  result_calc;

    integer p, c;

    function signed [31:0] get_template;
        input [2:0] id;
        input [8:0] addr;
        begin
            case(id)
                3'd1: get_template = tpl1[addr];
                3'd2: get_template = tpl2[addr];
                3'd3: get_template = tpl3[addr];
                3'd4: get_template = tpl4[addr];
                default: get_template = 32'sd0;
            endcase
        end
    endfunction

    function [63:0] min3;
        input [63:0] x;
        input [63:0] y;
        input [63:0] z;
        begin
            if(x <= y && x <= z)
                min3 = x;
            else if(y <= x && y <= z)
                min3 = y;
            else
                min3 = z;
        end
    endfunction

    always @(*) begin
        best_calc   = dist[1];
        result_calc = 3'd1;

        if(dist[2] < best_calc) begin
            best_calc   = dist[2];
            result_calc = 3'd2;
        end

        if(dist[3] < best_calc) begin
            best_calc   = dist[3];
            result_calc = 3'd3;
        end

        if(dist[4] < best_calc) begin
            best_calc   = dist[4];
            result_calc = 3'd4;
        end
    end

    localparam IDLE       = 5'd0;
    localparam INIT       = 5'd1;
    localparam ROW_INIT   = 5'd2;
    localparam COST_INIT  = 5'd3;
    localparam LOAD_AB    = 5'd4;
    localparam CALC_DIFF  = 5'd5;
    localparam CALC_SQ    = 5'd6;
    localparam COST_ACC   = 5'd7;
    localparam CELL_DONE  = 5'd8;
    localparam NEXT_CELL  = 5'd9;
    localparam NEXT_ROW   = 5'd10;
    localparam SAVE_DIST  = 5'd11;
    localparam NEXT_TPL   = 5'd12;
    localparam FIND_BEST  = 5'd13;
    localparam DONE       = 5'd14;

    reg [4:0] state;

    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            frame_count     <= 6'd0;
            buffer_full     <= 1'b0;
            new_frame_ready <= 1'b0;

            result          <= 3'd0;
            recog_valid     <= 1'b0;
            recog_done      <= 1'b0;
            best_distance   <= 64'd0;

            i <= 6'd0;
            j <= 6'd0;
            k <= 4'd0;
            tpl_id <= 3'd1;

            cost_acc <= 64'd0;
            state <= IDLE;
        end
        else begin
            new_frame_ready <= 1'b0;
            recog_done      <= 1'b0;
            recog_valid     <= 1'b0;

            if(mfcc_valid && mfcc_index >= 4'd1 && mfcc_index <= 4'd12) begin
                frame_buf[mfcc_index - 1'b1] <= mfcc_in;

                if(mfcc_index == 4'd12) begin
                    for(p = 0; p < FRAME_N-1; p = p + 1) begin
                        for(c = 0; c < MFCC_N; c = c + 1) begin
                            input_mem[p*MFCC_N + c] <= input_mem[(p+1)*MFCC_N + c];
                        end
                    end

                    for(c = 0; c < MFCC_N; c = c + 1) begin
                        if(c == 11)
                            input_mem[(FRAME_N-1)*MFCC_N + c] <= mfcc_in;
                        else
                            input_mem[(FRAME_N-1)*MFCC_N + c] <= frame_buf[c];
                    end

                    if(frame_count < FRAME_N)
                        frame_count <= frame_count + 1'b1;

                    if(frame_count >= FRAME_N-1) begin
                        buffer_full     <= 1'b1;
                        new_frame_ready <= 1'b1;
                    end
                end
            end

            case(state)

                IDLE: begin
                    if(buffer_full && new_frame_ready) begin
                        tpl_id <= 3'd1;
                        state  <= INIT;
                    end
                end

                INIT: begin
                    prev[0] <= 64'd0;

                    for(p = 1; p <= FRAME_N; p = p + 1)
                        prev[p] <= INF;

                    i <= 6'd1;
                    state <= ROW_INIT;
                end

                ROW_INIT: begin
                    curr[0] <= INF;

                    for(p = 1; p <= FRAME_N; p = p + 1)
                        curr[p] <= INF;

                    j <= 6'd1;
                    state <= COST_INIT;
                end

                COST_INIT: begin
                    k <= 4'd0;
                    cost_acc <= 64'd0;
                    state <= LOAD_AB;
                end

                LOAD_AB: begin
                    a_reg <= input_mem[(i-1)*MFCC_N + k];
                    b_reg <= get_template(tpl_id, (j-1)*MFCC_N + k);
                    state <= CALC_DIFF;
                end

                CALC_DIFF: begin
                    diff_reg <= a_reg - b_reg;
                    state <= CALC_SQ;
                end

                CALC_SQ: begin
                    diff_sq <= diff_reg * diff_reg;
                    state <= COST_ACC;
                end

                COST_ACC: begin
                    if(k == MFCC_N-1) begin
                        state <= CELL_DONE;
                    end
                    else begin
                        cost_acc <= cost_acc + diff_sq[63:0];
                        k <= k + 1'b1;
                        state <= LOAD_AB;
                    end
                end

                CELL_DONE: begin
                    curr[j] <= cost_acc
                             + diff_sq[63:0]
                             + min3(prev[j], curr[j-1], prev[j-1]);

                    state <= NEXT_CELL;
                end

                NEXT_CELL: begin
                    if(j == FRAME_N) begin
                        state <= NEXT_ROW;
                    end
                    else begin
                        j <= j + 1'b1;
                        state <= COST_INIT;
                    end
                end

                NEXT_ROW: begin
                    for(p = 0; p <= FRAME_N; p = p + 1)
                        prev[p] <= curr[p];

                    if(i == FRAME_N) begin
                        state <= SAVE_DIST;
                    end
                    else begin
                        i <= i + 1'b1;
                        state <= ROW_INIT;
                    end
                end

                SAVE_DIST: begin
                    dist[tpl_id] <= curr[FRAME_N];
                    state <= NEXT_TPL;
                end

                NEXT_TPL: begin
                    if(tpl_id == 3'd4) begin
                        state <= FIND_BEST;
                    end
                    else begin
                        tpl_id <= tpl_id + 1'b1;
                        state <= INIT;
                    end
                end

                FIND_BEST: begin
                    best_distance <= best_calc;
                    result        <= result_calc;
                    state <= DONE;
                end

                DONE: begin
                    recog_done <= 1'b1;

                    if(best_distance < THRESHOLD)
                        recog_valid <= 1'b1;
                    else
                        recog_valid <= 1'b0;

                    state <= IDLE;
                end

                default: begin
                    state <= IDLE;
                end

            endcase
        end
    end

endmodule


//module MFCC30_DTW_RECOG (
//    input  wire clk,
//    input  wire rst,              // active low
//
//    input  wire mfcc_valid,
//    input  wire [3:0] mfcc_index, // 0 -> 12
//    input  wire signed [31:0] mfcc_in, // Q8.10
//
//    output reg [2:0] result,      // 1 -> 4
//    output reg recog_valid,
//    output reg recog_done,
//    output reg [63:0] best_distance,
//    output reg [5:0] frame_count
//);
//
//    parameter FRAME_N = 30;
//    parameter MFCC_N  = 12;
//    parameter DATA_N  = 360;
//
////    parameter [63:0] THRESHOLD = 64'd28874368000;
//	 parameter [63:0] THRESHOLD = 64'd18874368000;									
////    localparam [63:0] INF = 64'h7FFFFFFFFFFFFFFF;
//	 localparam [63:0] INF = 64'd1000000000000; // 1e12
//
//    reg signed [31:0] input_mem [0:DATA_N-1];
//
//    reg signed [31:0] tpl1 [0:DATA_N-1];
//    reg signed [31:0] tpl2 [0:DATA_N-1];
//    reg signed [31:0] tpl3 [0:DATA_N-1];
//    reg signed [31:0] tpl4 [0:DATA_N-1];
//
//    initial begin
//        $readmemh("template_1_30frame_mfcc1_12_q810_hex.hex", tpl1);
//        $readmemh("template_2_30frame_mfcc1_12_q810_hex.hex", tpl2);
//        $readmemh("template_3_30frame_mfcc1_12_q810_hex.hex", tpl3);
//        $readmemh("template_4_30frame_mfcc1_12_q810_hex.hex", tpl4);
//    end
//
//    reg signed [31:0] frame_buf [0:11];
//    reg buffer_full;
//    reg new_frame_ready;
//
//    reg [63:0] prev [0:FRAME_N];
//    reg [63:0] curr [0:FRAME_N];
//    reg [63:0] dist [1:4];
//
//    reg [5:0] i, j;
//    reg [3:0] k;
//    reg [2:0] tpl_id;
//
//    reg signed [31:0] a_reg;
//    reg signed [31:0] b_reg;
//    reg signed [32:0] diff_reg;
//    reg [65:0] diff_sq;
//    reg [63:0] cost_acc;
//    reg [63:0] min_prev;
//
//    reg [63:0] best_tmp;
//    reg [2:0] result_tmp;
//
//    integer p, c;
//
//    function signed [31:0] get_template;
//        input [2:0] id;
//        input [8:0] addr;
//        begin
//            case(id)
//                3'd1: get_template = tpl1[addr];
//                3'd2: get_template = tpl2[addr];
//                3'd3: get_template = tpl3[addr];
//                3'd4: get_template = tpl4[addr];
//                default: get_template = 32'sd0;
//            endcase
//        end
//    endfunction
//
//    function [63:0] min3;
//        input [63:0] x;
//        input [63:0] y;
//        input [63:0] z;
//        begin
//            if(x <= y && x <= z)
//                min3 = x;
//            else if(y <= x && y <= z)
//                min3 = y;
//            else
//                min3 = z;
//        end
//    endfunction
//
//    localparam IDLE       = 5'd0;
//    localparam INIT       = 5'd1;
//    localparam ROW_INIT   = 5'd2;
//    localparam COST_INIT  = 5'd3;
//    localparam LOAD_AB    = 5'd4;
//    localparam CALC_DIFF  = 5'd5;
//    localparam CALC_SQ    = 5'd6;
//    localparam COST_ACC   = 5'd7;
//    localparam CELL_DONE  = 5'd8;
//    localparam NEXT_CELL  = 5'd9;
//    localparam NEXT_ROW   = 5'd10;
//    localparam SAVE_DIST  = 5'd11;
//    localparam NEXT_TPL   = 5'd12;
//    localparam FIND_BEST  = 5'd13;
//    localparam DONE       = 5'd14;
//
//    reg [4:0] state;
//
//    always @(posedge clk or negedge rst) begin
//        if(!rst) begin
//            frame_count     <= 6'd0;
//            buffer_full     <= 1'b0;
//            new_frame_ready <= 1'b0;
//
//            result          <= 3'd0;
//            recog_valid     <= 1'b0;
//            recog_done      <= 1'b0;
//            best_distance   <= 64'd0;
//
//            i <= 6'd0;
//            j <= 6'd0;
//            k <= 4'd0;
//            tpl_id <= 3'd1;
//
//            cost_acc <= 64'd0;
//            state <= IDLE;
//        end
//        else begin
//            new_frame_ready <= 1'b0;
//            recog_done      <= 1'b0;
//            recog_valid     <= 1'b0;
//
//            // =====================================================
//            // Nhận 1 frame MFCC: chỉ lấy MFCC1 -> MFCC12
//            // =====================================================
//            if(mfcc_valid && mfcc_index >= 4'd1 && mfcc_index <= 4'd12) begin
//                frame_buf[mfcc_index - 1'b1] <= mfcc_in;
//
//                if(mfcc_index == 4'd12) begin
//
//                    // Dịch buffer 30 frame
//                    for(p = 0; p < FRAME_N-1; p = p + 1) begin
//                        for(c = 0; c < MFCC_N; c = c + 1) begin
//                            input_mem[p*MFCC_N + c] <= input_mem[(p+1)*MFCC_N + c];
//                        end
//                    end
//
//                    // Ghi frame mới nhất vào cuối buffer
//                    for(c = 0; c < MFCC_N; c = c + 1) begin
//                        if(c == 11)
//                            input_mem[(FRAME_N-1)*MFCC_N + c] <= mfcc_in;
//                        else
//                            input_mem[(FRAME_N-1)*MFCC_N + c] <= frame_buf[c];
//                    end
//
//                    if(frame_count < FRAME_N)
//                        frame_count <= frame_count + 1'b1;
//
//                    if(frame_count >= FRAME_N-1) begin
//                        buffer_full     <= 1'b1;
//                        new_frame_ready <= 1'b1;
//                    end
//                end
//            end
//
//            // =====================================================
//            // DTW FSM
//            // =====================================================
//            case(state)
//
//                IDLE: begin
//                    if(buffer_full && new_frame_ready) begin
//                        tpl_id <= 3'd1;
//                        state  <= INIT;
//                    end
//                end
//
//                INIT: begin
//                    prev[0] <= 64'd0;
//
//                    for(p = 1; p <= FRAME_N; p = p + 1)
//                        prev[p] <= INF;
//
//                    i <= 6'd1;
//                    state <= ROW_INIT;
//                end
//
//                ROW_INIT: begin
//                    curr[0] <= INF;
//
//                    // clear curr[1..30] để tránh dữ liệu rác
//                    for(p = 1; p <= FRAME_N; p = p + 1)
//                        curr[p] <= INF;
//
//                    j <= 6'd1;
//                    state <= COST_INIT;
//                end
//
//                COST_INIT: begin
//                    k <= 4'd0;
//                    cost_acc <= 64'd0;
//                    state <= LOAD_AB;
//                end
//
//                LOAD_AB: begin
//                    a_reg <= input_mem[(i-1)*MFCC_N + k];
//                    b_reg <= get_template(tpl_id, (j-1)*MFCC_N + k);
//                    state <= CALC_DIFF;
//                end
//
//                CALC_DIFF: begin
//                    diff_reg <= a_reg - b_reg;
//                    state <= CALC_SQ;
//                end
//
//                CALC_SQ: begin
//                    diff_sq <= diff_reg * diff_reg;
//                    state <= COST_ACC;
//                end
//
//                COST_ACC: begin
//                    cost_acc <= cost_acc + diff_sq[63:0];
//
//                    if(k == MFCC_N-1)
//                        state <= CELL_DONE;
//                    else begin
//                        k <= k + 1'b1;
//                        state <= LOAD_AB;
//                    end
//                end
//
//                CELL_DONE: begin
//                    min_prev = min3(prev[j], curr[j-1], prev[j-1]);
//                    curr[j] <= cost_acc + min_prev;
//                    state <= NEXT_CELL;
//                end
//
//                NEXT_CELL: begin
//                    if(j == FRAME_N) begin
//                        state <= NEXT_ROW;
//                    end
//                    else begin
//                        j <= j + 1'b1;
//                        state <= COST_INIT;
//                    end
//                end
//
//                NEXT_ROW: begin
//                    for(p = 0; p <= FRAME_N; p = p + 1)
//                        prev[p] <= curr[p];
//
//                    if(i == FRAME_N) begin
//                        state <= SAVE_DIST;
//                    end
//                    else begin
//                        i <= i + 1'b1;
//                        state <= ROW_INIT;
//                    end
//                end
//
//                SAVE_DIST: begin
//                    dist[tpl_id] <= curr[FRAME_N];
//                    state <= NEXT_TPL;
//                end
//
//                NEXT_TPL: begin
//                    if(tpl_id == 3'd4) begin
//                        state <= FIND_BEST;
//                    end
//                    else begin
//                        tpl_id <= tpl_id + 1'b1;
//                        state <= INIT;
//                    end
//                end
//
//                FIND_BEST: begin
//                    best_tmp   = dist[1];
//                    result_tmp = 3'd1;
//
//                    if(dist[2] < best_tmp) begin
//                        best_tmp   = dist[2];
//                        result_tmp = 3'd2;
//                    end
//
//                    if(dist[3] < best_tmp) begin
//                        best_tmp   = dist[3];
//                        result_tmp = 3'd3;
//                    end
//
//                    if(dist[4] < best_tmp) begin
//                        best_tmp   = dist[4];
//                        result_tmp = 3'd4;
//                    end
//
//                    best_distance <= best_tmp;
//                    result        <= result_tmp;
//
//                    state <= DONE;
//                end
//
//                DONE: begin
//                    recog_done <= 1'b1;
//
//                    if(best_distance < THRESHOLD)
//                        recog_valid <= 1'b1;
//                    else
//                        recog_valid <= 1'b0;
//
//                    state <= IDLE;
//                end
//
//                default: begin
//                    state <= IDLE;
//                end
//
//            endcase
//        end
//    end
//
//endmodule


