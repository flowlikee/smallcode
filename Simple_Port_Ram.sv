`timescale 1ns / 1ps
`include "pkg.vh"
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/12/07 20:16:59
// Design Name: 
// Module Name: Simple_Port_Ram
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


module Simple_Port_Ram#(
    parameter INPUT_W = 32,
    parameter OUTPUT_W = 8,
    parameter OUTPUT_DEPTH = 32
)(
    input wire clk,
    input wire rst_n,
    input wire [$clog2(OUTPUT_DEPTH)-1:0]addr,
    input wire [INPUT_W-1:0]data_in,
    input wire en,
    input wire wea,
    output wire [OUTPUT_W-1:0] data_out,
    output reg data_out_valid
    );

parameter mem_write_depth=(((OUTPUT_W*OUTPUT_DEPTH)%INPUT_W)==0)?(OUTPUT_W*OUTPUT_DEPTH/INPUT_W):(OUTPUT_W*OUTPUT_DEPTH/INPUT_W)+1;
reg [INPUT_W-1:0]mem[mem_write_depth];
parameter addr_lsb=(INPUT_W==OUTPUT_W)?0:($clog2(INPUT_W/OUTPUT_W)-1);
wire [$clog2(OUTPUT_DEPTH)-addr_lsb:0]write_addr;
assign write_addr=addr[$clog2(OUTPUT_DEPTH)-1:addr_lsb];
always @(posedge clk) begin
    // if (~rst_n) begin
    //     foreach(mem[i]) mem[i]=0;
    // end else 
    if (en) begin
        if (wea) begin
            mem[write_addr]<=data_in;
        end
    end 
end
reg [INPUT_W-1:0]data_tmp;
reg [$clog2(OUTPUT_DEPTH)-1:0]read_addr;
assign data_out=data_tmp[OUTPUT_W*read_addr[addr_lsb-1:0]+:OUTPUT_W];
always @(posedge clk) begin
    if (~rst_n) begin
        data_tmp<=0;
        read_addr<=0;
        data_out_valid<=0;
    end else if(en && ~wea)begin
        read_addr<=addr;
        data_tmp<=mem[addr[$clog2(OUTPUT_DEPTH)-1:addr_lsb]];
        data_out_valid<=1;
    end else begin
        data_out_valid<=0;
        data_tmp<=0;
    end
end
endmodule
