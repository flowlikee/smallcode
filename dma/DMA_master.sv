`timescale 1ns / 1ps
`include "../../sources_1/new/pkg.vh"
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/12/04 17:36:57
// Design Name: 
// Module Name: DMA_master
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


module DMA_master(
    input wire clk,
    input wire rst_n,

    output reg req,
    input wire permit,

    output reg [`ID_WIDTH-1:0]  src_ID,
    output reg [`ADDR_WIDTH-1:0] src_addr,
    output reg [`ID_WIDTH-1:0]  dst_ID,
    output reg [`ADDR_WIDTH-1:0] dst_addr,
    output reg [`DMA_SIZE_WIDTH-1:0] size,
    output reg start,
    input wire done
    );
task automatic cmd_gen(
    logic [`ID_WIDTH-1:0]  this_src_ID,
    logic [`ADDR_WIDTH-1:0] this_src_addr,
    logic [`ID_WIDTH-1:0]  this_dst_ID,
    logic [`ADDR_WIDTH-1:0] this_dst_addr,
    logic [`DMA_SIZE_WIDTH-1:0] this_size,
    logic this_start
);
    req<=0;
    src_ID<=0;
    src_addr<=0;
    dst_ID<=0;
    dst_addr<=0;
    size<=0;
    start<=0;
    wait(rst_n);
    wait(this_start);
    @(posedge clk);
    req<=1;
    @(posedge clk);
    wait(permit);
    @(posedge clk);
    src_ID<=this_src_ID;
    src_addr<=this_src_addr;
    dst_ID<=this_dst_ID;
    dst_addr<=this_dst_addr;
    size<=this_size;
    start<=1;
    @(posedge clk);
    req<=0;
    src_ID<=0;
    src_addr<=0;
    dst_ID<=0;
    dst_addr<=0;
    size<=0;
    start<=0;
    wait(done);

endtask //automatic
endmodule
