module i2cControllerRTC(
					clock,
					sda,
					scl,
					data,
					start,
					led7seg,
					led7seg2,
					led7min1,
					led7min2,
					led7hour1,
					led7hour2
);
// khai báo đầu vao, đầu ra cho chương trình
input	 clock;
inout  sda;
input start;
output scl;
output [0:6] led7seg;
output [0:6] led7seg2;
output [0:6] led7min1;
output [0:6] led7min2;
output [0:6] led7hour1;
output [0:6] led7hour2;
output [7:0] data;

// khai báo các biến phụ 
reg [7:0]		addr_read;	
reg [7:0]		data_seconds;
reg [7:0]		data_minutes;
reg [7:0]		data_hours;

//parameter [7:0] addr_read_data = 8'b0000_0000;
//parameter [7:0] addr_read_data_minute = 8'b1000_0000;

reg 	[22:0] counter;				
reg	[2:0] counter_update;

// tan so 10hz - quet lan luot lay gia tri thanh ghi RTC
always@(posedge clock)
	begin
		if(counter == 23'd4999999)
			begin
				counter	<= 23'b0;
				counter_update <= counter_update + 1;
			end
		else
			counter <= counter +1;
	end

// VÒNG LẶP GÁN ĐỊA CHỈ MỚI ĐỂ ĐỌC THANH GHI.
always@(posedge clock)
begin
	case(counter_update)
	3'd0: addr_read = 8'b0000_0000;
	3'd1:	data_seconds = data;	
	3'd2: addr_read = 8'b1000_0000;
	3'd3: data_minutes = data;
	3'd4: addr_read = 8'b0100_0000;
	3'd5: data_hours = data;
	
	endcase
end
	
// GOI MODULE CON DE DOC DU LIEU VOI DIA CHI TUONG UNG
i2creadRTC seconds(
				.clk_50mhz(clock),
				.i2c_scl(scl),
				.i2c_sda(sda),
				.data_out(data),
				.addr_read(addr_read),
				.btstart(start)
						);

// HIEN THI LED 7 DOAN VOI DATA SECONDS TUONG UNG NHAN ĐƯỢC
led7seg ledseconds(
		.clk(clock), 
		.data_in(data_seconds),
		.led1(led7seg), 
		.led2(led7seg2)
);

//HIEN THI PHÚT
led7seg ledminutes(
		.clk(clock), 
		.data_in(data_minutes),
		.led1(led7min1), 
		.led2(led7min2)
);

//HIEN THI GIO
led7seg ledhours(
		.clk(clock), 
		.data_in(data_hours),
		.led1(led7hour1), 
		.led2(led7hour2)
); 

endmodule



//
//
//
//// -------------------------------------------------
//// Top: i2cControllerRTC.v
//// -------------------------------------------------
//module i2cControllerRTC(
//    input  wire       clock,         // 50 MHz
//    input  wire       reset_n,       // active low reset (thêm)
//    inout  wire       sda,
//    output wire       scl,
//    output wire [0:6] led7seg,
//    output wire [0:6] led7seg2,
//    output wire [0:6] led7min1,
//    output wire [0:6] led7min2,
//    output wire [0:6] led7hour1,
//    output wire [0:6] led7hour2,
//    output wire [7:0] data           // last read data (for debug)
//);
//
//    // internal registers
//    reg  [7:0] addr_read;
//    reg  [7:0] data_seconds;
//    reg  [7:0] data_minutes;
//    reg  [7:0] data_hours;
//
//    // counters
//    reg [22:0] counter;
//    reg [2:0]  counter_update;
//
//    // divider: tạo xung đọc tần suất chậm (ví dụ ~10 Hz)
//    // giả sử clock = 50 MHz -> 50_000_000 / 10 = 5_000_000 -> counter max 4_999_999
//    always @(posedge clock or negedge reset_n) begin
//        if (!reset_n) begin
//            counter <= 23'd0;
//            counter_update <= 3'd0;
//        end else begin
//            if (counter == 23'd4_999_999) begin
//                counter <= 23'd0;
//                counter_update <= counter_update + 1'b1;
//            end else begin
//                counter <= counter + 1'b1;
//            end
//        end
//    end
//
//    // vòng lặp gán địa chỉ / đọc data
//    always @(posedge clock or negedge reset_n) begin
//        if (!reset_n) begin
//            addr_read <= 8'h00;
//            data_seconds <= 8'h00;
//            data_minutes <= 8'h00;
//            data_hours   <= 8'h00;
//        end else begin
//            case (counter_update)
//                3'd0: addr_read <= 8'h00;        // seconds register
//                3'd1: data_seconds <= data;      // ghi giá trị read lên reg seconds
//                3'd2: addr_read <= 8'h01;        // minutes register
//                3'd3: data_minutes <= data;
//                3'd4: addr_read <= 8'h02;        // hours register
//                3'd5: data_hours <= data;
//                default: begin end
//            endcase
//        end
//    end
//
//    // instantiate i2c reader
//    wire [7:0] data_out;
//    wire busy;
//    wire done;
//
//    i2creadRTC i2c_reader (
//        .clk_50mhz(clock),
//        .reset_n(reset_n),
//        .i2c_scl(scl),
//        .i2c_sda(sda),
//        .data_out(data_out),
//        .addr_read(addr_read),
//        .start_read(1'b1)   // auto start: reader will sample addr_read whenever not busy
//    );
//
//    // expose last byte for debugging
//    assign data = data_out;
//
//    // hiển thị: mình giả sử bạn đã có module led7seg (giữ nguyên tên).
//    // Chỉ map data_seconds/minutes/hours (BCD). Nếu data ở dạng BCD thì ok.
//    led7seg ledseconds(
//        .clk(clock),
//        .data_in(data_seconds),
//        .led1(led7seg),
//        .led2(led7seg2)
//    );
//
//    led7seg ledminutes(
//        .clk(clock),
//        .data_in(data_minutes),
//        .led1(led7min1),
//        .led2(led7min2)
//    );
//
//    led7seg ledhours(
//        .clk(clock),
//        .data_in(data_hours),
//        .led1(led7hour1),
//        .led2(led7hour2)
//    );
//
//endmodule
//
//
//// -------------------------------------------------
//// i2creadRTC.v
//// - Đọc 1 byte từ DS1307: sequence write register address, restart, read 1 byte
//// - Tri-state SDA bằng sda_oe flag
//// -------------------------------------------------
//module i2creadRTC (
//    input  wire       clk_50mhz,
//    input  wire       reset_n,
//    output wire       i2c_scl,
//    inout  wire       i2c_sda,
//    output reg  [7:0] data_out,
//    input  wire [7:0] addr_read,
//    input  wire       start_read      // nếu =1: module tự khởi một vòng đọc mỗi khi rảnh
//);
//
//    // parameters
//    localparam CLK_FREQ = 50_000_000;
//    localparam I2C_FREQ = 100_000;
//    localparam integer DIV = (CLK_FREQ / (I2C_FREQ * 2)); // toggle every DIV clk to get SCL
//
//    // clock divider to generate scl clock (internal)
//    reg [15:0] div_cnt;
//    reg        scl_clk;    // internal SCL toggle (not directly drive SCL on bus because we need START/STOP timing)
//    wire       scl = i2c_scl;
//
//    // SDA tri-state handling
//    reg        sda_out;    // value to drive
//    reg        sda_oe;     // output enable: 1 -> drive sda_out, 0 -> release (hi-Z)
//    wire       sda_in;
//    assign i2c_sda = sda_oe ? sda_out : 1'bz;
//    assign sda_in   = i2c_sda;
//
//    // drive scl as reg->wire
//    reg scl_drive;
//    assign i2c_scl = scl_drive;
//
//    // FSM states
//    reg [7:0] state;
//    reg [7:0] bit_cnt;
//    reg [7:0] shifter;
//    reg busy;
//    reg done;
//
//    // device address for DS1307: 7'h68 -> write 0xD0, read 0xD1
//    localparam [6:0] DEV = 7'h68;
//
//    // simple clk divider to generate SCL timing ticks
//    always @(posedge clk_50mhz or negedge reset_n) begin
//        if (!reset_n) begin
//            div_cnt <= 0;
//            scl_clk <= 1'b1;
//        end else begin
//            if (div_cnt >= (DIV - 1)) begin
//                div_cnt <= 0;
//                scl_clk <= ~scl_clk;
//            end else begin
//                div_cnt <= div_cnt + 1'b1;
//            end
//        end
//    end
//
//    // FSM: states meaningful names
//    localparam ST_IDLE      = 8'd0;
//    localparam ST_START     = 8'd1;
//    localparam ST_DEV_W     = 8'd2; // dev + write bit
//    localparam ST_REG       = 8'd3; // send register addr
//    localparam ST_RESTART   = 8'd4;
//    localparam ST_DEV_R     = 8'd5; // dev + read bit
//    localparam ST_READ_BYTE = 8'd6; // read 8 bits
//    localparam ST_NACK_STOP = 8'd7;
//    localparam ST_DONE      = 8'd8;
//    localparam ST_WAIT_HALF = 8'd9; // small delay state to align edges
//
//    // For reliable SCL edges, we step FSM on falling edge of scl_clk (or posedge), simpler: step on scl_clk posedge
//    reg scl_clk_prev;
//    wire scl_posedge = (scl_clk & ~scl_clk_prev);
//    always @(posedge clk_50mhz) scl_clk_prev <= scl_clk;
//
//    // Start FSM
//    always @(posedge clk_50mhz or negedge reset_n) begin
//        if (!reset_n) begin
//            state <= ST_IDLE;
//            sda_out <= 1'b1;
//            sda_oe  <= 1'b1;   // idle drive high
//            scl_drive <= 1'b1;
//            busy <= 1'b0;
//            done <= 1'b0;
//            data_out <= 8'h00;
//            bit_cnt <= 0;
//            shifter <= 8'h00;
//        end else begin
//            done <= 1'b0;
//            case (state)
//                ST_IDLE: begin
//                    sda_out <= 1'b1; sda_oe <= 1'b1;
//                    scl_drive <= 1'b1;
//                    busy <= 1'b0;
//                    if (start_read) begin
//                        state <= ST_START;
//                        busy <= 1'b1;
//                    end
//                end
//
//                // START condition: SDA goes low while SCL high
//                ST_START: begin
//                    sda_out <= 1'b1; sda_oe <= 1'b1; scl_drive <= 1'b1;
//                    // ensure both high, then pull SDA low
//                    sda_out <= 1'b0; sda_oe <= 1'b1;
//                    // wait a little then go to sending device+W
//                    state <= ST_DEV_W;
//                    // prepare device + write bit (0)
//                    shifter <= {DEV, 1'b0};
//                    bit_cnt <= 7;
//                end
//
//                // send device address + W (MSB first)
//                ST_DEV_W: begin
//                    // toggle SCL manually based on scl_clk: on falling edge we change SDA, on rising edge we leave
//                    if (scl_posedge) begin
//                        // rising edge: nothing
//                    end else if (~scl_clk) begin
//                        // place next bit while SCL low
//                        sda_out <= shifter[bit_cnt];
//                        if (bit_cnt == 0) begin
//                            state <= ST_WAIT_HALF;
//                            // next will be ACK (release SDA)
//                        end else begin
//                            bit_cnt <= bit_cnt - 1;
//                        end
//                    end
//                    // drive scl to follow scl_clk
//                    scl_drive <= scl_clk;
//                end
//
//                // small WAIT to release SDA for ACK: use ST_WAIT_HALF to align
//                ST_WAIT_HALF: begin
//                    // release SDA for ACK
//                    sda_oe <= 1'b0; // release (hi-Z), slave drives ACK
//                    scl_drive <= scl_clk;
//                    // on next transition go to REG state
//                    if (scl_posedge) begin
//                        // after ACK cycle, grab ACK (optional)
//                        sda_oe <= 1'b1; // re-take control
//                        sda_out <= 1'b0; // default
//                        // send register address
//                        shifter <= addr_read;
//                        bit_cnt <= 7;
//                        state <= ST_REG;
//                    end
//                end
//
//                // send register address (8 bits)
//                ST_REG: begin
//                    scl_drive <= scl_clk;
//                    if (~scl_clk) begin
//                        sda_out <= shifter[bit_cnt];
//                        if (bit_cnt == 0) begin
//                            state <= ST_RESTART;
//                        end else bit_cnt <= bit_cnt - 1;
//                    end
//                end
//
//                // RESTART sequence: SDA high, SCL high, SDA low again
//                ST_RESTART: begin
//                    // drive SDA high then low with scl high
//                    sda_out <= 1'b1; sda_oe <= 1'b1;
//                    scl_drive <= 1'b1;
//                    // then pull SDA low (start again)
//                    sda_out <= 1'b0;
//                    // prepare device + read bit
//                    shifter <= {DEV, 1'b1};
//                    bit_cnt <= 7;
//                    state <= ST_DEV_R;
//                end
//
//                // send device + READ bit
//                ST_DEV_R: begin
//                    scl_drive <= scl_clk;
//                    if (~scl_clk) begin
//                        sda_out <= shifter[bit_cnt];
//                        if (bit_cnt == 0) begin
//                            // release SDA for ACK then start reading
//                            sda_oe <= 1'b0; // release to let slave ACK
//                            state <= ST_READ_BYTE;
//                            bit_cnt <= 7;
//                            shifter <= 8'h00;
//                        end else bit_cnt <= bit_cnt - 1;
//                    end
//                end
//
//                // read 8 bits from slave (on SDA) MSB first
//                ST_READ_BYTE: begin
//                    scl_drive <= scl_clk;
//                    // ensure SDA released
//                    sda_oe <= 1'b0;
//                    if (scl_posedge) begin
//                        // sample on rising edge
//                        shifter[bit_cnt] <= sda_in;
//                        if (bit_cnt == 0) begin
//                            // after reading byte, send NACK and STOP
//                            data_out <= shifter;
//                            sda_oe <= 1'b1;
//                            sda_out <= 1'b1; // NACK (release or drive high)
//                            state <= ST_NACK_STOP;
//                        end else begin
//                            bit_cnt <= bit_cnt - 1;
//                        end
//                    end
//                end
//
//                ST_NACK_STOP: begin
//                    // issue STOP: while SCL high, SDA goes 0->1
//                    scl_drive <= 1'b1;
//                    sda_out <= 1'b0; sda_oe <= 1'b1;
//                    // small delay then release SDA to produce stop
//                    // next step: release SDA to 1 (stop)
//                    sda_out <= 1'b1; sda_oe <= 1'b1;
//                    state <= ST_DONE;
//                end
//
//                ST_DONE: begin
//                    busy <= 1'b0;
//                    done <= 1'b1;
//                    state <= ST_IDLE;
//                end
//
//                default: state <= ST_IDLE;
//            endcase
//        end
//    end
//
//endmodule
