`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/08/23 16:16:12
// Design Name: 
// Module Name: top_module_of_smart_farm
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


module top_module_of_smart_farm(

    );
endmodule


// Water level control module
module water_level_control (
    input clk, reset_p,
    input vauxp15, vauxn15,
    output water_flag );
    
    // Declare variables.
    wire eoc_out; // End of convert, ��ȯ ���� ��ȣ
    wire [4:0] channel_out; // ���� ���õ� ä��
    wire [15:0] do_out;
    
    // Instance of xadc_wiz module
    xadc_wiz_2 adc_water_level (
          .daddr_in({2'b0, channel_out}),   // XADC �������Ϳ� �����ϱ� ���� �ּҸ� ����
          .dclk_in(clk),                    // xadc ����� clk ����
          .den_in(eoc_out),                 // den_in�� eoc_out�� ���� ������ ��ȯ ��ȣ�� �����ٴ� ��ȣ�� 
                                            // ������ ������ ������ �����ϰ� �ȴ�.
   
          .reset_in(reset_p),               // �ý��� ��� ���� ���� ��ȣ
          .vauxp15(vauxp15),                  // Auxiliary channel 6
          .vauxn15(vauxn15),
          .channel_out(channel_out),        // ä�� ���� ���, ���� ���õ� ä���� ��Ÿ����.
          .do_out(do_out),                  // �Ƴ��α� ��ȣ�� ������ ������ ��ȯ�� ��� ��
          .eoc_out(eoc_out));               // ��ȯ ���� ��ȣ );
    
    
    // do_out ���� 100�̸� �̸� ���� ������ ���� ----> 1
    // do_out ���� 100�̻� �̸� ���� ����� ���� ----> 0
    assign water_flag  = (do_out[15:9] < 100) ? 1 : 0;
    
endmodule



// hc_sr04_control 
module hc_sr04_control (
    input clk, reset_p, 
    input hc_sr04_echo,
    output hc_sr04_trig,
    output led_up_down );
    
    // Instance of HC_SR04 Control module
    wire [21:0] distance_cm;
    HC_SR04_cntr HC_SR04_cntr_0(.clk(clk), .reset_p(reset_p), .hc_sr04_echo(hc_sr04_echo), .hc_sr04_trig(hc_sr04_trig), .distance(distance_cm),  .led_debug(led_debug));
    
    // ���� �Ĺ� ���� �Ÿ��� 10cm �̸��̸� led_up_down = 1
    //      �Ĺ� ���� �Ÿ��� 10cm �̻��̸� led_uo_down = 0
    assign led_up_down = (distance_cm < 22'd10) ? 1 : 0;
    
endmodule
