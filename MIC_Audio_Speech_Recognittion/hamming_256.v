module hamming_256 (
    input  wire clk,
    input  wire rst,          // active low reset

    input  wire ham_run,
    input  wire [7:0] index,  // 0 -> 255
    input  wire signed [15:0] x_in,

    output reg  signed [15:0] y_out,
    output reg  ham_done
);

    reg [15:0] hamming_rom [0:255];

    reg signed [15:0] x_reg;
    reg signed [31:0] mult_reg;

    reg [1:0] state;

    localparam IDLE = 2'd0;
    localparam MUL  = 2'd1;
    localparam OUT  = 2'd2;
    localparam DONE = 2'd3;

    initial begin
        $readmemh("hamming_256.hex", hamming_rom);
    end

    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            state    <= IDLE;
            x_reg    <= 16'sd0;
            mult_reg <= 32'sd0;
            y_out    <= 16'sd0;
            ham_done <= 1'b0;
        end
        else begin
            ham_done <= 1'b0;

            case(state)

                IDLE: begin
                    if(ham_run) begin
                        x_reg <= x_in;
                        state <= MUL;
                    end
                end

                MUL: begin
                    mult_reg <= x_reg * $signed({1'b0, hamming_rom[index]});
                    state    <= OUT;
                end

                OUT: begin
                    y_out <= mult_reg >>> 15;
                    state <= DONE;
                end

                DONE: begin
                    ham_done <= 1'b1;

                    // chờ ham_run hạ xuống rồi mới nhận mẫu mới
                    if(!ham_run)
                        state <= IDLE;
                end

                default: begin
                    state <= IDLE;
                end

            endcase
        end
    end

endmodule

