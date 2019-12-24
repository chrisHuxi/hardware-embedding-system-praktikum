`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/12/04 21:03:31
// Design Name: 
// Module Name: bram
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


module bram#(
  parameter DATA_W = 32,
  parameter ADDR_W = 32,
  parameter DEPTH = 1024
  ) 
  (
	input clk, 
    input wr_enable, 
    input [DATA_W-1:0] write_element,
    input [ADDR_W-1:0] write_addr,

    input rd_enable,
    input [ADDR_W-1:0] read_addr,
    output [DATA_W-1:0] read_element 

    );

    reg [DATA_W - 1:0] mem_array [0:DEPTH-1]; // max mem depth : 1024
    
    // read logic: cost 0 clk
    assign read_element = (rd_enable == 1'b1 ? mem_array[read_addr] : 1'b0);

    // write logic: cost 1 clk
    always @(posedge clk)
    begin
      if (wr_enable == 1'b1)
        begin
            mem_array[write_addr] <= write_element;
        end
    end

    
endmodule
