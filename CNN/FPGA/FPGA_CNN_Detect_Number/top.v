module top(
				input clk,
				input reset_n,
				input start,
				input stop,
				output [6:0] LED_seg,
				output reg [9:0] LED_R,
				output UART_TX,
				input  UART_RX
);
	
	wire clk_100;

    // =========================================================
    // Bộ nhớ ảnh và feature map (Cấu hình 8 -> 16 Filters)
    // =========================================================
    (* ramstyle = "M9K", no_rw_check *)
	 reg signed [31:0] score [0:9];        // 10 output scores

    // =========================================================
    // Trọng số Q8.8 mới (Cần train lại trên Python theo cấu hình này)
    // =========================================================
    
	 reg signed [15:0] conv1_b [0:7];      // 8 bias

	 reg signed [15:0] conv2_b [0:15];     // 16 bias

	 reg signed [15:0] fc_b [0:9];

    initial begin
//     $readmemh("image_3_28x28.hex", image);
//	  
//	  $readmemh("conv1_w_q88.hex", conv1_w);
     $readmemh("conv1_b_q88.hex", conv1_b);

//     $readmemh("conv2_w_q88.hex", conv2_w);
     $readmemh("conv2_b_q88.hex", conv2_b);

//     $readmemh("fc_w_q88.hex", fc_w);
     $readmemh("fc_b_q88.hex", fc_b);
	 end
	 
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
	 localparam S_UART   = 4'd9;
	 
	 localparam S_FC_CALC = 4'd10;  // Trạng thái tính tích lũy tuần tự
    localparam S_FC_SAVE = 4'd11;

    reg [3:0] state;

    // =========================================================
    // Counter xử lý
    // =========================================================

	reg [8:0] i;
	reg [3:0] cls;
	 
	reg [4:0] row;
	reg [4:0] col;

	reg [3:0] ch;
	reg [3:0] ic;

	reg [2:0] kh;
	reg [2:0] kw;

    reg signed [63:0] acc;
	 reg signed [63:0] post_acc;
    reg signed [31:0] max_val;

    reg signed [31:0] best_score;
    reg [3:0] best_digit;
	 reg [3:0] digit;
	 
	 reg busy;
	 reg done;
	 reg [4:0] stt;

    // =========================================================
    // Hàm index dùng layout channels-last (Cấu hình nâng cấp 8 -> 16 Filters)
    // Tensor Keras: row, col, channel
    // =========================================================

    // 1. Định vị ảnh gốc (28x28x1)
    function integer idx_image;
        input integer r;
        input integer c;
        begin
            idx_image = r * 32'd28 + c;
        end
    endfunction

    // 2. Định vị Feature Map sau lớp CONV1 (24x24x8)
    function integer idx_conv1;
        input integer r;
        input integer c;
        input integer oc; // Kênh đầu ra lớp 1 (0 -> 7)
        begin
            // Nhân 8 (Lũy thừa của 2) -> Quartus tự tối ưu thành mạch dịch bit << 3
            idx_conv1 = (r * 32'd24 + c) * 32'd8 + oc;
        end
    endfunction

    // 3. Định vị Feature Map sau lớp POOL1 (12x12x8)
    function integer idx_pool1;
        input integer r;
        input integer c;
        input integer oc; // Kênh đầu ra lớp 1 (0 -> 7)
        begin
            // Nhân 8 -> Mạch dịch bit << 3
            idx_pool1 = (r * 32'd12 + c) * 32'd8 + oc;
        end
    endfunction

    // 4. Định vị Feature Map sau lớp CONV2 (8x8x16)
    function integer idx_conv2;
        input integer r;
        input integer c;
        input integer oc; // Kênh đầu ra lớp 2 (0 -> 15)
        begin
            // Nhân 16 -> Mạch dịch bit << 4
            idx_conv2 = (r * 32'd8 + c) * 32'd16 + oc;
        end
    endfunction

    // 5. Định vị Feature Map sau lớp POOL2 (4x4x16)
    function integer idx_pool2;
        input integer r;
        input integer c;
        input integer oc; // Kênh đầu ra lớp 2 (0 -> 15)
        begin
            // Nhân 16 -> Mạch dịch bit << 4
            idx_pool2 = (r * 32'd4 + c) * 32'd16 + oc;
        end
    endfunction

    // 6. Định vị Trọng số bộ lọc CONV1_W (Shape Keras: [5][5][1][8])
    function integer idx_conv1_w;
        input integer khr;
        input integer kwc;
        input integer oc; // Kênh đầu ra lớp 1 (0 -> 7)
        begin
            idx_conv1_w = (khr * 32'd5 + kwc) * 32'd8 + oc;
        end
    endfunction

    // 7. Định vị Trọng số bộ lọc CONV2_W (Shape Keras: [5][5][8][16])
    function integer idx_conv2_w;
        input integer khr;
        input integer kwc;
        input integer in_ch;  // Kênh đầu vào (0 -> 7) từ lớp POOL1 truyền sang
        input integer out_ch; // Kênh bộ lọc đầu ra lớp 2 (0 -> 15)
        begin
            // Do nhân 8 và nhân 16 đều là lũy thừa cơ số 2, 
            // trình tổng hợp sẽ không tốn bất kỳ bộ nhân DSP nào cho hàm này!
            idx_conv2_w = (((khr * 32'd5 + kwc) * 32'd8 + in_ch) * 32'd16 + out_ch);
        end
    endfunction

    // 8. Định vị Trọng số lớp Kết nối đầy đủ FC_W (Shape Keras: [256][10])
    function integer idx_fc_w;
        input integer input_idx; // Chỉ số ngõ vào phẳng phẳng từ POOL2 (0 -> 255)
        input integer out_class; // Lớp chữ số ngõ ra (0 -> 9)
        begin
            // Mảng pool2 phẳng có kích thước 4 * 4 * 16 = 256 phần tử đầu vào
            idx_fc_w = input_idx * 32'd10 + out_class;
        end
    endfunction
	 
	 
	reg  [9:0] addr_img;
   wire  [15:0] pixel;
	
	reg [11:0] addr_conv1w;
	wire signed [15:0] data_conv1w;
	
	reg [12:0] addr_img_conv1;
	reg [31:0] data_w_img_conv1;
	wire[31:0] data_r_img_conv1;
	reg wren_img_conv1;
	
	reg [10:0] addr_pool1;
	reg [31:0] data_w_pool1;
	wire[31:0] data_r_pool1;
	reg wren_pool1;

	reg [11:0] addr_conv2w;
	wire signed [15:0]data_conv2w;
	
	reg [9:0] addr_img_conv2;
	reg [31:0]data_w_img_conv2;
	wire [31:0]data_r_img_conv2;
	reg wren_img_conv2;
	
	reg [10:0] addr_pool2;
	reg [31:0] data_w_pool2;
	wire[31:0] data_r_pool2;
	reg wren_pool2;
	
	reg [11:0] addr_fcw;
	wire signed [15:0] data_r_fcw;
	
	
	//************ TEST UART ***********//

	reg run;
	wire fb_uart;
	reg [7:0] data_uart;
	reg [15:0] data_array [0:9];
	reg [18:0] uart_address_sram;
	reg [4:0] stt_uart;

	//*********************************//

    // =========================================================
    // Main FSM
    // =========================================================

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            state       <= S_IDLE;
            busy        <= 1'b0;
            done        <= 1'b0;
            digit       <= 4'd0;

            row         <= 5'd0;
            col         <= 5'd0;
            ch          <= 2'd0;
            cls         <= 4'd0;

            best_score  <= 32'sd0;
            best_digit  <= 4'd0;
				
				addr_img		<= 0;
				addr_conv1w <= 0;
				stt_uart <= 0;
				LED_R <= 0;
				
				stt <= 5'd0;
        end else begin

        case (state)

        // -------------------------------------------------
        // IDLE
        // -------------------------------------------------
        S_IDLE: begin
            done <= 1'b0;
            busy <= 1'b0;
				stt	 <= 5'd0;
				stt_uart <= 0;

            if (!start) begin
              busy  <= 1'b1;
              state <= S_CONV1;
            end
        end
					 
         // -------------------------------------------------
         // CONV1
         // Input: 28x28x1
         // Kernel: 5x5x1x8
         // Output: 24x24x8
         // -------------------------------------------------					 					 
					 
			S_CONV1: begin
				 case(stt)
							
					  5'd0: begin
							kh  <= 0;
							kw  <= 0;
							acc <= 64'sd0; 					// Reset acc về 0 chuẩn bị cho ô quét mới
							wren_img_conv1 <= 1'b1;
							stt <= 5'd1;
					  end
					  
					  5'd1: begin
							addr_img <= idx_image(row + kh, col + kw);
							addr_conv1w <= idx_conv1_w(kh, kw, ch);
							stt <= 5'd2;
					  end
					  
					  5'd2: begin
							acc <= acc + $signed({1'b0, pixel}) * $signed(data_conv1w);
							stt <= 5'd3;    
					  end
					  
					  5'd3: begin
							if (kw < 4) 
								begin
									kw  <= kw + 3'd1;
									stt <= 5'd1;
								end 
							else 
								begin
									kw <= 0;
									if (kh < 4) 
										begin
											kh  <= kh + 3'd1;
											stt <= 5'd1;
										end 
									else 
										begin
											stt <= 5'd4; 		// Đủ 25 pixel -> Chuyển sang ReLU
										end
								end
					  end

					  // RELU & SAVE
					  5'd4: begin
							post_acc = (acc >>> 8) + conv1_b[ch];
							stt <= 5'd5;
					  end
					  
					  5'd5: begin
							addr_img_conv1 <= idx_conv1(row, col, ch);
					  		if (post_acc < 0)
								data_w_img_conv1 <= 32'sd0;
							else
								data_w_img_conv1 <= post_acc[31:0]; 
							stt <= 5'd6;
					  end
					  
					  // DỊCH CHUYỂN Ô QUÉT ẢNH (TRÊN CÙNG 1 KÊNH)
					  5'd6: begin
							if (col < 5'd23) 
								begin
									col <= col + 5'd1;
									stt <= 5'd0; 				// SỬA: Quay về d0 để xóa acc và reset kh, kw cho ô tiếp theo
								end 
							else 
								begin
									col <= 5'd0; 				// Reset col ngay tại đây khi hết hàng
									if (row < 5'd23) 	
										begin
											row <= row + 5'd1;
											stt <= 5'd0; 		// SỬA: Quay về d0 để tính ô đầu tiên của hàng mới
										end 
									else 
										begin
											row <= 0;
											stt <= 5'd7; 		// Đã quét sạch ảnh của kênh này -> Chuyển sang đổi kênh
										end
								end
					  end
					  
					  // CHUYỂN KÊNH ĐẦU RA (FILTER) KẾ TIẾP
					  5'd7: begin
							if (ch < 7) 
								begin 							// Chạy từ 0 đến 7 là đủ 8 filters
									ch  <= ch + 4'd1;
									row <= 0;    				// Đảm bảo reset lại từ đầu ảnh
									col <= 5'd0; 				// Đảm bảo reset lại từ đầu ảnh
									stt <= 5'd0; 				// SỬA: Quay về d0 để khởi tạo lại toàn bộ cho kênh mới
								end 
							else 
								begin	
									ch    <= 0;
									stt   <= 5'd0;
									state <= S_POOL1; 		// HOÀN THÀNH LỚP CONV1 -> Chuyển sang lớp Max Pooling
								end
					  end
				 endcase
			end

         // -------------------------------------------------
         // POOL1
         // Input: 24x24x8
         // MaxPool 2x2
         // Output: 12x12x8
         // -------------------------------------------------
					 
			S_POOL1: begin
				case(stt)
					5'd0: begin
						row   <= 5'd0;
                  col   <= 5'd0;
						wren_img_conv1 <= 1'b0;
						wren_pool1 <= 1'b1;
						stt	<= 5'd1;
					end
					
					5'd1: begin
						addr_img_conv1 <= idx_conv1(row * 2, col * 2, ch);
						stt <= 5'd2;
					end
					
					5'd2: begin
						max_val <= data_r_img_conv1;
						addr_img_conv1 <= idx_conv1(row * 2, col * 2 + 1, ch);
						stt <= 5'd3;
					end
					
					5'd3: begin
						if (data_r_img_conv1 > max_val)
							max_val <= data_r_img_conv1;
						addr_img_conv1 <= idx_conv1(row * 2 + 1, col * 2, ch);
						stt <= 5'd4;
					end
					
					5'd4: begin
						if (data_r_img_conv1 > max_val)
                     max_val <= data_r_img_conv1;
						addr_img_conv1 <= idx_conv1(row * 2 + 1, col * 2 + 1, ch);
						stt <= 5'd5;
					end
					
					5'd5: begin
						if (data_r_img_conv1 > max_val)
                     max_val <= data_r_img_conv1;
						
						stt <= 5'd6;
					end
					
					5'd6: begin
						addr_pool1 <= idx_pool1(row, col, ch);
						data_w_pool1 <= max_val;
						if(col < 5'd11)
							begin
								col <= col + 5'd1;
								stt <= 5'd1;
							end
						else 
							begin
								col <= 0;
								if(row < 5'd11)
									begin
										row <= row + 5'd1;
										stt <= 5'd1;
									end
								else
									begin
										row <= 5'd0;
										stt <= 5'd7;
									end
							end
					end
					
					5'd7: begin
						if (ch < 5'd7)
							begin
								ch <= ch + 4'd1;
								stt <= 5'd0;
							end
						else
							begin
								ch <= 4'd0;
								stt <= 5'd0;
								state <= S_CONV2;
							end
					end
					
				endcase
				
			end
			
		 // -------------------------------------------------
       // CONV2
       // Input: 12x12x8
       // Kernel: 5x5x8x16
       // Output: 8x8x16
       // -------------------------------------------------
					 
			S_CONV2: begin
				case(stt)
					5'd0: begin
						kh  <= 0;
						kw  <= 0;
						acc <= 64'sd0; 					// Reset acc về 0 chuẩn bị cho ô quét mới
						wren_pool1 <= 1'b0;
						wren_img_conv2 <= 1'b1;
						stt <= 5'd1;
					end
					
					5'd1: begin
						addr_conv2w <= idx_conv2_w(kh, kw, ic, ch);
						addr_pool1 <= idx_pool1(row + kh, col + kw, ic);
						stt <= 5'd2;
						
					end
					
					5'd2: begin
						acc <= acc + $signed(data_r_pool1) * $signed(data_conv2w);
						stt <= 5'd3;
					end
					
					5'd3: begin
						if(ic < 7)
							begin
								ic <= ic + 4'd1;
								stt <= 5'd1;
							end
						else
							begin
								ic <= 0;
								if (kw < 4) 
									begin
										kw  <= kw + 3'd1;
										stt <= 5'd1;
									end 
								else 
									begin
										kw <= 0;
										if (kh < 4) 
											begin
												kh  <= kh + 3'd1;
												stt <= 5'd1;
											end 
										else 
											begin
												stt <= 5'd4; 		// Đủ 25 pixel -> Chuyển sang ReLU
											end
									end
							end
					 end
					  
					  // RELU & SAVE
					  5'd4: begin
							post_acc <= (acc >>> 8) + $signed(conv2_b[ch]);
							
							stt <= 5'd5; 
					  end
					  
					  5'd5: begin
							addr_img_conv2 <= idx_conv2(row, col, ch);
							if (post_acc < 0)
								 data_w_img_conv2 <= 32'sd0;
							else
								 data_w_img_conv2 <= post_acc[31:0];
							stt <= 5'd6; 
					  end
					  
					  // DỊCH CHUYỂN Ô QUÉT ẢNH (TRÊN CÙNG 1 KÊNH)
					  5'd6: begin
							if (col < 5'd7) 
								begin
									col <= col + 5'd1;
									stt <= 5'd0; 				// SỬA: Quay về d0 để xóa acc và reset kh, kw cho ô tiếp theo
								end 
							else 
								begin
									col <= 5'd0; 				// Reset col ngay tại đây khi hết hàng
									if (row < 5'd7) 	
										begin
											row <= row + 5'd1;
											stt <= 5'd0; 		// SỬA: Quay về d0 để tính ô đầu tiên của hàng mới
										end 
									else 
										begin
											row <= 0;
											stt <= 5'd7; 		// Đã quét sạch ảnh của kênh này -> Chuyển sang đổi kênh
										end
								end
					  end
					  
					  // CHUYỂN KÊNH ĐẦU RA (FILTER) KẾ TIẾP
					  5'd7: begin
							if (ch < 15) 
								begin 							// Chạy từ 0 đến 7 là đủ 8 filters
									ch  <= ch + 4'd1;
									row <= 0;    				// Đảm bảo reset lại từ đầu ảnh
									col <= 5'd0; 				// Đảm bảo reset lại từ đầu ảnh
									stt <= 5'd0; 				// SỬA: Quay về d0 để khởi tạo lại toàn bộ cho kênh mới
								end 
							else 
								begin	
									ch    <= 0;
									stt   <= 5'd0;
									state <= S_POOL2; 		// HOÀN THÀNH LỚP CONV1 -> Chuyển sang lớp Max Pooling
								end
					  end
				
				endcase
			end

         // -------------------------------------------------
         // POOL2
         // Input: 8x8x16
         // MaxPool 2x2
         // Output: 4x4x16
         // -------------------------------------------------

			S_POOL2: begin
				case(stt)
					5'd0: begin
						row   <= 5'd0;
                  col   <= 5'd0;
						wren_img_conv2 <= 1'b0;
						wren_pool2 <= 1'b1;
						stt	<= 5'd1;
					end
					
					5'd1: begin
						addr_img_conv2 <= idx_conv2(row * 2, col * 2, ch);
						stt <= 5'd2;
					end
					
					5'd2: begin
						max_val <= data_r_img_conv2;
						addr_img_conv2 <= idx_conv2(row * 2, col * 2 + 1, ch);
						stt <= 5'd3;
					end
					
					5'd3: begin
						if (data_r_img_conv2 > max_val)
							max_val <= data_r_img_conv2;
						addr_img_conv2 <= idx_conv2(row * 2 + 1, col * 2, ch);
						stt <= 5'd4;
					end
					
					5'd4: begin
						if (data_r_img_conv2 > max_val)
                     max_val <= data_r_img_conv2;
						addr_img_conv2 <= idx_conv2(row * 2 + 1, col * 2 + 1, ch);	
						stt <= 5'd5;
					end
					
					5'd5: begin
						if (data_r_img_conv2 > max_val)
                     max_val <= data_r_img_conv2;
						addr_pool2 <= idx_pool2(row, col, ch);
						stt <= 5'd6;
					end
					
					5'd6: begin
						data_w_pool2 <= max_val;
						if(col < 5'd3)
							begin
								col <= col + 5'd1;
								stt <= 5'd1;
							end
						else 
							begin
								col <= 0;
								if(row < 5'd3)
									begin
										row <= row + 5'd1;
										stt <= 5'd1;
									end
								else
									begin
										row <= 5'd0;
										stt <= 5'd7;
									end
							end
					end
					
					5'd7: begin
						if (ch < 5'd15)
							begin
								ch <= ch + 4'd1;
								stt <= 5'd0;
							end
						else
							begin
								ch <= 4'd0;
								stt <= 5'd0;
								state <= S_FC;
							end
					end
					
				endcase
			
			end

      // -------------------------------------------------
      // FULLY CONNECTED
      // Input: 48
      // Output: 10
      // Mỗi chu kỳ tính 1 class
      // -------------------------------------------------
	
			S_FC: begin
				case(stt)
				5'd0: begin
					acc <= 64'sd0;
					i <= 0;
					cls <= 0;
					wren_pool2 <= 1'b0;
					stt <= 1;
				end
				
				5'd1: begin
					addr_fcw <= idx_fc_w(i, cls);
					addr_pool2 <= i;
					stt <= 2;
				end
				
				5'd2: begin
					acc <= acc + data_r_pool2 * $signed(data_r_fcw);
					stt <= 3;
				end
				
				5'd3: begin
					if (i<255)
						begin
							i <= i + 9'd1;
							stt <= 1;
						end
					else
						begin
							i <= 0;
							stt <= 4;
						end
				end
				
				5'd4: begin
					acc <= (acc >>> 8) + $signed(fc_b[cls]);
					stt <= 5;
				end
				
				5'd5: begin
					score[cls] <= acc[31:0];
					if(cls == 4'd9)
						begin
							stt <= 0;
							state <= S_ARGMAX;
						end
					else
						begin
							cls <= cls + 4'd1;
							acc <= 0;
							stt <= 1;
						end
				end
				endcase
			end
			
			S_ARGMAX: begin
				case (stt)
				5'd0: begin
					best_score = score[0];
					best_digit = 4'd0;
					i <= 0;
					stt <= 1;
				end
				
				5'd1: begin 
					stt <= 2;
				end
				
				5'd2: begin
					if (score[i] > best_score)
						begin
							best_score = score[i];
							best_digit = i[3:0];
						end
					stt <= 3;
				end
				
				5'd3: begin
					if(i < 9)
						begin
							i <= i+1;
							stt <= 1;
						end
					else
						begin
							digit <= best_digit;
							state <= S_DONE;
							stt <= 0;
						end				
				end
				
				endcase
			end
			
//				S_UART: begin
//					case(stt_uart)
//						4'd0: begin 
//							run <= 0; 
//							addr_img_conv1 <= 0;
//							wren_img_conv1 <= 0;
//							stt_uart <= 1;					
//						 end
//						 
//						4'd1: begin
//							stt_uart <= 2;
//						end
//						
//						4'd2: 
//						if(!fb_uart)
//							begin
//								data_uart <= data_r_img_conv1[31:24];
//								run <= 1;
//								stt_uart <= 3;
//							end
//						4'd3:if(fb_uart)
//							begin
//								run <= 0;
//								stt_uart <= 4;
//							end
//						4'd4: 
//						if(!fb_uart)
//							begin
//								data_uart <= data_r_img_conv1[23:16];
//								run <= 1;
//								stt_uart <= 5;
//							end
//						4'd5:if(fb_uart)
//							begin
//								run <= 0;
//								stt_uart <= 6;
//							end
//						4'd6:if(!fb_uart)
//							begin
//								data_uart <= data_r_img_conv1[15:8];
//								run <= 1;
//								stt_uart <= 7;
//							end
//						4'd7:if(fb_uart)
//							begin
//								run <= 0;
//								stt_uart <= 8;
//							end	
//						4'd8:if(!fb_uart)
//							begin
//								data_uart <= data_r_img_conv1[7:0];
//								run <= 1;
//								stt_uart <= 9;
//							end
//						4'd9:if(fb_uart)
//							begin
//								run <= 0;
//								stt_uart <= 10;
//								addr_img_conv1 <= addr_img_conv1 + 13'd1;
//							end
//						4'd10:	
//							begin
//								if(addr_img_conv1 < 13'd4607) stt_uart <= 1;
//								else 
//									begin
//										stt_uart <= 0;
//										state <= S_DONE;
//								end
//							end
//					endcase
//				
//				end
				
				
//				S_UART: begin
//					case(stt_uart)
//						4'd0: begin 
//							run <= 0; 
//							addr_pool1 <= 0;
//							wren_pool1 <= 0;
//							stt_uart <= 1;					
//						 end
//						 
//						4'd1: begin
//							stt_uart <= 2;
//						end
//						
//						4'd2: 
//						if(!fb_uart)
//							begin
//								data_uart <= data_r_pool1[31:24];
//								run <= 1;
//								stt_uart <= 3;
//							end
//						4'd3:if(fb_uart)
//							begin
//								run <= 0;
//								stt_uart <= 4;
//							end
//						4'd4: 
//						if(!fb_uart)
//							begin
//								data_uart <= data_r_pool1[23:16];
//								run <= 1;
//								stt_uart <= 5;
//							end
//						4'd5:if(fb_uart)
//							begin
//								run <= 0;
//								stt_uart <= 6;
//							end
//						4'd6:if(!fb_uart)
//							begin
//								data_uart <= data_r_pool1[15:8];
//								run <= 1;
//								stt_uart <= 7;
//							end
//						4'd7:if(fb_uart)
//							begin
//								run <= 0;
//								stt_uart <= 8;
//							end	
//						4'd8:if(!fb_uart)
//							begin
//								data_uart <= data_r_pool1[7:0];
//								run <= 1;
//								stt_uart <= 9;
//							end
//						4'd9:if(fb_uart)
//							begin
//								run <= 0;
//								stt_uart <= 10;
//								addr_pool1 <= addr_pool1 + 13'd1;
//							end
//						4'd10:	
//							begin
//								if(addr_pool1 < 13'd1151) stt_uart <= 1;
//								else 
//									begin
//										stt_uart <= 0;
//										state <= S_DONE;
//								end
//							end
//					endcase
//				
//				end
		
//				S_UART: begin
//					case(stt_uart)
//						4'd0: begin 
//							run <= 0; 
//							addr_img <= 0;
//							stt_uart <= 1;					
//						 end
//						 
//						4'd1: begin
//							stt_uart <= 2;
//						end
//						
//						4'd2:if(!fb_uart)
//							begin
//								data_uart <= pixel[15:8];
//								run <= 1;
//								stt_uart <= 3;
//							end
//						4'd3:if(fb_uart)
//							begin
//								run <= 0;
//								stt_uart <= 4;
//							end	
//						4'd4:if(!fb_uart)
//							begin
//								data_uart <= pixel[7:0];
//								run <= 1;
//								stt_uart <= 5;
//							end
//						4'd5:if(fb_uart)
//							begin
//								run <= 0;
//								stt_uart <= 6;
//								addr_img <= addr_img + 10'd1;
//							end
//						4'd6:	
//							begin
//								if(addr_img < 10'd783) stt_uart <= 1;
//								else 
//									begin
//										stt_uart <= 0;
//										state <= S_DONE;
//								end
//							end
//					endcase
//				
//				end
		
				S_DONE: begin
                    done <= 1'b1;
                    busy <= 1'b0;
						  LED_R <= 1;

                    if (!start) begin
                        state <= S_IDLE;
                    end
             end		 
		endcase
	end
end

seven_seg u_hex0 
(
   .num (digit),
   .seg (LED_seg)
);

pll u_pll(
	.inclk0(clk),
	.c0(clk_100)
);

image u_image (
   .address(addr_img),
   .clock(clk_100),
   .data(16'b0),
   .wren(1'b0),
   .q(pixel)
);	

 conv1 conv1_w(
	.address(addr_conv1w),
	.clock(clk_100),
	.data(16'b0),
	.wren(1'b0),
	.q(data_conv1w)
);

img_conv1 u_img_conv1(
	.address(addr_img_conv1),
	.clock(clk_100),
	.data(data_w_img_conv1),
	.wren(wren_img_conv1),
	.q(data_r_img_conv1)
	);

pool1 u_pool1(
	.address(addr_pool1),
	.clock(clk_100),
	.data(data_w_pool1),
	.wren(wren_pool1),
	.q(data_r_pool1)
);

conv2_w u_conv2w(
	.address(addr_conv2w),
	.clock(clk_100),
	.data(16'b0),
	.wren(1'b0),
	.q(data_conv2w)
);

img_conv2 u_img_conv2(
	.address(addr_img_conv2),
	.clock(clk_100),
	.data(data_w_img_conv2),
	.wren(wren_img_conv2),
	.q(data_r_img_conv2)
);

pool2 u_pool2(
	.address(addr_pool2),
	.clock(clk_100),
	.data(data_w_pool2),
	.wren(wren_pool2),
	.q(data_r_pool2)
	);
	
fc_w u_fc_w(
	.address(addr_fcw),
	.clock(clk_100),
	.data(16'd0),
	.wren(1'b0),
	.q(data_r_fcw)
);

uartWrite u5(
	.clock_50mhz(clk),
	.reset(reset_n),
	.data(data_uart),
	.run(run),
	.feedback(fb_uart),
	.tx_pin(UART_TX)
);

endmodule



