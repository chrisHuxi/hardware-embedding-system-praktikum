`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/11/25 16:08:41
// Design Name: 
// Module Name: alu
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


module alu(
    input clk,
    input resetn,
    input [31:0] a,
    input [31:0] b,
    input [23:0] command,
    input data_vld,
    output reg result_done,
    output reg [31:0] result
    );
    reg [31:0] result_power;    //因为power需要自己进行设计计算流程，所以单独用一个reg来存储
    reg done_power;             //设置一个flag，当计算完power时将 result_power 写入 reg3
    reg [31:0] counter;         //用来控制 power 的循环次数， for 循环中的 i
    always @(posedge clk) begin
        if (resetn == 0) begin
            result <= 0;
            result_done <= 0;
        end else begin
            if (data_vld) 
                begin  //当可以进行计算时
                case (command)
                    0: begin result <= $signed(a) + $signed(b); result_done <= 1; end
                    1: begin result <= $signed(a) - $signed(b); result_done <= 1; end
                    2: begin result <= $signed(a) * $signed(b); result_done <= 1; end
                    3: begin result <= result_power; result_done <= done_power; end 
                        //因为power 操作会花费更多的clk，所以不能简单将result_done设置为1
                        //而是需要等待 done_power 的值
                    default: result <= result;
                endcase
                end
            else 
                begin
                result <= result; result_done <= 0;
                end
        end
    end
    
    //calculating the power operation
    //单独设置一个部分来计算power，这其实是和上一个部分是同时进行的，所以需要done_power信号来控制
    always @ (posedge clk) begin
        if (resetn == 0) 
        begin
            result_power <= 1; //重置时：默认result为1
            done_power <= 0;
            counter <= 0; //初始化 i = 0
        end 
        
        else begin
            if (command == 3) begin
                if (data_vld == 1 && counter < b) begin 
                    //当可以进行计算时，且 counter < b 时，这里不用for循环，因为在每个clk都会进行这样的check
                    //只需要控制好counter值就可以了
                    result_power <= result_power * a;
                    counter <= counter + 1;
                    done_power <= 0; //这里其实按逻辑是不必要的，但是为了保险还是重复设置done_power为0
                end 
                else if (data_vld == 1 && counter >= b) begin
                    //当可以进行计算时，且已经完成了计算（counter >= b）时
                    //设置 done_power 为 1，表示可以传给主module了
                    result_power <= result_power;
                    counter <= counter;
                    done_power <= 1;
                end 
                else begin //当还不可以进行计算时，保持reset状态
                    result_power <= result_power;
                    done_power <= 0;
                    counter <= 0;
                end
             end 
             else begin //如果不是 power command，则保持reset状态
                  result_power <= 1;
                  done_power <= 0;
                  counter <= 0;
             end
        end
    end
endmodule
