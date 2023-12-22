`timescale 1ns / 1ps
`include "pkg.vh"
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/11/21 16:21:42
// Design Name: 
// Module Name: DMA_wr_cmd
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
module DMA_wr_cmd(
    input wire clk,
    input wire rst_n,
    input wire start,
    input wire [`ID_WIDTH-1:0] dst_id,
    input wire [`ADDR_WIDTH-1:0]dst_addr,
    input wire [`DMA_SIZE_WIDTH-1:0]size,//real_size - 1
    //AR channel
    output wire [`ID_WIDTH-1:0] M_AXI_AWID,
    output wire [`ADDR_WIDTH-1:0] M_AXI_AWADDR,
    output wire [7    : 0] M_AXI_AWLEN,
    output wire M_AXI_AWVALID,
    input  wire M_AXI_AWREADY
);
reg [`ID_WIDTH-1:0] awid;
reg awvalid;
reg [7:0]awlen;
reg [`ADDR_WIDTH-1:0]awaddr;
assign M_AXI_AWID=awid;
assign M_AXI_AWADDR=awaddr;
assign M_AXI_AWLEN=awlen;
assign M_AXI_AWVALID=awvalid;

reg [`DMA_SIZE_WIDTH-1:0] write_size;
reg [`ADDR_WIDTH-1:0]write_dst_addr;

reg [2:0] state;
parameter idle = 0;
parameter trans_full = 1;
parameter trans_last = 2;

always @(posedge clk or negedge rst_n)
    if(~rst_n)begin
        state<=0;
        awid<=0;
        write_size<=0;
        write_dst_addr<=0;
    end
else begin
    case(state)
        idle:begin//idle
            if(start)begin
                state<=1;
                awid<=dst_id;
                write_size<=size;
                write_dst_addr<=dst_addr;
                if (size[`DMA_SIZE_WIDTH-1:8]==0) begin
                    state<=trans_last;
                end else begin
                    state<=trans_full;
                end
            end else begin
                awid<=0;
                write_size<=0;
                write_dst_addr<=0;
            end
        end
        trans_full:begin
            if(M_AXI_AWVALID && M_AXI_AWREADY)begin//send a wr cmd
                write_size[`DMA_SIZE_WIDTH-1:8]<=write_size[`DMA_SIZE_WIDTH-1:8]-1;
                write_dst_addr<=write_dst_addr+256*(`AXI_DATA_WIDTH/8);
                state<=(write_size[`DMA_SIZE_WIDTH-1:8]==1)?trans_last:state;   
            end
        end
        trans_last:begin
            if (M_AXI_AWVALID && M_AXI_AWREADY) begin
                    state<=idle;
            end
        end
    endcase
end
always@(*)begin
    if (state==trans_full) begin
        awaddr=write_dst_addr;
        awlen=8'hff;
        awvalid=1;
    end else if (state==trans_last) begin
        awaddr=write_dst_addr;
        awlen=write_size[7:0];
        awvalid=1;
    end else begin
        awaddr=0;
        awlen=0;
        awvalid=0;
    end
end
endmodule
