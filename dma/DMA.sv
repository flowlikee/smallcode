`timescale 1ns / 1ps
`include "pkg.vh"
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/11/21 16:17:57
// Design Name: 
// Module Name: DMA
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
module DMA(
    input wire clk,
    input wire rst_n,
    input wire [`ID_WIDTH-1:0]src_ID,
    input wire [`ADDR_WIDTH-1:0] src_addr,
    input wire [`ID_WIDTH-1:0]  dst_ID,
    input wire [`ADDR_WIDTH-1:0] dst_addr,
    input wire [`DMA_SIZE_WIDTH-1:0] size,
    input wire start,
    output wire done,

    //AR channel
    output [`AXI_ID_WIDTH-1 : 0] M_AXI_ARID,
    output [`ADDR_WIDTH-1:0] M_AXI_ARADDR,
    output [7 : 0] M_AXI_ARLEN,
    output [2 : 0] M_AXI_ARSIZE,//=$clog2(`AXI_DATA_WIDTH/8);
    output [1 : 0] M_AXI_ARBURST,//=2'b01;
    output  M_AXI_ARLOCK,//=1'b0;
    output [3 : 0] M_AXI_ARCACHE,//=4'b0010;
    output [2 : 0] M_AXI_ARPROT,//=3'h0;
    output [3 : 0] M_AXI_ARQOS,//=4'h0;
    output  M_AXI_ARVALID,
    input  M_AXI_ARREADY,
    
    //Rd channel
    input [`AXI_ID_WIDTH-1 : 0] M_AXI_RID,
    input [`AXI_DATA_WIDTH-1 : 0] M_AXI_RDATA,
    input [1 : 0] M_AXI_RRESP,//ignore
    input  M_AXI_RLAST,
    input  M_AXI_RVALID,
    output M_AXI_RREADY,
    
    //AW channel
    output [`AXI_ID_WIDTH-1 : 0] M_AXI_AWID,
    output [32-1 : 0] M_AXI_AWADDR,
    output [7    : 0] M_AXI_AWLEN,
    output [2 : 0] M_AXI_AWSIZE,//=$clog2(`AXI_DATA_WIDTH/8)
    output [1 : 0] M_AXI_AWBURST,//=2'b01;
    output  M_AXI_AWLOCK,//1'b0;
    output [3 : 0] M_AXI_AWCACHE,//=4'b0010
    output [2 : 0] M_AXI_AWPROT,//=3'h0;
    output [3 : 0] M_AXI_AWQOS,//=4'h0;
    output  M_AXI_AWVALID,
    input  M_AXI_AWREADY,
    
    //Wr channel
    output [`AXI_DATA_WIDTH-1 : 0] M_AXI_WDATA,
    output [`AXI_DATA_WIDTH/8-1 : 0] M_AXI_WSTRB,
    output  M_AXI_WLAST,
    output  M_AXI_WVALID,
    input  M_AXI_WREADY,
    
    //Resp channel
    input [`AXI_ID_WIDTH-1 : 0] M_AXI_BID,//ignore
    input [1 : 0] M_AXI_BRESP,//ignore
    input  M_AXI_BVALID,//Bvalid and Bread means a a write response.
    output  M_AXI_BREADY//Bvalid and Bread means a a write response.
    );
 
assign M_AXI_AWSIZE=$clog2(`AXI_DATA_WIDTH/8);
assign M_AXI_AWBURST=2'b01;
assign M_AXI_AWLOCK=1'b0;
assign M_AXI_AWCACHE=4'b0010;
assign M_AXI_AWPROT=3'h0;
assign M_AXI_AWQOS=4'h0;
    
assign M_AXI_ARSIZE=$clog2(`AXI_DATA_WIDTH/8);
assign M_AXI_ARBURST=2'b01; 
assign M_AXI_ARLOCK=1'b0;
assign M_AXI_ARCACHE=4'b0010;
assign M_AXI_ARPROT=3'h0;
assign M_AXI_ARQOS=4'h0;
    
assign M_AXI_BREADY=1'b1;
assign M_AXI_WDATA=M_AXI_RDATA;
assign M_AXI_WSTRB={(`AXI_DATA_WIDTH/8){1'b1}};
assign M_AXI_WLAST=M_AXI_RLAST;
assign M_AXI_WVALID=M_AXI_RVALID;
assign M_AXI_RREADY=M_AXI_WREADY;
// assign M_AXI_RREADY=1;

DMA_rd_cmd u_DMA_rd_cmd(
.clk(clk),
.rst_n(rst_n),
.start(start),
.src_id(src_ID),
.src_addr(src_addr[`ADDR_WIDTH-1:0]),
.size(size),
//AR channel
.M_AXI_ARID(M_AXI_ARID),
.M_AXI_ARADDR(M_AXI_ARADDR),
.M_AXI_ARLEN(M_AXI_ARLEN),
.M_AXI_ARVALID(M_AXI_ARVALID),
.M_AXI_ARREADY(M_AXI_ARREADY)        
);

DMA_wr_cmd u_DMA_wr_cmd(
.clk(clk),
.rst_n(rst_n),
.start(start),
.dst_id(dst_ID),
.dst_addr(dst_addr[`ADDR_WIDTH-1:0]),
.size(size),//real_size - 1
//AW channel
.M_AXI_AWID(M_AXI_AWID),
.M_AXI_AWADDR(M_AXI_AWADDR),
.M_AXI_AWLEN(M_AXI_AWLEN),
.M_AXI_AWVALID(M_AXI_AWVALID),
.M_AXI_AWREADY(M_AXI_AWREADY)           
);

reg [15:0]cnt;
always @(posedge clk or negedge rst_n)begin
    if(~rst_n)
        cnt<=0;
    else if(start)
        cnt<=size;
    else if(M_AXI_WVALID&M_AXI_WREADY)
        cnt<=cnt-1;
    end
assign done = M_AXI_BVALID && M_AXI_BREADY && (cnt==0);
                   
endmodule
