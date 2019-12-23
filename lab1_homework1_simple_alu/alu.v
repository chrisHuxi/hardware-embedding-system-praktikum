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
    reg [31:0] result_power;    //��Ϊpower��Ҫ�Լ�������Ƽ������̣����Ե�����һ��reg���洢
    reg done_power;             //����һ��flag����������powerʱ�� result_power д�� reg3
    reg [31:0] counter;         //�������� power ��ѭ�������� for ѭ���е� i
    always @(posedge clk) begin
        if (resetn == 0) begin
            result <= 0;
            result_done <= 0;
        end else begin
            if (data_vld) 
                begin  //�����Խ��м���ʱ
                case (command)
                    0: begin result <= $signed(a) + $signed(b); result_done <= 1; end
                    1: begin result <= $signed(a) - $signed(b); result_done <= 1; end
                    2: begin result <= $signed(a) * $signed(b); result_done <= 1; end
                    3: begin result <= result_power; result_done <= done_power; end 
                        //��Ϊpower �����Ứ�Ѹ����clk�����Բ��ܼ򵥽�result_done����Ϊ1
                        //������Ҫ�ȴ� done_power ��ֵ
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
    //��������һ������������power������ʵ�Ǻ���һ��������ͬʱ���еģ�������Ҫdone_power�ź�������
    always @ (posedge clk) begin
        if (resetn == 0) 
        begin
            result_power <= 1; //����ʱ��Ĭ��resultΪ1
            done_power <= 0;
            counter <= 0; //��ʼ�� i = 0
        end 
        
        else begin
            if (command == 3) begin
                if (data_vld == 1 && counter < b) begin 
                    //�����Խ��м���ʱ���� counter < b ʱ�����ﲻ��forѭ������Ϊ��ÿ��clk�������������check
                    //ֻ��Ҫ���ƺ�counterֵ�Ϳ�����
                    result_power <= result_power * a;
                    counter <= counter + 1;
                    done_power <= 0; //������ʵ���߼��ǲ���Ҫ�ģ�����Ϊ�˱��ջ����ظ�����done_powerΪ0
                end 
                else if (data_vld == 1 && counter >= b) begin
                    //�����Խ��м���ʱ�����Ѿ�����˼��㣨counter >= b��ʱ
                    //���� done_power Ϊ 1����ʾ���Դ�����module��
                    result_power <= result_power;
                    counter <= counter;
                    done_power <= 1;
                end 
                else begin //���������Խ��м���ʱ������reset״̬
                    result_power <= result_power;
                    done_power <= 0;
                    counter <= 0;
                end
             end 
             else begin //������� power command���򱣳�reset״̬
                  result_power <= 1;
                  done_power <= 0;
                  counter <= 0;
             end
        end
    end
endmodule
