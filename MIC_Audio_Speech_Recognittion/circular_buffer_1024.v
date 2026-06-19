module circular_buffer_1024 (
    input               clk,
    input               reset,

    input       [15:0]  sample_in,
    input               sample_valid,

    output reg          frame_ready,

    input       [9:0]   frame_rd_addr,
    output reg  [15:0]  frame_data
);

parameter FRAME_SIZE = 1024;
parameter HOP_SIZE   = 512;

reg [15:0] buffer [0:FRAME_SIZE-1];

reg [9:0] wr_ptr;
reg [9:0] sample_count;

integer i;

always @(posedge clk or negedge reset)
begin
    if(!reset)
    begin
        wr_ptr <= 0;
        sample_count <= 0;
        frame_ready <= 0;

        for(i=0;i<FRAME_SIZE;i=i+1)
            buffer[i] <= 0;
    end
    else if(sample_valid)
    begin

        // ghi sample mới
        buffer[wr_ptr] <= sample_in;

        // tăng write pointer
        if(wr_ptr == FRAME_SIZE-1)
            wr_ptr <= 0;
        else
            wr_ptr <= wr_ptr + 1;

        // đếm sample để tạo frame_ready
        if(sample_count == HOP_SIZE-1)
        begin
            sample_count <= 0;
            frame_ready <= 1;
        end
        else
        begin
            sample_count <= sample_count + 1;
            frame_ready <= 0;
        end

    end
    else
        frame_ready <= 0;

end

// đọc frame với offset circular
wire [10:0] rd_index;

assign rd_index = wr_ptr + frame_rd_addr;

always @(posedge clk)
begin
    if(rd_index >= FRAME_SIZE)
        frame_data <= buffer[rd_index - FRAME_SIZE];
    else
        frame_data <= buffer[rd_index];
end

endmodule
