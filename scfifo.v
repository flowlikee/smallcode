
module scfifo #(
    parameter integer DEPTH = 32,//input 
    parameter integer I_WIDTH = 32,
    parameter integer O_WIDTH = 32 //it can be 32 , 16 , 8 , 4 , 2 , 1
) (
    input wire clk,
    input wire rst_n,
    input wire wr_en,
    input wire [I_WIDTH-1:0]din,
    input wire rd_en,
    output reg empty,
    output reg full,
    output wire [O_WIDTH-1:0]dout,
    output reg dout_valid,
    output reg overflow,
    output reg underflow
);
reg [I_WIDTH-1:0] mem[DEPTH-1:0];
reg [$clog2(DEPTH):0] wr_ptr;
reg [$clog2(DEPTH*I_WIDTH/O_WIDTH):0] rd_ptr;
reg wr_valid,wr_rdy;
reg [I_WIDTH-1:0]data_in;
reg [O_WIDTH-1:0]data_out;
always @(*) begin
    if (~rst_n) begin
        wr_valid<=0;
        data_in<=0;
    end begin
        wr_valid<=wr_en;
        data_in<=din;
    end 
end

wire [$clog2(DEPTH*I_WIDTH/O_WIDTH):0] count;
assign count= wr_ptr*(I_WIDTH/O_WIDTH)-rd_ptr;

always @(posedge clk) begin
    if (full && wr_en) begin
        overflow<=1;
    end else begin
        overflow<=0;
    end
end

always @(posedge clk ) begin
    if (~rst_n) begin
        wr_ptr <=0;
    end else if (wr_valid && wr_rdy) begin
        wr_ptr <=wr_ptr + 1;
    end 
end

always @(*) begin
    if (~rst_n) begin
        full<=0;
    end else if (count>=(DEPTH-1)*(I_WIDTH/O_WIDTH)&&count<(DEPTH)*(I_WIDTH/O_WIDTH)) begin
        full<=1;
    end else begin
        full<=0;
    end
end

always @(*) begin
    if (~rst_n) begin
        wr_rdy<=0;
    end else if (~full) begin
        wr_rdy<=1;
    end else begin
        wr_rdy<=0;
    end
end

reg wr_mem;
reg [$clog2(DEPTH)-1:0] wr_addr;
reg [I_WIDTH-1:0]wr_mem_in;
always @(posedge clk) begin
    if (~full&&(count==DEPTH-1)) begin
        wr_mem<=wr_valid && wr_rdy;
        wr_addr<=wr_ptr[$clog2(DEPTH)-1:0];
        wr_mem_in<=data_in;
    end else if (count==DEPTH-1) begin
        wr_mem<=0;
        wr_addr<=0;
        wr_mem_in<=0;
    end else begin
        wr_mem<=wr_valid && wr_rdy;
        wr_addr<=wr_ptr[$clog2(DEPTH)-1:0];
        wr_mem_in<=data_in;
    end
end

always @(posedge clk ) begin
    if (wr_mem) begin
        mem[wr_addr]<=wr_mem_in;
    end  
end



reg rd_valid,rd_rdy;
always @(posedge clk ) begin
    if (empty && rd_en) begin
        underflow<=1;
    end else begin
        underflow<=0;
    end
end
always @(posedge clk ) begin
    if (~rst_n) begin
        rd_ptr <= 0;
    end else if (rd_valid && rd_rdy) begin
        rd_ptr <= rd_ptr+1;
    end else begin
        rd_ptr<=rd_ptr;
    end
end

reg data_out_valid;
parameter integer rd_addr_LOW=(O_WIDTH==I_WIDTH)?1:$clog2(I_WIDTH/O_WIDTH);
parameter integer rd_addr_HIGH=$clog2(DEPTH*I_WIDTH/O_WIDTH);
reg [O_WIDTH-1:0]dout_reg;
always @(*) begin
    if (~rst_n) begin
        rd_valid<=0;
    end else begin
        rd_valid<=rd_en;
    end
end
always @(*) begin
    if (~rst_n) begin
        rd_rdy<=0;
    end else if (~empty) begin
        rd_rdy<=1;
    end else begin
        rd_rdy<=0;
    end
end
always @(*) begin
    if (~rst_n) begin
        empty<=0;
    end else if (count<=1) begin
        empty<=1;
    end else  begin
        empty<=0;
    end
end

wire [$clog2(DEPTH)-1:0] rd_addr=(O_WIDTH==I_WIDTH)?rd_ptr[rd_addr_HIGH-1:0]:rd_ptr[rd_addr_HIGH-1:rd_addr_LOW];
always @(posedge clk ) begin
    if (~rst_n) begin
        data_out<=0;
        data_out_valid<=0;
    end else if (rd_valid && rd_rdy) begin
        if (O_WIDTH==I_WIDTH) begin
            data_out<=mem[rd_addr];
        end else begin
          //  $display("rd_addr is ",rd_addr);
            $display("rd_data is ",mem[rd_addr][O_WIDTH*rd_ptr[rd_addr_LOW-1:0]+:O_WIDTH]);
            data_out<=mem[rd_addr][O_WIDTH*rd_ptr[rd_addr_LOW-1:0]+:O_WIDTH];
        end
        data_out_valid<=1;
    end else begin
        data_out<=0;
        data_out_valid<=0;
    end
end

always @(posedge clk ) begin
    dout_reg<=data_out;
    dout_valid<=data_out_valid;
end
assign dout=dout_reg;
endmodule
