module button_counter(
    input  wire clk,
    input  wire KEY0,            // nút nhấn mức thấp
    output reg  [6:0] HEX0       // LED 7 đoạn anode chung
);
//==================================================
// 1. Đồng bộ hóa nút nhấn (tránh metastability)
//==================================================
reg key_sync1, key_sync2;
always @(posedge clk) begin
    key_sync1 <= KEY0;
    key_sync2 <= key_sync1;
end
//==================================================
// 2. Debounce trong 10ms
//==================================================
reg [19:0] debounce_cnt;        // 2^20 / 50M ≈ 20ms
reg stable_key;

always @(posedge clk) begin
    if (key_sync2 != stable_key) begin
        debounce_cnt <= debounce_cnt + 1;
        if (debounce_cnt == 20'd500000) begin // ~10ms
            stable_key <= key_sync2;
            debounce_cnt <= 0;
        end
    end else begin
        debounce_cnt <= 0;
    end
end

//==================================================
// 3. Edge detector (phát hiện nhấn 1 lần)
// KEY0 = 0 (nhấn) nên dùng cạnh xuống
//==================================================
reg stable_d1;
wire press_pulse;
always @(posedge clk)
    stable_d1 <= stable_key;
assign press_pulse = (stable_d1 == 1 && stable_key == 0);
//==================================================
// 4. Bộ đếm từ 0 → 9
//==================================================
reg [3:0] count;
always @(posedge clk) begin
    if (press_pulse) begin
        if (count == 9)
            count <= 0;
        else
            count <= count + 1;
    end
end
//==================================================
// 5. Giải mã LED 7 đoạn (anode chung)
//==================================================
always @(*) begin
    case (count)
        4'd0: HEX0 = 7'b1000000;
        4'd1: HEX0 = 7'b1111001;
        4'd2: HEX0 = 7'b0100100;
        4'd3: HEX0 = 7'b0110000;
        4'd4: HEX0 = 7'b0011001;
        4'd5: HEX0 = 7'b0010010;
        4'd6: HEX0 = 7'b0000010;
        4'd7: HEX0 = 7'b1111000;
        4'd8: HEX0 = 7'b0000000;
        4'd9: HEX0 = 7'b0010000;
        default: HEX0 = 7'b1111111;
    endcase
end
endmodule
