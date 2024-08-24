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

// Top moudle of Smarr Farm
module top_module_of_smart_farm(
    input clk, reset_p,
    input [2:0] btn,
    input [3:0] sw,
    inout dht11_data,
    input vauxp6, vauxn6,
    input vauxp15, vauxn15,
    input hc_sr04_echo,
    output hc_sr04_trig,
    output window_pwm);
    
    // Button Control module
    wire btn_electric_fan_mode, btn_led_mode, btn_window_mode;
    button_cntr btn0(.clk(clk), .reset_p(reset_p), .btn(btn[0]), .btn_pedge(btn_electric_fan_mode));
    button_cntr btn1(.clk(clk), .reset_p(reset_p), .btn(btn[1]), .btn_pedge(btn_led_mode));
    button_cntr btn2(.clk(clk), .reset_p(reset_p), .btn(btn[2]), .btn_pedge(btn_window_mode));
    
    // Declare Switch
    wire sw_led_up, sw_led_down, sw_window_open, sw_window_close;
    assign sw_led_up = sw[0];
    assign sw_led_down = sw[1];
    assign sw_window_open = sw[2];
    assign sw_window_close = sw[3];
    
    // Declare sensor variables.
    wire [15:0] dht11_value;
    wire [7:0] sunlight_value;
    wire water_flag;
    wire led_up_down;
    wire [7:0] distance_between_plant_and_LED;
    
    // Instance of sensor module
    dht11_control dht11_control_instance (.clk(clk), .reset_p(reset_p), .dht11_data(dht11_data), .dht11_value(dht11_value));
    cds_control cds_control_instance (.clk(clk), .reset_p(reset_p), .vauxp6(vauxp6), .vauxn6(vauxn6), .sunlight_value(sunlight_value));
    water_level_control water_level_control_instance (.clk(clk), .reset_p(reset_p), .vauxp15(vauxp15), .vauxn15(vauxn15), .water_flag(water_flag));
    hc_sr04_control hc_sr04_control_instance (.clk(clk), .reset_p(reset_p), .hc_sr04_echo(hc_sr04_echo), .hc_sr04_trig(hc_sr04_trig), .led_up_down(led_up_down), .distance_between_plant_and_led(distance_between_plant_and_led));
    
    // Instance of Control module
    window_control window_control_instance (.clk(clk), .reset_p(reset_p), .dht11_value(dht11_value), .sw_window_open(sw_window_open), .sw_window_close(sw_window_close), .btn_window_control(btn_window_control), .window_pwm(window_pwm));
    
    // Show temperature, humidity to FND
    show_the_fnd show_the_fnd_instance(.clk(clk), .reset_p(reset_p), .hex_value(dht11_value), .com(com), .seg_7(seg_7));
    
    
endmodule

///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
////////////////////////        temp Module        ////////////////////////////
///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////

module show_the_fnd (
    input clk, reset_p,
    input [15:0] hex_value,
    output [3:0] com,
    output [7:0] seg_7);
    
    // Convert from binary to BCD Code
    wire [15:0] temperature_bcd, humidity_bcd;
    bin_to_dec bcd_temp(.bin({4'b0, hex_value[15:8]}),  .bcd(temperature_bcd));
    bin_to_dec bcd_humi(.bin({4'b0, hex_value[7:0]}),  .bcd(humidity_bcd));
    
    // FND Control module
    fnd_cntr fnd_cntr_instance (.clk(clk), .reset_p(reset_p), .value({temperature_bcd[7:0], humidity_bcd[7:0]}), .com(com), .seg_7(seg_7));
    
endmodule


//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
////////////////////////        Senseor Module        ////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////


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
    output led_up_down,
    output [7:0] distance_between_plant_and_led );
    
    // Instance of HC_SR04 Control module
    wire [21:0] distance_cm;
    HC_SR04_cntr HC_SR04_cntr_0(.clk(clk), .reset_p(reset_p), .hc_sr04_echo(hc_sr04_echo), .hc_sr04_trig(hc_sr04_trig), .distance(distance_cm),  .led_debug(led_debug));
    
    // 만약 식물 간에 거리가 10cm 미만이면 led_up_down = 1
    //      식물 간에 거리가 10cm 이상이면 led_uo_down = 0
    assign led_up_down = (distance_cm < 22'd10) ? 1 : 0;
    
    // 현재 식물과 LED간에 거리를 출력한다.
    assign distance_between_plant_and_led = distance_cm[7:0];
    
endmodule




// DHT11 Control module
module dht11_control(
    input clk, reset_p, 
    inout dht11_data,
    output [15:0] dht11_value);

    wire [7:0] humidity, temperature; 
    dht11_cntrl dth11( .clk(clk), .reset_p(reset_p), .dht11_data(dht11_data), .humidity(humidity), .temperature(temperature), .led_debug(led_debug));


    assign dht11_value = {humidity[7:0], temperature[7:0]};

endmodule




// Cds Control module (sunlight)
module cds_control (
       input clk, reset_p,
       input vauxp6, vauxn6,
       output [7:0] sunlight_value);

       wire [4:0] channel_out;
       wire [16:0] do_out;
       wire eoc_out;

        // ADC Module instance
       xadc_wiz_3 xadc_cds (
        .daddr_in({2'b0, channel_out}),
        .dclk_in(clk),
        .den_in(eoc_out),
        .reset_in(reset_p),
        .vauxp6(vauxp6),
        .vauxn6(vauxn6),
        .channel_out(channel_out),
        .do_out(do_out),
        .eoc_out(eoc_out)
    );

    assign sunlight_value = do_out[15:8];

endmodule



//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
////////////////////////        Control Module        ////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////



// Window control module
module window_control (
    input clk, reset_p,
    input [15:0] dht11_value,
    input sw_window_open,
    input sw_window_close,
    input btn_window_control,
    output window_pwm );
    
    // Declare temperature, humidity 
    wire [7:0] temperature, humidity;
    assign temperature = dht11_value [15:8];
    assign humidity = dht11_value [7:0];
    
    // Declare state machine.
    parameter S_MANUAL_MODE = 2'b01;
    parameter S_AUTO_MODE = 2'b10;
    
    // Declare state, next state variables
    reg [1:0] state, next_state;
    
    // 언제 다음 상태 단계로 전이되는가?
    always @(posedge clk or posedge reset_p) begin
        if(reset_p) state = S_MANUAL_MODE;
        else state = next_state;
    end
    
    // Declare duty of window
    // min_duty == Window Open 상태
    // max_duty == Window Close 상태
    reg [5:0] duty, min_duty, max_duty;

    
    // 각 상태 단계의 동작 및 다음 상태 전이 조건 정의
    always @(negedge clk or posedge reset_p) begin
        if(reset_p) begin
           next_state =  S_MANUAL_MODE;
           duty = max_duty;
           max_duty = 6'd25;
           min_duty = 6'd5;
        end
        else begin
            case (state) 
                // 1단계) 수동 조작 단계
                S_MANUAL_MODE: begin
                    if(sw_window_open && duty > min_duty) duty = duty - 1;
                    if(sw_window_close && duty < max_duty) duty = duty + 1;                    
                end
                
                // 2단계) 자동 조작 단계
                 S_AUTO_MODE : begin
                    if(temperature <= 20 || humidity < 40) duty = max_duty;
                    else if(temperature <= 24 || humidity < 60) duty = 6'd16;
                    else if(temperature >= 28 || humidity >= 60) duty = min_duty; 
                 end   
            endcase 
        end
    end
    
    // Instance of pwm_control module
    pwm_Nstep_freq #(
    .duty_step(200),
    .pwm_freq(50)) 
    pwm_servo_motor (.clk(clk), .reset_p(reset_p), .duty(duty), .pwm(window_pwm));
    
endmodule