module mel_20(
		input  wire                   clk,
		input  wire                   rst_n,

		// -------------------------
		// Receive bins interface
		// -------------------------
		output reg                 	rx_ready, // input flag: "sẵn sàng nhận dữ liệu"
		input  wire                   bin_valid,   // input flag: P[k] valid
		input  wire [31:0]      		bin_data,    // P[k] theo thứ tự k=0..NUM_BINS-1
		input 								rx_send,

		output reg                    rx_done,     // output flag: đã nhận đủ bin

		// -------------------------
		// Calculate control
		// -------------------------
		input  wire                   start_calc,  // input flag: bắt đầu tính (pulse)
		output reg                    calc_done,   // output flag: tính xong

		// -------------------------
		// Readback interface
		// -------------------------
		input  wire                   rd_ready_in, // input flag: sẵn sàng đọc
		output reg                    mel_valid,   // output flag: mel_out valid
		output reg  [4:0]             mel_index,   // 0..19
		output reg  [47:0]   			mel_out,     // mel energy output
		output reg                    read_done    // output flag: đã đọc đủ 20 mel
);

reg [31:0] bin_rx[0:64];
reg [47:0] acc [0:19];

  integer i;

  // =========================================================================
  // FSM
  // =========================================================================
  localparam S_IDLE      = 3'd0;
  localparam S_RECV      = 3'd1;
  localparam S_READY     = 3'd2;
  localparam S_CALC      = 3'd3;
  localparam S_DONE      = 3'd4;
  localparam S_READ      = 3'd5;

  reg [2:0] state;

  // read loop index
  reg [4:0] r_cnt;
  reg [6:0] rx_cnt;
  
  
function automatic [47:0] mul_q15(input [31:0] x, input [15:0] w);
	reg [47:0] p;
		begin
			p = x * w;          // 32x16 -> 48
			mul_q15 = p >> 15;  // Q0.15 scale back
	end
endfunction
  
  
  // =========================================================================
  // Main sequential
  // =========================================================================
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state     <= S_IDLE;
      rx_cnt    <= 7'd0;
      rx_done   <= 1'b0;
      calc_done <= 1'b0;
		rx_ready  <= 1'b1;

      r_cnt     <= 5'd0;
      mel_valid <= 1'b0;
      mel_index <= 5'd0;
      mel_out   <= 48'd0;
      read_done <= 1'b0;

//      for (i = 0; i < 20; i = i + 1) begin
//        acc[i] <= {ACC_WIDTH{1'b0}};
//      end
    end else begin
      // defaults
      mel_valid <= 1'b0;

      case (state)
        // ------------------------------------------------------------
        // IDLE: chờ rx_ready_in để bắt đầu nhận bins
        // ------------------------------------------------------------
        S_IDLE: begin
          rx_done   <= 1'b0;
          calc_done <= 1'b0;
          read_done <= 1'b0;
          rx_cnt    <= 7'd0;
			 rx_ready  <= 1'b1;

          if (rx_send) begin
            state <= S_RECV;
          end
        end

        // ------------------------------------------------------------
        // RECV: nhận NUM_BINS mẫu P[k] theo thứ tự k=0..NUM_BINS-1
        // ------------------------------------------------------------
        S_RECV: 
		  begin
          if (!rx_send) 
				begin
					// nếu bạn hạ rx_ready_in thì coi như dừng nhận và quay lại idle
					state <= S_IDLE;
				end 
			 else 
				case(r_cnt)
					0:if (bin_valid) 
						begin
							bin_rx[rx_cnt] <= bin_data;
							rx_done <= 1'b1;
							r_cnt <= 1;
						end
					1:if(!bin_valid)
						begin	
							rx_cnt <= rx_cnt + 7'd1;
							rx_done <= 1'b0;
							r_cnt <= 2;
							if (rx_cnt >= 64) 
								begin
									state   <= S_READY;
									rx_ready  <= 1'b0;
									r_cnt <= 0;
								end
							else	r_cnt <= 0;
						end
				endcase
        end

        // ------------------------------------------------------------
        // READY: đã nhận đủ bins, chờ start_calc
        // ------------------------------------------------------------
        S_READY: begin
          if (start_calc) begin
            // clear accumulators
            for (i = 0; i < 20; i = i + 1) begin
              acc[i] <= 48'd0;
            end

            r_cnt     <= 5'd0;
            calc_done <= 1'b0;
            state     <= S_CALC;
          end
        end

        // ------------------------------------------------------------
        // CALC: mỗi clock xử lý 1 bin k (đọc P[k] + map -> cộng vào acc)
        // ------------------------------------------------------------
        S_CALC: begin
				case(r_cnt)
					 // mel0 (0-1-2): k=1 weight=1.0
				 5'd0: begin
					acc[0] <= mul_q15(bin_rx[1], 16'd32767);
					r_cnt  <= 5'd1;
				 end
			
				 // mel1 (1-2-3): k=2
				 5'd1: begin
					acc[1] <= mul_q15(bin_rx[2], 16'd32767);
					r_cnt  <= 5'd2;
				 end
			
				 // mel2 (2-3-4): k=3
				 5'd2: begin
					acc[2] <= mul_q15(bin_rx[3], 16'd32767);
					r_cnt  <= 5'd3;
				 end
			
				 // mel3 (3-4-6): k=4(1.0), k=5(0.5)
				 5'd3: begin
					acc[3] <= mul_q15(bin_rx[4], 16'd32767)
							  + mul_q15(bin_rx[5], 16'd16384);
					r_cnt  <= 5'd4;
				 end
			
				 // mel4 (4-6-8): k=5(0.5), k=6(1.0), k=7(0.5)
				 5'd4: begin
					acc[4] <= mul_q15(bin_rx[5], 16'd16384)
							  + mul_q15(bin_rx[6], 16'd32767)
							  + mul_q15(bin_rx[7], 16'd16384);
					r_cnt  <= 5'd5;
				 end
			
				 // mel5 (6-8-9): k=7(0.5), k=8(1.0)
				 5'd5: begin
					acc[5] <= mul_q15(bin_rx[7], 16'd16384)
							  + mul_q15(bin_rx[8], 16'd32767);
					r_cnt  <= 5'd6;
				 end
			
				 // mel6 (8-9-11): k=9(1.0), k=10(0.5)
				 5'd6: begin
					acc[6] <= mul_q15(bin_rx[9],  16'd32767)
							  + mul_q15(bin_rx[10], 16'd16384);
					r_cnt  <= 5'd7;
				 end
			
				 // mel7 (9-11-14): k=10(0.5), k=11(1.0), k=12(2/3), k=13(1/3)
				 5'd7: begin
					acc[7] <= mul_q15(bin_rx[10], 16'd16384)
							  + mul_q15(bin_rx[11], 16'd32767)
							  + mul_q15(bin_rx[12], 16'd21845)
							  + mul_q15(bin_rx[13], 16'd10922);
					r_cnt  <= 5'd8;
				 end
			
				 // mel8 (11-14-16): k=12(1/3), k=13(2/3), k=14(1.0), k=15(0.5)
				 5'd8: begin
					acc[8] <= mul_q15(bin_rx[12], 16'd10922)
							  + mul_q15(bin_rx[13], 16'd21845)
							  + mul_q15(bin_rx[14], 16'd32767)
							  + mul_q15(bin_rx[15], 16'd16384);
					r_cnt  <= 5'd9;
				 end
			
				 // mel9 (14-16-19): k=15(0.5), k=16(1.0), k=17(2/3), k=18(1/3)
				 5'd9: begin
					acc[9] <= mul_q15(bin_rx[15], 16'd16384)
							  + mul_q15(bin_rx[16], 16'd32767)
							  + mul_q15(bin_rx[17], 16'd21845)
							  + mul_q15(bin_rx[18], 16'd10922);
					r_cnt  <= 5'd10;
				 end
			
				 // mel10 (16-19-22): k=17(1/3),18(2/3),19(1),20(2/3),21(1/3)
				 5'd10: begin
					acc[10] <= mul_q15(bin_rx[17], 16'd10922)
								+ mul_q15(bin_rx[18], 16'd21845)
								+ mul_q15(bin_rx[19], 16'd32767)
								+ mul_q15(bin_rx[20], 16'd21845)
								+ mul_q15(bin_rx[21], 16'd10922);
					r_cnt   <= 5'd11;
				 end
			
				 // mel11 (19-22-25): k=20(1/3),21(2/3),22(1),23(2/3),24(1/3)
				 5'd11: begin
					acc[11] <= mul_q15(bin_rx[20], 16'd10922)
								+ mul_q15(bin_rx[21], 16'd21845)
								+ mul_q15(bin_rx[22], 16'd32767)
								+ mul_q15(bin_rx[23], 16'd21845)
								+ mul_q15(bin_rx[24], 16'd10922);
					r_cnt   <= 5'd12;
				 end
			
				 // mel12 (22-25-28): k=23(1/3),24(2/3),25(1),26(2/3),27(1/3)
				 5'd12: begin
					acc[12] <= mul_q15(bin_rx[23], 16'd10922)
								+ mul_q15(bin_rx[24], 16'd21845)
								+ mul_q15(bin_rx[25], 16'd32767)
								+ mul_q15(bin_rx[26], 16'd21845)
								+ mul_q15(bin_rx[27], 16'd10922);
					r_cnt   <= 5'd13;
				 end
			
				 // mel13 (25-28-32): k=26(1/4),27(1/2),28(1),29(3/4),30(1/2),31(1/4)
				 5'd13: begin
					acc[13] <= mul_q15(bin_rx[26], 16'd8192)
								+ mul_q15(bin_rx[27], 16'd16384)
								+ mul_q15(bin_rx[28], 16'd32767)
								+ mul_q15(bin_rx[29], 16'd24576)
								+ mul_q15(bin_rx[30], 16'd16384)
								+ mul_q15(bin_rx[31], 16'd8192);
					r_cnt   <= 5'd14;
				 end
			
				 // mel14 (28-32-36): k=29(1/4),30(1/2),31(3/4),32(1),33(3/4),34(1/2),35(1/4)
				 5'd14: begin
					acc[14] <= mul_q15(bin_rx[29], 16'd8192)
								+ mul_q15(bin_rx[30], 16'd16384)
								+ mul_q15(bin_rx[31], 16'd24576)
								+ mul_q15(bin_rx[32], 16'd32767)
								+ mul_q15(bin_rx[33], 16'd24576)
								+ mul_q15(bin_rx[34], 16'd16384)
								+ mul_q15(bin_rx[35], 16'd8192);
					r_cnt   <= 5'd15;
				 end
			
				 // mel15 (32-36-41): k=33..40 (theo bảng)
				 5'd15: begin
					acc[15] <= mul_q15(bin_rx[33], 16'd6553)
								+ mul_q15(bin_rx[34], 16'd13107)
								+ mul_q15(bin_rx[35], 16'd19660)
								+ mul_q15(bin_rx[36], 16'd32767)
								+ mul_q15(bin_rx[37], 16'd26214)
								+ mul_q15(bin_rx[38], 16'd19660)
								+ mul_q15(bin_rx[39], 16'd13107)
								+ mul_q15(bin_rx[40], 16'd6553);
					r_cnt   <= 5'd16;
				 end
			
				 // mel16 (36-41-46): k=37..45
				 5'd16: begin
					acc[16] <= mul_q15(bin_rx[37], 16'd6553)
								+ mul_q15(bin_rx[38], 16'd13107)
								+ mul_q15(bin_rx[39], 16'd19660)
								+ mul_q15(bin_rx[40], 16'd26214)
								+ mul_q15(bin_rx[41], 16'd32767)
								+ mul_q15(bin_rx[42], 16'd26214)
								+ mul_q15(bin_rx[43], 16'd19660)
								+ mul_q15(bin_rx[44], 16'd13107)
								+ mul_q15(bin_rx[45], 16'd6553);
					r_cnt   <= 5'd17;
				 end
			
				 // mel17 (41-46-51): k=42..50
				 5'd17: begin
					acc[17] <= mul_q15(bin_rx[42], 16'd6553)
								+ mul_q15(bin_rx[43], 16'd13107)
								+ mul_q15(bin_rx[44], 16'd19660)
								+ mul_q15(bin_rx[45], 16'd26214)
								+ mul_q15(bin_rx[46], 16'd32767)
								+ mul_q15(bin_rx[47], 16'd26214)
								+ mul_q15(bin_rx[48], 16'd19660)
								+ mul_q15(bin_rx[49], 16'd13107)
								+ mul_q15(bin_rx[50], 16'd6553);
					r_cnt   <= 5'd18;
				 end
			
				 // mel18 (46-51-57): k=47..56
				 5'd18: begin
					acc[18] <= mul_q15(bin_rx[47], 16'd5461)
								+ mul_q15(bin_rx[48], 16'd10922)
								+ mul_q15(bin_rx[49], 16'd16384)
								+ mul_q15(bin_rx[50], 16'd21845)
								+ mul_q15(bin_rx[51], 16'd32767)
								+ mul_q15(bin_rx[52], 16'd27306)
								+ mul_q15(bin_rx[53], 16'd21845)
								+ mul_q15(bin_rx[54], 16'd16384)
								+ mul_q15(bin_rx[55], 16'd10922)
								+ mul_q15(bin_rx[56], 16'd5461);
					r_cnt   <= 5'd19;
				 end
			
				 // mel19 (51-57-64): k=52..63
				 5'd19: begin
					acc[19] <= mul_q15(bin_rx[52], 16'd5461)
								+ mul_q15(bin_rx[53], 16'd10922)
								+ mul_q15(bin_rx[54], 16'd16384)
								+ mul_q15(bin_rx[55], 16'd21845)
								+ mul_q15(bin_rx[56], 16'd27306)
								+ mul_q15(bin_rx[57], 16'd32767)
								+ mul_q15(bin_rx[58], 16'd28086)
								+ mul_q15(bin_rx[59], 16'd23405)
								+ mul_q15(bin_rx[60], 16'd18724)
								+ mul_q15(bin_rx[61], 16'd14043)
								+ mul_q15(bin_rx[62], 16'd9361)
								+ mul_q15(bin_rx[63], 16'd4680);
					// xong 20 mel
					calc_done <= 1'b1;
					// chuyển sang state DONE/READ tuỳ FSM của bạn
					state <= S_DONE;
					r_cnt <= 5'd20; // hoặc giữ 19 tuỳ bạn
				 end
						endcase
	
        end

        // ------------------------------------------------------------
        // DONE: tính xong, chờ rd_ready_in để bắt đầu xuất 20 mel
        // ------------------------------------------------------------
        S_DONE: begin
          if (rd_ready_in) begin
            r_cnt     <= 5'd0;
            read_done <= 1'b0;
            state     <= S_READ;
          end
        end

        // ------------------------------------------------------------
        // READ: xuất lần lượt 20 mel (1 mel / clock) khi rd_ready_in=1
        // ------------------------------------------------------------
        S_READ: begin
          if (!rd_ready_in) begin
            // nếu rd_ready_in hạ xuống thì giữ trạng thái (không xuất)
            mel_valid <= 1'b0;
          end else begin
            mel_valid <= 1'b1;
            mel_index <= r_cnt;
            mel_out   <= acc[r_cnt];

            if (r_cnt == 5'd19) begin
              read_done <= 1'b1;
              state     <= S_IDLE; // xong 1 frame
				  r_cnt	<= 0;
            end else begin
              r_cnt <= r_cnt + 1'b1;
            end
          end
        end

        default: state <= S_IDLE;
      endcase
    end
  end


endmodule


