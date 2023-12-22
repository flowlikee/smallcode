`timescale 1ns / 1ps
`include "pkg.vh"
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/11/30 16:34:39
// Design Name: 
// Module Name: Axifull_To_Simple
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
// //slave axi-full-write to simple ports
//////////////////////////////////////////////////////////////////////////////////
module Axifull_To_Simple(
    input wire clk,
    input wire rst_n,
    //axi-full-write
    //AW channel
    input wire [`AXI_ID_WIDTH-1 : 0] AXI_AWID,
    input wire [`ADDR_WIDTH-1:0] AXI_AWADDR,
    input wire [7    : 0] AXI_AWLEN,
    input wire [2 : 0] AXI_AWSIZE,//$clog2(`AXI_DATA_WIDTH/8);
    input wire [1 : 0] AXI_AWBURST,//=2'b01;
    input wire AXI_AWLOCK,//1'b0;
    input wire [3 : 0] AXI_AWCACHE,//=4'b0010
    input wire [2 : 0] AXI_AWPROT,//=3'h0;
    input wire [3 : 0] AXI_AWQOS,//=4'h0;
    input wire AXI_AWVALID,
    output wire AXI_AWREADY,
    
    //Wr channel
    input wire [`AXI_DATA_WIDTH-1 : 0] AXI_WDATA,
    input wire [`AXI_DATA_WIDTH/8-1 : 0] AXI_WSTRB,
    input wire AXI_WLAST,
    input wire AXI_WVALID,
    output wire AXI_WREADY,
    
    //Resp channel
    output wire [`AXI_ID_WIDTH-1 : 0] AXI_BID,//ignore
    output wire [1 : 0] AXI_BRESP,//ignore
    output wire AXI_BVALID,//Bvalid and Bread means a a write response.
    input  wire AXI_BREADY,//Bvalid and Bread means a a write response.
    
    output reg [`ID_WIDTH-1:0]slave_id,
    output reg [`AXI_DATA_WIDTH-1:0]slave_data,
    output reg slave_valid,
    output reg slave_begin_flag,
    output reg slave_last_flag
    );
reg awready;
reg wready;
reg bvalid;
assign AXI_AWREADY=awready;
assign AXI_WREADY=wready;
assign AXI_BVALID=bvalid;

reg [2:0]state;
parameter idle = 0;
parameter trans_first = 1;
parameter trans_body = 2;
parameter trans_finish = 3;

reg trans_flag;
always @(posedge clk) begin
    if (~rst_n) begin
        state<=idle;
    end else begin
        case (state)
            idle:begin
                if (AXI_AWREADY && AXI_AWVALID) begin
                    state<=trans_first;
                end
            end 
            trans_first:begin
                if (AXI_WREADY && AXI_WVALID) begin
                    state<=trans_body;
                end 
                if (AXI_WREADY && AXI_WVALID && AXI_WLAST) begin
                    state<=trans_finish;
                end
            end
            trans_body:begin
                if (AXI_WREADY && AXI_WVALID && AXI_WLAST) begin
                    state<=trans_finish;
                end
            end
            trans_finish:begin
                if (AXI_BVALID && AXI_BREADY) begin
                    state<=idle;
                end
            end
            default: state<=idle;
        endcase
    end 
end

always @(*) begin
    if(~rst_n) begin
        awready<=0;
        wready<=0;
        bvalid<=0;
        slave_id<=0;
        slave_data<=0;
        slave_valid<=0;
        slave_begin_flag<=0;
        slave_last_flag<=0;
    end else begin
        case (state)
        idle:begin
            awready<=1;
            wready<=0;
            bvalid<=0;
            slave_id<=AXI_AWID;
            slave_data<=0;
            slave_valid<=0;
            slave_begin_flag<=0;
            slave_last_flag<=0;
        end 
        trans_first:begin
            awready<=0;
            wready<=1;
            slave_data<=AXI_WDATA;
            slave_valid<= AXI_WVALID && AXI_WREADY;
            slave_begin_flag=AXI_WVALID && AXI_WREADY;
        end
        trans_body:begin
            slave_data<=AXI_WDATA;
            slave_begin_flag<=0;
            slave_valid<= AXI_WVALID && AXI_WREADY;
            slave_last_flag<=AXI_WVALID && AXI_WREADY && AXI_WLAST;
        end
        trans_finish:begin
            bvalid<=1;
            wready<=0;
            slave_data<=0;
            slave_valid<=0;
            slave_begin_flag<=0;
            slave_last_flag<=0;
            
        end
        default: begin
            awready<=0;
            wready<=0;
            bvalid<=0;
            slave_id<=0;
            slave_data<=0;
            slave_valid<=0;
            slave_begin_flag<=0;
            slave_last_flag<=0;
        end
    endcase
    end
    
end
endmodule
