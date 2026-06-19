//module DCT13 (
//    input  wire clk,
//    input  wire rst,          // active low
//
//    input  wire log_valid,
//    input  wire [4:0] log_index,       // 0 -> 19
//    input  wire signed [23:0] log_in,
//
//    input  wire dct_start,
//
//    output reg signed [31:0] mfcc_out,
//    output reg [3:0] mfcc_index,       // 0 -> 12
//    output reg mfcc_valid,
//    output reg dct_done
//);
//
//    reg signed [23:0] log_mem [0:19];
//    reg signed [23:0] coef_rom [0:259]; // 13*20 = 260
//
//    reg [4:0] n;
//    reg [3:0] k;
//
//    reg signed [47:0] acc;
//
//    wire signed [31:0] mult;
//    wire signed [47:0] acc_next;
//
//    assign mult = log_mem[n] * coef_rom[k*20 + n];
//    assign acc_next = acc + {{16{mult[31]}}, mult};
//
//    localparam IDLE = 2'd0;
//    localparam MAC  = 2'd1;
//    localparam OUT  = 2'd2;
//    localparam DONE = 2'd3;
//
//    reg [1:0] state;
//
//    initial begin
//        $readmemh("dct_13x20_q14.hex", coef_rom);
//    end
//
//    always @(posedge clk or negedge rst) begin
//        if(!rst) begin
//            state      <= IDLE;
//            n          <= 0;
//            k          <= 0;
//            acc        <= 0;
//            mfcc_out   <= 0;
//            mfcc_index <= 0;
//            mfcc_valid <= 0;
//            dct_done   <= 0;
//        end
//        else begin
//            mfcc_valid <= 0;
//            dct_done   <= 0;
//
//            // Lưu 20 giá trị log2 Mel
//            if(log_valid) begin
//                log_mem[log_index] <= log_in;
//            end
//
//            case(state)
//
//                IDLE: begin
//                    if(dct_start) begin
//                        k     <= 0;
//                        n     <= 0;
//                        acc   <= 0;
//                        state <= MAC;
//                    end
//                end
//
//                MAC: begin
//                    acc <= acc_next;
//
//                    if(n == 5'd19) begin
//                        state <= OUT;
//                    end
//                    else begin
//                        n <= n + 1'b1;
//                    end
//                end
//
//                OUT: begin
//                    mfcc_out   <= acc >>> 14; // do hệ số Q2.14
//                    mfcc_index <= k;
//                    mfcc_valid <= 1'b1;
//
//                    if(k == 4'd12) begin
//                        state <= DONE;
//                    end
//                    else begin
//                        k     <= k + 1'b1;
//                        n     <= 0;
//                        acc   <= 0;
//                        state <= MAC;
//                    end
//                end
//
//                DONE: begin
//                    dct_done <= 1'b1;
//
//                    if(!dct_start)
//                        state <= IDLE;
//                end
//
//            endcase
//        end
//    end
//
//endmodule

module DCT13 (
    input  wire clk,
    input  wire rst,          // active low

    input  wire log_valid,
    input  wire [4:0] log_index,       // 0 -> 19
    input  wire signed [23:0] log_in,  // Q6.10, 24-bit

    input  wire dct_start,

    output reg signed [31:0] mfcc_out, // Q8.10
    output reg [3:0] mfcc_index,       // 0 -> 12
    output reg mfcc_valid,
    output reg dct_done
);

    reg signed [23:0] log_mem [0:19];
    reg signed [15:0] coef_rom [0:259]; // 13*20 = 260, Q2.14

    reg [4:0] n;
    reg [3:0] k;

    reg signed [55:0] acc;

    wire signed [39:0] mult;
    wire signed [55:0] mult_ext;
    wire signed [55:0] acc_next;

    assign mult     = log_mem[n] * coef_rom[k*20 + n]; // Q6.10 * Q2.14 = Q8.24
    assign mult_ext = {{16{mult[39]}}, mult};
    assign acc_next = acc + mult_ext;

    localparam IDLE = 2'd0;
    localparam MAC  = 2'd1;
    localparam OUT  = 2'd2;
    localparam DONE = 2'd3;

    reg [1:0] state;

    initial begin
        $readmemh("dct_13x20_q14.hex", coef_rom);
    end

    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            state      <= IDLE;
            n          <= 5'd0;
            k          <= 4'd0;
            acc        <= 56'sd0;
            mfcc_out   <= 32'sd0;
            mfcc_index <= 4'd0;
            mfcc_valid <= 1'b0;
            dct_done   <= 1'b0;
        end
        else begin
            mfcc_valid <= 1'b0;
            dct_done   <= 1'b0;

            if(log_valid) begin
                log_mem[log_index] <= log_in;
            end

            case(state)

                IDLE: begin
                    if(dct_start) begin
                        k     <= 4'd0;
                        n     <= 5'd0;
                        acc   <= 56'sd0;
                        state <= MAC;
                    end
                end

                MAC: begin
                    acc <= acc_next;

                    if(n == 5'd19) begin
                        state <= OUT;
                    end
                    else begin
                        n <= n + 1'b1;
                    end
                end

                OUT: begin
                    // acc là Q8.24
                    // dịch phải 14 bit để đưa về Q8.10
                    mfcc_out   <= acc >>> 14;
                    mfcc_index <= k;
                    mfcc_valid <= 1'b1;

                    if(k == 4'd12) begin
                        state <= DONE;
                    end
                    else begin
                        k     <= k + 1'b1;
                        n     <= 5'd0;
                        acc   <= 56'sd0;
                        state <= MAC;
                    end
                end

                DONE: begin
                    dct_done <= 1'b1;

                    if(!dct_start)
                        state <= IDLE;
                end

                default: begin
                    state <= IDLE;
                end

            endcase
        end
    end

endmodule

