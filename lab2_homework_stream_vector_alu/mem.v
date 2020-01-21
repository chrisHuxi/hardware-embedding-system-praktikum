`timescale 1 ns / 1 ps
module mem #(
  parameter DATA_W = 32,
  parameter DEPTH = 1024,
  parameter ADDR_W = clogb2(DEPTH - 1)
  ) 
  (
    input rd_clk,
    input rd_en,
    input [ADDR_W - 1:0] rd_addr,
    output [DATA_W - 1:0] rd_data,

    input wr_clk,
    input wr_en,
    input [ADDR_W - 1:0] wr_addr,
    input [DATA_W - 1:0] wr_data
  );
  function integer clogb2 (input integer bit_depth);
    begin
      for(clogb2=0; bit_depth>0; clogb2=clogb2+1)
        bit_depth = bit_depth >> 1;
    end
  endfunction

  reg [DATA_W - 1:0] mem_array [0:DEPTH-1];

  assign rd_data = (rd_en == 1'b1 ? mem_array[rd_addr] : 1'b0);

  always @(posedge wr_clk) begin
    if (wr_en) begin
      mem_array[wr_addr] <= wr_data;
    end
  end

endmodule


