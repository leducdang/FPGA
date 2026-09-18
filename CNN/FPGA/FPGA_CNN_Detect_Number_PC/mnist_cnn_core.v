module mnist_cnn_core (
    input  wire        clk,
    input  wire        reset_n,

    input  wire        start,

    input  wire        pixel_valid,
    input  wire [7:0]  pixel_in,
    output wire        pixel_ready,

    output reg         busy,
    output reg         done,
    output reg  [3:0]  digit,
    output reg  [3:0]  debug_state
);

    // =========================================================
    // State machine
    // =========================================================
    localparam S_IDLE   = 4'd0;
    localparam S_LOAD   = 4'd1;
    localparam S_CONV1  = 4'd2;
    localparam S_POOL1  = 4'd3;
    localparam S_CONV2  = 4'd4;
    localparam S_POOL2  = 4'd5;
    localparam S_FC     = 4'd6;
    localparam S_ARGMAX = 4'd7;
    localparam S_DONE   = 4'd8;

    reg [3:0] state;

    assign pixel_ready = (state == S_LOAD);

    // =========================================================
    // Bộ nhớ ảnh và feature map
    // Dữ liệu dùng Q8.8
    // pixel 0..255 được xem gần đúng là Q8.8 của pixel/255
    // =========================================================

    reg signed [31:0] image [0:783];      // 28*28

    reg signed [31:0] conv1 [0:1727];     // 24*24*3
    reg signed [31:0] pool1 [0:431];      // 12*12*3

    reg signed [31:0] conv2 [0:191];      // 8*8*3
    reg signed [31:0] pool2 [0:47];       // 4*4*3

    reg signed [31:0] score [0:9];        // 10 output scores

    // =========================================================
    // Trọng số Q8.8
    // Thứ tự file phải đúng theo Keras:
    // Conv:  [kh][kw][in_channel][out_channel]
    // FC:    [input_index][class]
    // =========================================================

    reg signed [15:0] conv1_w [0:74];     // 5*5*1*3
    reg signed [15:0] conv1_b [0:2];

    reg signed [15:0] conv2_w [0:224];    // 5*5*3*3
    reg signed [15:0] conv2_b [0:2];

    reg signed [15:0] fc_w [0:479];       // 48*10
    reg signed [15:0] fc_b [0:9];

    initial begin
        $readmemh("conv1_w_q88.hex", conv1_w);
        $readmemh("conv1_b_q88.hex", conv1_b);

        $readmemh("conv2_w_q88.hex", conv2_w);
        $readmemh("conv2_b_q88.hex", conv2_b);

        $readmemh("fc_w_q88.hex", fc_w);
        $readmemh("fc_b_q88.hex", fc_b);
    end

    // =========================================================
    // Counter xử lý
    // =========================================================

    reg [9:0] load_cnt;

    reg [4:0] row;
    reg [4:0] col;
    reg [1:0] ch;
    reg [3:0] cls;

    integer kh;
    integer kw;
    integer ic;
    integer i;

    reg signed [63:0] acc;
    reg signed [31:0] max_val;

    reg signed [31:0] best_score;
    reg [3:0] best_digit;

    // =========================================================
    // Hàm index dùng layout channels-last:
    // Tensor Keras: row, col, channel
    // =========================================================

    function integer idx_image;
        input integer r;
        input integer c;
        begin
            idx_image = r * 28 + c;
        end
    endfunction

    function integer idx_conv1;
        input integer r;
        input integer c;
        input integer oc;
        begin
            idx_conv1 = (r * 24 + c) * 3 + oc;
        end
    endfunction

    function integer idx_pool1;
        input integer r;
        input integer c;
        input integer oc;
        begin
            idx_pool1 = (r * 12 + c) * 3 + oc;
        end
    endfunction

    function integer idx_conv2;
        input integer r;
        input integer c;
        input integer oc;
        begin
            idx_conv2 = (r * 8 + c) * 3 + oc;
        end
    endfunction

    function integer idx_pool2;
        input integer r;
        input integer c;
        input integer oc;
        begin
            idx_pool2 = (r * 4 + c) * 3 + oc;
        end
    endfunction

    function integer idx_conv1_w;
        input integer khr;
        input integer kwc;
        input integer oc;
        begin
            // shape Keras: 5,5,1,3
            idx_conv1_w = (khr * 5 + kwc) * 3 + oc;
        end
    endfunction

    function integer idx_conv2_w;
        input integer khr;
        input integer kwc;
        input integer in_ch;
        input integer out_ch;
        begin
            // shape Keras: 5,5,3,3
            idx_conv2_w = (((khr * 5 + kwc) * 3 + in_ch) * 3 + out_ch);
        end
    endfunction

    function integer idx_fc_w;
        input integer input_idx;
        input integer out_class;
        begin
            // Dense weight Keras shape: 48,10
            idx_fc_w = input_idx * 10 + out_class;
        end
    endfunction

    // =========================================================
    // Main FSM
    // =========================================================

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            state       <= S_IDLE;
            busy        <= 1'b0;
            done        <= 1'b0;
            digit       <= 4'd0;
            debug_state <= S_IDLE;

            load_cnt    <= 10'd0;
            row         <= 5'd0;
            col         <= 5'd0;
            ch          <= 2'd0;
            cls         <= 4'd0;

            best_score  <= 32'sd0;
            best_digit  <= 4'd0;
        end else begin
            debug_state <= state;

            case (state)

                // -------------------------------------------------
                // IDLE
                // -------------------------------------------------
                S_IDLE: begin
                    done <= 1'b0;
                    busy <= 1'b0;

                    if (start) begin
                        busy     <= 1'b1;
                        load_cnt <= 10'd0;
                        state    <= S_LOAD;
                    end
                end

                // -------------------------------------------------
                // LOAD IMAGE
                // Nhận 784 pixel ảnh 28x28
                // -------------------------------------------------
                S_LOAD: begin
                    if (pixel_valid) begin
                        // pixel_in 0..255, xem như Q8.8 gần đúng
                        image[load_cnt] <= {24'd0, pixel_in};

                        if (load_cnt == 10'd783) begin
                            row   <= 5'd0;
                            col   <= 5'd0;
                            ch    <= 2'd0;
                            state <= S_CONV1;
                        end else begin
                            load_cnt <= load_cnt + 10'd1;
                        end
                    end
                end

                // -------------------------------------------------
                // CONV1
                // Input: 28x28x1
                // Kernel: 5x5x1x3
                // Output: 24x24x3
                // -------------------------------------------------
                S_CONV1: begin
                    acc = 64'sd0;

                    for (kh = 0; kh < 5; kh = kh + 1) begin
                        for (kw = 0; kw < 5; kw = kw + 1) begin
                            acc = acc
                                + $signed(image[idx_image(row + kh, col + kw)])
                                * $signed(conv1_w[idx_conv1_w(kh, kw, ch)]);
                        end
                    end

                    // Q16.16 -> Q8.8, sau đó cộng bias Q8.8
                    acc = (acc >>> 8) + $signed(conv1_b[ch]);

                    // ReLU
                    if (acc < 0)
                        conv1[idx_conv1(row, col, ch)] <= 32'sd0;
                    else
                        conv1[idx_conv1(row, col, ch)] <= acc[31:0];

                    // tăng index
                    if (ch == 2'd2) begin
                        ch <= 2'd0;

                        if (col == 5'd23) begin
                            col <= 5'd0;

                            if (row == 5'd23) begin
                                row   <= 5'd0;
                                col   <= 5'd0;
                                ch    <= 2'd0;
                                state <= S_POOL1;
                            end else begin
                                row <= row + 5'd1;
                            end
                        end else begin
                            col <= col + 5'd1;
                        end
                    end else begin
                        ch <= ch + 2'd1;
                    end
                end

                // -------------------------------------------------
                // POOL1
                // Input: 24x24x3
                // MaxPool 2x2
                // Output: 12x12x3
                // -------------------------------------------------
                S_POOL1: begin
                    max_val = conv1[idx_conv1(row * 2,     col * 2,     ch)];

                    if (conv1[idx_conv1(row * 2,     col * 2 + 1, ch)] > max_val)
                        max_val = conv1[idx_conv1(row * 2,     col * 2 + 1, ch)];

                    if (conv1[idx_conv1(row * 2 + 1, col * 2,     ch)] > max_val)
                        max_val = conv1[idx_conv1(row * 2 + 1, col * 2,     ch)];

                    if (conv1[idx_conv1(row * 2 + 1, col * 2 + 1, ch)] > max_val)
                        max_val = conv1[idx_conv1(row * 2 + 1, col * 2 + 1, ch)];

                    pool1[idx_pool1(row, col, ch)] <= max_val;

                    if (ch == 2'd2) begin
                        ch <= 2'd0;

                        if (col == 5'd11) begin
                            col <= 5'd0;

                            if (row == 5'd11) begin
                                row   <= 5'd0;
                                col   <= 5'd0;
                                ch    <= 2'd0;
                                state <= S_CONV2;
                            end else begin
                                row <= row + 5'd1;
                            end
                        end else begin
                            col <= col + 5'd1;
                        end
                    end else begin
                        ch <= ch + 2'd1;
                    end
                end

                // -------------------------------------------------
                // CONV2
                // Input: 12x12x3
                // Kernel: 5x5x3x3
                // Output: 8x8x3
                // -------------------------------------------------
                S_CONV2: begin
                    acc = 64'sd0;

                    for (kh = 0; kh < 5; kh = kh + 1) begin
                        for (kw = 0; kw < 5; kw = kw + 1) begin
                            for (ic = 0; ic < 3; ic = ic + 1) begin
                                acc = acc
                                    + $signed(pool1[idx_pool1(row + kh, col + kw, ic)])
                                    * $signed(conv2_w[idx_conv2_w(kh, kw, ic, ch)]);
                            end
                        end
                    end

                    // Q16.16 -> Q8.8, cộng bias
                    acc = (acc >>> 8) + $signed(conv2_b[ch]);

                    // ReLU
                    if (acc < 0)
                        conv2[idx_conv2(row, col, ch)] <= 32'sd0;
                    else
                        conv2[idx_conv2(row, col, ch)] <= acc[31:0];

                    if (ch == 2'd2) begin
                        ch <= 2'd0;

                        if (col == 5'd7) begin
                            col <= 5'd0;

                            if (row == 5'd7) begin
                                row   <= 5'd0;
                                col   <= 5'd0;
                                ch    <= 2'd0;
                                state <= S_POOL2;
                            end else begin
                                row <= row + 5'd1;
                            end
                        end else begin
                            col <= col + 5'd1;
                        end
                    end else begin
                        ch <= ch + 2'd1;
                    end
                end

                // -------------------------------------------------
                // POOL2
                // Input: 8x8x3
                // MaxPool 2x2
                // Output: 4x4x3
                // -------------------------------------------------
                S_POOL2: begin
                    max_val = conv2[idx_conv2(row * 2,     col * 2,     ch)];

                    if (conv2[idx_conv2(row * 2,     col * 2 + 1, ch)] > max_val)
                        max_val = conv2[idx_conv2(row * 2,     col * 2 + 1, ch)];

                    if (conv2[idx_conv2(row * 2 + 1, col * 2,     ch)] > max_val)
                        max_val = conv2[idx_conv2(row * 2 + 1, col * 2,     ch)];

                    if (conv2[idx_conv2(row * 2 + 1, col * 2 + 1, ch)] > max_val)
                        max_val = conv2[idx_conv2(row * 2 + 1, col * 2 + 1, ch)];

                    pool2[idx_pool2(row, col, ch)] <= max_val;

                    if (ch == 2'd2) begin
                        ch <= 2'd0;

                        if (col == 5'd3) begin
                            col <= 5'd0;

                            if (row == 5'd3) begin
                                cls   <= 4'd0;
                                state <= S_FC;
                            end else begin
                                row <= row + 5'd1;
                            end
                        end else begin
                            col <= col + 5'd1;
                        end
                    end else begin
                        ch <= ch + 2'd1;
                    end
                end

                // -------------------------------------------------
                // FULLY CONNECTED
                // Input: 48
                // Output: 10
                // Mỗi chu kỳ tính 1 class
                // -------------------------------------------------
                S_FC: begin
                    acc = 64'sd0;

                    for (i = 0; i < 48; i = i + 1) begin
                        acc = acc
                            + $signed(pool2[i])
                            * $signed(fc_w[idx_fc_w(i, cls)]);
                    end

                    // Q16.16 -> Q8.8, cộng bias
                    acc = (acc >>> 8) + $signed(fc_b[cls]);

                    score[cls] <= acc[31:0];

                    if (cls == 4'd9) begin
                        cls         <= 4'd0;
                        best_score  <= score[0];
                        best_digit  <= 4'd0;
                        state       <= S_ARGMAX;
                    end else begin
                        cls <= cls + 4'd1;
                    end
                end

                // -------------------------------------------------
                // ARGMAX
                // Không cần Softmax trên FPGA
                // Chỉ cần lấy score lớn nhất
                // -------------------------------------------------
                S_ARGMAX: begin
                    best_score = score[0];
                    best_digit = 4'd0;

                    for (i = 1; i < 10; i = i + 1) begin
                        if (score[i] > best_score) begin
                            best_score = score[i];
                            best_digit = i[3:0];
                        end
                    end

                    digit <= best_digit;
                    state <= S_DONE;
                end

                // -------------------------------------------------
                // DONE
                // -------------------------------------------------
                S_DONE: begin
                    done <= 1'b1;
                    busy <= 1'b0;

                    if (!start) begin
                        state <= S_IDLE;
                    end
                end

                default: begin
                    state <= S_IDLE;
                end

            endcase
        end
    end

endmodule
