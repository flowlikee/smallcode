`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/12/13 16:38:44
// Design Name: 
// Module Name: Sdpram
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module Sdpram#(
    parameter INPUT_DATA_W = 32,
    parameter OUTPUT_DATA_W = 8,
    parameter SIZE = 1024  //Byte number
)(
    input wire clk,
    input wire [$clog2(SIZE*8/INPUT_DATA_W)-1:0]addr_in,
    input wire en_in,
    input wire wea_in,
    input wire [INPUT_DATA_W-1:0]data_in,
    
    input wire [$clog2(SIZE*8/OUTPUT_DATA_W)-1:0]addr_out,
    input wire en_out,
    output wire [OUTPUT_DATA_W-1:0]data_out
    );

parameter INPUT_ADDR_W = $clog2(SIZE*8/INPUT_DATA_W);
parameter OUTPUT_ADDR_W = $clog2(SIZE*8/OUTPUT_DATA_W);
parameter mem_blk_num = INPUT_DATA_W/8;
parameter mem_part_num = INPUT_DATA_W/OUTPUT_DATA_W;
parameter mem_blk_depth = SIZE*8/INPUT_DATA_W;
reg [7:0]mem[mem_blk_num-1:0][mem_blk_depth-1:0];
reg [$clog2(SIZE*8/OUTPUT_DATA_W)-1:0]addr_out_temp;
wire [$clog2(mem_part_num)-1:0]part_num;

reg [INPUT_DATA_W-1:0] read_temp;
genvar blk_num;
generate
    for (blk_num = 0;blk_num < mem_blk_num;blk_num++ ) begin :memory_block
        always @(posedge clk) begin
            if (en_in) begin
                if (wea_in) begin
                    mem[blk_num][addr_in]<=data_in[blk_num*8+:8];
                end 
            end
        end
        always @(posedge clk) begin
            if (en_out) begin
                addr_out_temp<=addr_out;
                read_temp[blk_num*8+:8]<=mem[blk_num][addr_out/mem_part_num];
            end else begin
                read_temp<=0;
                addr_out_temp<=0;
            end
        end
    end
    assign part_num=(mem_part_num==1)?0:addr_out_temp%(mem_part_num);
    assign data_out=read_temp[OUTPUT_DATA_W*part_num+:OUTPUT_DATA_W];
endgenerate


endmodule
