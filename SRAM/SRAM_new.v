module SRAM_new(
    input               clock_50mhz,
    output      [19:0]  pinAddr,
    inout       [15:0]  pinData,
    output              pinCE,
    output              pinOE,
    output              pinWE,
    output              pinUB,
    output              pinLB,
    input       [15:0]  pinSW,
    output      [15:0]  pinLED,
    input               pinRead,
    input               pinWrite,
    input               pinReset,
    input       [1:0]   input_sw_Addr
);

// ==============================
// Các thanh ghi điều khiển SRAM
// ==============================
reg CE, OE, WE;
reg UB, LB;

// ==============================
// Thanh ghi dữ liệu & địa chỉ
// ==============================
reg [19:0] addr;
reg [15:0] dataWrite;
reg [15:0] dataRead;

// ==============================
// FSM WRITE
// ==============================
localparam W_IDLE  = 3'd0;
localparam W_SETUP = 3'd1;
localparam W_WRITE = 3'd2;
localparam W_HOLD  = 3'd3;
localparam W_DONE  = 3'd4;


// ==============================
// FSM READ
// ==============================
// Định nghĩa các trạng thái FSM
localparam R_IDLE      = 3'd0;
localparam R_TRISTATE  = 3'd1;
localparam R_SETUP     = 3'd2;
localparam R_READ      = 3'd3;
localparam R_DONE      = 3'd4;

reg [2:0] stW, stR;


// =====================================================
// MAIN PROCESS
// =====================================================
always @(posedge clock_50mhz or negedge pinReset) begin
    if (!pinReset) begin
        stW <= W_IDLE;
        stR <= R_IDLE;

        CE <= 1; OE <= 1; WE <= 1;
        UB <= 1; LB <= 1;

        dataWrite <= 16'hZZZZ;
    end
    else begin
        
        // ==============================
        // FSM GHI DỮ LIỆU
        // ==============================
        case (stW)

            W_IDLE: begin
                if (!pinWrite) begin
                    dataWrite <= pinSW;
                    stW <= W_SETUP;
                end
            end

            W_SETUP: begin
                CE <= 0; WE <= 0; UB <= 0; LB <= 0;
                stW <= W_WRITE;
            end

            W_WRITE: begin
                stW <= W_HOLD; // giữ 1 chu kỳ
            end

            W_HOLD: begin
                CE <= 1; WE <= 1; UB <= 1; LB <= 1;
                stW <= W_DONE;
            end

            W_DONE: begin
                stW <= W_IDLE;
            end
        endcase


        // ==============================
        // FSM ĐỌC DỮ LIỆU
        // ==============================
        case (stR)

            R_IDLE: begin
                if (!pinRead) begin
                    dataWrite <= 16'hZZZZ;   // thả bus
                    stR <= R_TRISTATE;
                end
            end

            R_TRISTATE: begin
                CE <= 0; OE <= 0; UB <= 0; LB <= 0;
                stR <= R_SETUP;
            end

            R_SETUP: begin
                stR <= R_READ; // chờ ổn định 1 chu kỳ
            end

            R_READ: begin
                dataRead <= pinData;
                stR <= R_DONE;
            end

            R_DONE: begin
                CE <= 1; OE <= 1; UB <= 1; LB <= 1;
                stR <= R_IDLE;
            end
        endcase


        // ==============================
        // Chọn địa chỉ
        // ==============================
        case (input_sw_Addr)
            2'b00: addr <= 20'd0;
            2'b01: addr <= 20'd1;
            2'b10: addr <= 20'd2;
            2'b11: addr <= 20'd3;
        endcase

    end
end


// ==============================
// Gán tín hiệu ra
// ==============================
assign pinAddr = addr;
assign pinData = (stR == R_IDLE || stR == R_DONE) ? dataWrite : 16'hZZZZ; // tránh bus xung đột

assign pinCE  = CE;
assign pinOE  = OE;
assign pinWE  = WE;
assign pinUB  = UB;
assign pinLB  = LB;

assign pinLED = dataRead;

endmodule
