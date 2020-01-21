`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/01/11 14:44:24
// Design Name: 
// Module Name: vector_stream_alu
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


module vector_stream_alu#(
  parameter DATA_W = 32,
  parameter ADDR_W = 32,
  parameter DEPTH = 1024
  ) 
  (
	input clk,
    input resetn,        
    
    input[DATA_W-1:0] a,
    input[DATA_W-1:0] b,
    
    input [DATA_W-1:0] command,
    input [DATA_W-1:0] vector_length,
    
    input start_cal,  

    output reg [DATA_W-1:0] element_output,
    output reg result_done_element,
    output reg result_done_vector,      
    output reg [31:0] counter
    );
    
    reg [31:0] result_power;   
    reg done_power;            
    reg [31:0] counter_power; 
    
    // counting how many times we calculated 
    // used as writing address for bram C
    always @(posedge clk) 
    begin
        if (resetn == 0) 
        begin
          counter <= 0;
        end
        else
        begin
          if(result_done_element == 1)
          begin
            counter <= counter+1;
          end
          else
          begin
            counter <= counter;
          end
        end
    end
                
    always @(posedge clk) begin
        if (resetn == 0) begin
            element_output <= 0;
            result_done_vector <= 0;
            result_done_element <= 0;
        end 
        else begin
            if (counter < vector_length)
            begin
                if ((start_cal == 1) && (result_done_element == 0) ) 
                begin 
                  case (command)
                    0: begin element_output <= $signed(a) + $signed(b); result_done_element <= 1; end
                    1: begin element_output <= $signed(a) - $signed(b); result_done_element <= 1; end
                    2: begin element_output <= $signed(a) * $signed(b); result_done_element <= 1; end
                    3: begin element_output <= result_power; result_done_element <= done_power;   end  // power needs more clk 

                    default: begin element_output <= element_output; result_done_vector <= 0; result_done_element <= 0; end
                  endcase
                end
                else 
                begin
                  element_output <= element_output; result_done_vector <= 0; result_done_element <= 0;
                end
            end
            else
            begin
              if(vector_length == 0)
              begin
                result_done_vector <= 0;
              end
              else
              begin
                result_done_vector <= 1;
              end
            end

        end
    end
    
    //calculating the power operation
    //the same as simple alu power logic
    always @ (posedge clk) begin
        if (resetn == 0) 
        begin
            result_power <= 1; 
            done_power <= 0;
            counter_power <= 0;
        end 
        
        else begin
            if (command == 3) begin
                if (start_cal == 1 && counter_power < b) begin 
                    result_power <= result_power * a;
                    counter_power <= counter_power + 1;
                    done_power <= 0; 
                end 
                else if (start_cal == 1 && counter_power >= b) begin

                    result_power <= result_power;
                    counter_power <= counter_power;
                    done_power <= 1;
                end 
                else begin 
                    result_power <= 1;
                    done_power <= 0;
                    counter_power <= 0;
                end
             end 
             else begin 
                  result_power <= 1;
                  done_power <= 0;
                  counter_power <= 0;
             end
        end
    end 
    
     ila_alu ila_alu_inst(
    .clk(clk),
    .probe0(start_cal),
    .probe1(result_done_element),
    .probe2(resetn),
    .probe3(a),
    .probe4(b),
    .probe5(counter),
    .probe6(command),
    .probe7(element_output),
    .probe8(vector_length)
    );
endmodule
