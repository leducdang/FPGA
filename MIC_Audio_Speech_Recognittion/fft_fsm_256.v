module fft_fsm_256 (
    input  wire        clk,
    input  wire        reset_n,
    input  wire        start,

    // ===== Sink interface (to FFT)
    output reg         sink_valid,
    input  wire        sink_ready,
    output reg         sink_sop,
    output reg         sink_eop,
    output reg  [15:0] sink_real,
    output wire [15:0] sink_imag,

    // ===== Source interface (from FFT)
    input  wire        source_valid,
    output reg         source_ready,
    input  wire        source_sop,
    input  wire        source_eop,
    input  wire [23:0] source_real,
    input  wire [23:0] source_imag
);

assign sink_imag = 16'd0;

localparam IDLE        = 3'd0;
localparam SEND        = 3'd1;
localparam WAIT_OUTPUT = 3'd2;
localparam READ        = 3'd3;
localparam DONE        = 3'd4;

reg [2:0] state;

reg [8:0] send_cnt;   // 0 → 255
reg [8:0] read_cnt;   // 0 → 255

// Ví dụ RAM chứa frame
reg [15:0] frame_ram [0:255];

// RAM chứa kết quả FFT
reg [23:0] fft_real_ram [0:255];
reg [23:0] fft_imag_ram [0:255];

always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
        state        <= IDLE;
        send_cnt     <= 0;
        read_cnt     <= 0;
        sink_valid   <= 0;
        sink_sop     <= 0;
        sink_eop     <= 0;
        source_ready <= 0;
    end else begin
        case (state)

        //==================================================
        IDLE: begin
            sink_valid   <= 0;
            source_ready <= 0;
            send_cnt     <= 0;
            read_cnt     <= 0;

            if (start)
                state <= SEND;
        end

        //==================================================
        SEND: begin
            if (sink_ready) begin
                sink_valid <= 1;
                sink_real  <= frame_ram[send_cnt];

                sink_sop <= (send_cnt == 0);
                sink_eop <= (send_cnt == 255);

                send_cnt <= send_cnt + 1;

                if (send_cnt == 255)
                    state <= WAIT_OUTPUT;
            end
        end

        //==================================================
        WAIT_OUTPUT: begin
            sink_valid <= 0;
            sink_sop   <= 0;
            sink_eop   <= 0;

            source_ready <= 1;

            if (source_valid && source_sop) begin
                read_cnt <= 0;
                state    <= READ;
            end
        end

        //==================================================
        READ: begin
            if (source_valid && source_ready) begin
                fft_real_ram[read_cnt] <= source_real;
                fft_imag_ram[read_cnt] <= source_imag;

                read_cnt <= read_cnt + 1;

                if (source_eop)
                    state <= DONE;
            end
        end

        //==================================================
        DONE: begin
            source_ready <= 0;
            state <= IDLE;
        end

        endcase
    end
end

endmodule


