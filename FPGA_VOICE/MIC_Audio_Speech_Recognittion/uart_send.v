module uart_send 
(
    input  wire         clk,
    input  wire         reset_n,

    input  wire         start,          // xung bắt đầu gửi
    input  wire [47:0]  data_in,        // dữ liệu lớn nhất 48 bit
    input  wire [2:0]   data_bytes,     // số byte cần gửi: 2,3,4,6
	 output  				UART_TX,
	 input 					UART_RX,

    output reg  [7:0]   uart_data,      // byte đưa vào UART
    output reg          done,           // gửi xong toàn bộ packet
    output reg          busy            // đang gửi packet
);
	 wire       uart_fb;
	 reg        uart_run;
    reg [47:0] shift_reg;
    reg [2:0]  byte_cnt;
    reg [2:0]  state;

    localparam S_IDLE      = 3'd0,
               S_LOAD      = 3'd1,
               S_WAIT_FREE = 3'd2,
               S_START_TX  = 3'd3,
               S_WAIT_BUSY = 3'd4,
               S_WAIT_DONE = 3'd5,
               S_NEXT      = 3'd6;

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            shift_reg <= 48'd0;
            byte_cnt  <= 3'd0;
            uart_run  <= 1'b0;
            uart_data <= 8'd0;
            done      <= 1'b0;
            busy      <= 1'b0;
            state     <= S_IDLE;
        end
        else begin
            // mặc định
//            uart_run <= 1'b0;
//            done     <= 1'b0;

            case (state)
                S_IDLE: begin
                    busy <= 1'b0;
                    if (start) begin
                        state <= S_LOAD;	
                    end
                end

                S_LOAD: begin
                    busy      <= 1'b1;
                    shift_reg <= data_in;
                    byte_cnt  <= 3'd0;
                    state     <= S_WAIT_FREE;
						  done     	<= 1'b0;
                end

                S_WAIT_FREE: begin
                    if (!uart_fb) begin
                        state <= S_START_TX;
                    end
                end

                S_START_TX: begin
                    uart_data <= shift_reg[47:40];   // lấy byte cao nhất trước
                    uart_run  <= 1'b1;
                    state     <= S_WAIT_BUSY;
                end

                S_WAIT_BUSY: begin
                    // chờ UART gửi xong
                    if (uart_fb) begin
                        state <= S_WAIT_DONE;
								uart_run  <= 1'b0;
                    end
                end

                S_WAIT_DONE: begin
                    // chờ UART reset fb để gửi byte ti
                    if (!uart_fb) begin
                        state <= S_NEXT;
                    end
                end

                S_NEXT: begin
                    if (byte_cnt == (data_bytes - 1'b1)) begin
                        done  <= 1'b1;
                        busy  <= 1'b0;
                        state <= S_IDLE;
                    end
                    else begin
                        byte_cnt  <= byte_cnt + 3'd1;
                        shift_reg <= {shift_reg[39:0], 8'd0}; // dịch trái 1 byte
                        state     <= S_WAIT_FREE;
                    end
                end

                default: state <= S_IDLE;
            endcase
        end
    end
	 
uartWrite UART(
				.clock_50mhz(clk),
				.reset(reset_n),
				.data(uart_data),
				.run(uart_run),
				.feedback(uart_fb),
				.tx_pin(UART_TX)
);

endmodule
