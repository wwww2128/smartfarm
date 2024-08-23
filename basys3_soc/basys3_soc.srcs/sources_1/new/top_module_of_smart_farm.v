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
    wire eoc_out; // End of convert, 변환 종료 신호
    wire [4:0] channel_out; // 현재 선택된 채널
    wire [15:0] do_out;
    
    // Instance of xadc_wiz module
    xadc_wiz_2 adc_water_level (
          .daddr_in({2'b0, channel_out}),   // XADC 레지스터에 접근하기 위한 주소를 지정
          .dclk_in(clk),                    // xadc 모듈의 clk 설정
          .den_in(eoc_out),                 // den_in는 eoc_out로 부터 디지털 변환 신호를 끝났다는 신호를 
                                            // 받으면 데이터 전송을 시작하게 된다.
   
          .reset_in(reset_p),               // 시스템 제어를 위한 리셋 신호
          .vauxp15(vauxp15),                  // Auxiliary channel 6
          .vauxn15(vauxn15),
          .channel_out(channel_out),        // 채널 선택 출력, 현재 선택된 채널을 나타낸다.
          .do_out(do_out),                  // 아날로그 신호를 디지털 값으로 변환된 결과 값
          .eoc_out(eoc_out));               // 변환 종료 신호 );
    
    
    // do_out 값이 100미만 이면 물이 부족한 상태 ----> 1
    // do_out 값이 100이상 이면 물이 충분한 상태 ----> 0
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
    
    // 만약 식물 간에 거리가 10cm 미만이면 led_up_down = 1
    //      식물 간에 거리가 10cm 이상이면 led_uo_down = 0
    assign led_up_down = (distance_cm < 22'd10) ? 1 : 0;
    
endmodule
