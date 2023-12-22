`timescale 1ns / 1ps
`include "pkg.vh"
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/11/21 16:22:46
// Design Name: 
// Module Name: DMA_rd_cmd
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
module DMA_rd_cmd(
    input wire clk,
    input wire rst_n,

    input wire start,
    input wire [`ID_WIDTH-1:0]src_id,
    input wire [`ADDR_WIDTH-1:0]src_addr,
    input wire [`DMA_SIZE_WIDTH-1:0] size,

    //AR channel
    output wire [`ID_WIDTH-1:0] M_AXI_ARID,
    output wire [`ADDR_WIDTH-1:0] M_AXI_ARADDR,
    output wire [7:0] M_AXI_ARLEN,
    output wire M_AXI_ARVALID,
    input wire M_AXI_ARREADY
);
reg [`ID_WIDTH-1:0]arid;
reg arvalid;
reg [`ADDR_WIDTH-1:0] araddr;
reg [7:0] arlen;
assign M_AXI_ARID=arid;
assign M_AXI_ARADDR=araddr;
assign M_AXI_ARLEN=arlen;
assign M_AXI_ARVALID=arvalid;

reg [`DMA_SIZE_WIDTH-1:0] read_size;
reg [`ADDR_WIDTH-1:0]read_src_addr;

reg [2:0] state;
parameter idle = 0;
parameter trans_full = 1;
parameter trans_last = 2;
always@(posedge clk,negedge rst_n)begin
    if(~rst_n)begin
        state<=idle;
        arid<=0;
        read_size<=0; 
        read_src_addr<=0;
    end else begin
        case(state)
            idle:begin
                if(start)begin
                    arid<=src_id;
                    read_size<=size;
                    read_src_addr<=src_addr;
                    if (size[`DMA_SIZE_WIDTH-1:8]==0) begin
                        state<=trans_last;
                    end else begin
                        state<=trans_full;
                    end
                end else begin
                    arid<=0;
                    read_size<=0; 
                    read_src_addr<=0;
                end
            end
            trans_full:begin
                if (M_AXI_ARVALID && M_AXI_ARREADY) begin
                    read_size[`DMA_SIZE_WIDTH-1:8]<=read_size[`DMA_SIZE_WIDTH-1:8]-1;  
                    read_src_addr<=read_src_addr+256*(`AXI_DATA_WIDTH/8);
                    state<=(read_size[`DMA_SIZE_WIDTH-1:8]==1)?trans_last:state;        
                end
            end
            trans_last:begin 
                if (M_AXI_ARVALID && M_AXI_ARREADY) begin
                    state<=idle;
                end
            end
        endcase
    end
end  
always@(*)begin
    if (state==trans_full) begin
        araddr=read_src_addr;
        arlen=8'hff;
        arvalid=1;
    end else if (state==trans_last) begin
        araddr=read_src_addr;
        arlen=read_size[7:0];
        arvalid=1;
    end else begin
        araddr=0;
        arlen=0;
        arvalid=0;
    end
end 
endmodule
