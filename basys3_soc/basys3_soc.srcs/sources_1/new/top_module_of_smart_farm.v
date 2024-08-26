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
module top_module_of_smart_farm (
    input clk, reset_p,
    input [3:0] btn,
    input [15:0] sw,
    inout dht11_data,
    input vauxp6, vauxn6,
    input vauxp15, vauxn15,
    input hc_sr04_echo,
    output hc_sr04_trig,
<<<<<<< Updated upstream
    output window_pwm);
=======
    output window_pwm,
    output fan_pwm,
    output fan_dir_pwm,
    output led_pwm,
    output warning_water_level_led,
    output pump_on_off,
    output [3:0] com,
    output [7:0] seg_7,
    output led_debug);
    
    assign led_debug = water_flag;
>>>>>>> Stashed changes
    
    // Button Control module
    wire btn_led_light, btn_window_mode, btn_electric_fan_power;
    button_cntr btn0(.clk(clk), .reset_p(reset_p), .btn(btn[0]), .btn_pedge(btn_led_light));
    button_cntr btn1(.clk(clk), .reset_p(reset_p), .btn(btn[1]), .btn_pedge(btn_window_mode));
    button_cntr btn2(.clk(clk), .reset_p(reset_p), .btn(btn[2]), .btn_pedge(btn_electric_fan_power));
    
    // Declare Switch
    wire sw_led_up, sw_led_down, sw_window_open, sw_window_close, sw_cntr_electirc_fan_dir, sw_electric_fan_mode;
    wire sw_led_mode;
    assign sw_led_up = sw[0];
    assign sw_led_down = sw[1];
    assign sw_window_open = sw[2];
    assign sw_window_close = sw[3];
    assign sw_led_mode = sw[10];
    assign sw_cntr_electirc_fan_dir = sw[14];
    assign sw_electric_fan_mode = sw[15];
    
    // Declare sensor variables.
    wire [15:0] dht11_value;
    wire [7:0] sunlight_value;
    wire water_flag;
    wire led_up_down;
    wire [7:0] distance_between_plant_and_LED;
    
    // Instance of sensor module
    dht11_control dht11_control_instance (.clk(clk), .reset_p(reset_p), .dht11_data(dht11_data), .dht11_value(dht11_value));
    cds_and_water_level_control cds_and_water_level_control_instance (.clk(clk), .reset_p(reset_p), .vauxp6(vauxp6), .vauxn6(vauxn6), .vauxp15(vauxp15), .vauxn15(vauxn15), .water_flag(water_flag), .sunlight_value(sunlight_value) );
    hc_sr04_control hc_sr04_control_instance (.clk(clk), .reset_p(reset_p), .hc_sr04_echo(hc_sr04_echo), .hc_sr04_trig(hc_sr04_trig), .led_up_down(led_up_down), .distance_between_plant_and_led(distance_between_plant_and_led));
    
    // Instance of Control module
<<<<<<< Updated upstream
    window_control window_control_instance (.clk(clk), .reset_p(reset_p), .dht11_value(dht11_value), .sw_window_open(sw_window_open), .sw_window_close(sw_window_close), .btn_window_control(btn_window_control), .window_pwm(window_pwm));
    
    // Show temperature, humidity to FND
    show_the_fnd show_the_fnd_instance(.clk(clk), .reset_p(reset_p), .hex_value(dht11_value), .com(com), .seg_7(seg_7));
=======
    window_control window_control_instance (.clk(clk), .reset_p(reset_p), .dht11_value(dht11_value), .sw_window_open(sw_window_open), .sw_window_close(sw_window_close), .btn_window_control(btn_window_mode), .window_pwm(window_pwm));
    electric_fan_control electric_fan_control_instance (.clk(clk), .reset_p(reset_p), .sw_cntr_electirc_fan_dir(sw_cntr_electirc_fan_dir), .sw_electric_fan_mode(sw_electric_fan_mode), .dht11_value(dht11_value), .btn_electric_fan_power(btn_electric_fan_power), .fan_pwm(fan_pwm), .fan_dir_pwm(fan_dir_pwm));
    led_control led_control_instance (.clk(clk), .reset_p(reset_p), .sw_led_mode(sw_led_mode), .btn_led_light(btn_led_light), .water_flag(water_flag), .sunlight_value(sunlight_value), .led_pwm(led_pwm), .warning_water_level_led(warning_water_level_led));
    water_pump water_pump_instance (.clk(clk), .reset_p(reset_p), .water_flag(water_flag), .pump_on_off(pump_on_off));
    
    // Show temperature, humidity to FND
    show_the_fnd show_the_fnd_instance(.clk(clk), .reset_p(reset_p), .hex_value(dht11_value), .sunlight_value(sunlight_value), .com(com), .seg_7(seg_7));
>>>>>>> Stashed changes
    
    
endmodule

///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
////////////////////////        temp Module        ////////////////////////////
///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
<<<<<<< Updated upstream

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

=======
>>>>>>> Stashed changes

module show_the_fnd (
    input clk, reset_p,
    input [15:0] hex_value,
    input [7:0] sunlight_value,
    output [3:0] com,
    output [7:0] seg_7);
    
    // Convert from binary to BCD Code
    wire [15:0] temperature_bcd, humidity_bcd;
    bin_to_dec bcd_temp(.bin({4'b0, hex_value[15:8]}),  .bcd(temperature_bcd));
    bin_to_dec bcd_humi(.bin({4'b0, sunlight_value[7:0]}),  .bcd(humidity_bcd));
    
    // FND Control module
    fnd_cntr fnd_cntr_instance (.clk(clk), .reset_p(reset_p), .value(humidity_bcd), .com(com), .seg_7(seg_7));
    
endmodule


//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
////////////////////////        Senseor Module        ////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////


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

    assign dht11_value = {temperature[7:0], humidity[7:0]};

endmodule



// cds_and_water_level_control module
module cds_and_water_level_control (
    input clk, reset_p,
    input vauxp6, vauxn6,
    input vauxp15, vauxn15,
    output reg water_flag,
    output reg [7:0] sunlight_value );
    
     wire [4:0] channel_out;
     wire [16:0] do_out;
     wire eoc_out;

<<<<<<< Updated upstream
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
=======
     // ADC Module instance
       xadc_wiz_10 xadc_cds (
>>>>>>> Stashed changes
        .daddr_in({2'b0, channel_out}),
        .dclk_in(clk),
        .den_in(eoc_out),
        .reset_in(reset_p),
        .vauxp6(vauxp6),
        .vauxn6(vauxn6),
        .vauxp15(vauxp15),
        .vauxn15(vauxn15),
        .channel_out(channel_out),
        .do_out(do_out),
        .eoc_out(eoc_out)
    );
    
    // Get positive edge of eoc_out.
    wire eoc_out_pedge;
    edge_detector_p ed_eoc_out_cds(.clk(clk), .reset_p(reset_p), .cp(eoc_out), .p_edge(eoc_out_pedge));
    
    // Channel_out 변수 값에 따라 변환된 Channel이 무엇인지를 확인 후, 해당 값을 출력
    // do_out 값이 100미만 이면 물이 부족한 상태 ----> 1
    // do_out 값이 100이상 이면 물이 충분한 상태 ----> 0  
    always @(posedge clk or posedge reset_p) begin
        if(reset_p) begin
            sunlight_value = 0;
            water_flag = 0;
        end
        else if(eoc_out_pedge) begin
            case(channel_out[3:0])
                6 : begin sunlight_value = do_out[15:8]; end
                15 : begin water_flag  = (do_out[15:9] < 100) ? 1 : 0; end
            endcase
        end
    end
     
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
        else if(btn_window_control) state = next_state;
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
                    
                    next_state = S_AUTO_MODE;        
                end
                
                // 2단계) 자동 조작 단계
                 S_AUTO_MODE : begin
                    if(temperature < 8'd27 || humidity < 8'd40) duty = max_duty;
                    else duty = min_duty;
                    
                    next_state = S_MANUAL_MODE;
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



// Electric Fan Control
module electric_fan_control (
    input clk, reset_p,
    input sw_cntr_electirc_fan_dir,
    input sw_electric_fan_mode,
    input btn_electric_fan_power,
    input [15:0] dht11_value,
    output fan_pwm, fan_dir_pwm );
    
    // Declare state machine
    parameter S_MANUAL_MODE = 2'b01;
    parameter S_AUTO_MODE = 2'b10;
    
    // Declare state, next state
    reg [1:0] power_state;
    
    // 언제 다음 상태로 넘어가는가?
    always @(posedge clk or posedge reset_p) begin
        if(reset_p) power_state = S_MANUAL_MODE; 
        else if(sw_electric_fan_mode) power_state = S_AUTO_MODE;
        else if(!sw_electric_fan_mode) power_state = S_MANUAL_MODE;
    end
    
    // Register duty of electirc fan.
    reg [1:0] fan_manual_duty, fan_auto_duty;   
    
    
    // Declare temperature, humidity 
    wire [7:0] temperature, humidity;
    assign temperature = dht11_value [15:8];
    assign humidity = dht11_value [7:0];
    
    // 각 상태의 동작 및 다음 상태 단계로 전이되기 위한 조건 정의
    always @(negedge clk or posedge reset_p) begin
        if(reset_p) begin
            fan_manual_duty = 0;
            fan_auto_duty = 0;
        end
        else begin
            case(power_state)
                S_MANUAL_MODE : begin
                    if(btn_electric_fan_power) begin
                        if(fan_manual_duty >= 3) fan_manual_duty = 0;
                        else fan_manual_duty = fan_manual_duty + 1;
                    end
                end
                
                S_AUTO_MODE : begin
                    if(temperature < 27) fan_auto_duty = 0;
                    else if(27 <= temperature && temperature < 29) fan_auto_duty = 1;
                    else if(29 <= temperature && temperature <= 31) fan_auto_duty = 2;
                    else if(temperature > 31) fan_auto_duty = 3;
                end
           endcase        
        end
    end
    
    // Select duty of electric fan
    wire [1:0] duty;
    assign duty = (power_state == S_MANUAL_MODE) ? fan_manual_duty : fan_auto_duty;
    
    // Get pwm of electric fan
    pwm_cntr #(.pwm_freq(100), .duty_step(4)) control_power_pwm (.clk(clk), .reset_p(reset_p), .duty(duty), .pwm(fan_pwm));
  
    
    
    
    // Declare State Machine
    parameter S_SERVO_STOP = 2'b01;
    parameter S_SERVO_START = 2'b10;
    
    // Declcare state variable
    reg [1:0] dir_state;
    
    // Declare necessary variables
    reg [4:0] dir_duty;
    reg [4:0] dir_min_duty = 5'd5;
    reg [4:0] dir_max_duty = 5'd25;
    reg direction_of_fan; // direction_of_fan == 0 이면 감소, direction_of_fan == 1 이면 증가
    
    // 언제 다음 state로 전이되는가>
    always @(posedge clk or posedge reset_p) begin
        if(reset_p) dir_state = S_SERVO_STOP;
        else if(sw_cntr_electirc_fan_dir) dir_state = S_SERVO_START;
        else if(!sw_cntr_electirc_fan_dir) dir_state = S_SERVO_STOP;
    end
  
    always @(negedge clk or posedge reset_p) begin
        if(reset_p) begin
            dir_duty = 5'd15;
            direction_of_fan = 0;
        end
        else begin
            case(dir_state)
                S_SERVO_STOP : begin
                    dir_duty = dir_duty;
                end
            
                S_SERVO_START : begin
                    if(direction_of_fan) begin
                        if(dir_duty == dir_max_duty) begin
                            dir_duty = dir_duty - 1;
                            direction_of_fan = ~ direction_of_fan;
                        end
                        else dir_duty = dir_duty + 1;
                    end
                    else begin
                        if(dir_duty == dir_min_duty) begin
                            dir_duty = dir_duty + 1;
                            direction_of_fan = ~ direction_of_fan;
                        end
                        else dir_duty = dir_duty - 1;
                    end
                end
            endcase
        end
    end
  
    // Get pwm of servo-motor
    pwm_cntr #(.pwm_freq(50), .duty_step(200)) control_servo_pwm (.clk(clk), .reset_p(reset_p), .duty(dir_duty), .pwm(fan_dir_pwm));

endmodule



<<<<<<< Updated upstream
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
=======

// LED Control module
module led_control (
    input clk, reset_p,
    input sw_led_mode,
    input btn_led_light,
    input water_flag,
    input [7:0] sunlight_value,
    output led_pwm, warning_water_level_led );
    
    // Warning Water Level LED
    assign warning_water_level_led = water_flag;
    
    // Main LED Control
    // Declare state machine
    parameter S_MANUAL_MODE = 2'b01;
    parameter S_AUTO_MODE = 2'B10;
    
    // Declare state variable
    reg [1:0] state;
    
    // Declare duty variabels
    wire [2:0] led_duty;
    reg [2:0] manual_duty;
    reg [7:0] auto_duty;
    wire manual_pwm, auto_pwm;
    
    // 언제 다음 상태로 전이되는가?
    always @(posedge clk or posedge reset_p) begin
        if(reset_p) state = S_MANUAL_MODE;
        else if(sw_led_mode) state = S_AUTO_MODE;
        else if(!sw_led_mode) state = S_MANUAL_MODE;
    end
    
    // 각 상태에 대한 행동 및 다음 상태로 전이되기 위한 조건 정의
    always @(negedge clk or posedge reset_p) begin
        if(reset_p) begin
            manual_duty = 0;
            auto_duty = 0;
        end
        else begin
            case(state) 
                S_MANUAL_MODE : begin
                    if(btn_led_light) begin
                        if(manual_duty >= 5) manual_duty = 0;
                        else manual_duty = manual_duty + 1;
                    end
                end
                
                S_AUTO_MODE : begin
                   auto_duty = 256 - sunlight_value;
                   
                   if(auto_duty <= 50) auto_duty = 0;
                end
            endcase
        end
    end
    
    // Instance of pwm control
    pwm_cntr #(.pwm_freq(10_000), .duty_step(6)) control_manual_led_pwm (.clk(clk), .reset_p(reset_p), .duty(manual_duty), .pwm(manual_pwm));
    pwm_cntr #(.pwm_freq(10_000), .duty_step(256)) control_auto_led_pwm (.clk(clk), .reset_p(reset_p), .duty(auto_duty), .pwm(auto_pwm));
    
    // Select led pwm
    assign led_pwm = (state == S_MANUAL_MODE) ? manual_pwm : auto_pwm;
    
endmodule



// LCD Display Control
module lcd_display_control (
    input clk, reset_p,
    input [15:0] dht11_value,
    input [7:0] sunlight_value,
    input water_flag,
    output scl, sda );
    
    
    
endmodule

// LED Height Control module
module led_height_control (
    input clk, reset_p,
    input led_up_down,
    input sw_led_up, sw_led_down,
    output led_height_pwm );
        
    
endmodule


// Water Pump Control module
module water_pump (
    input clk, reset_p,
    input water_flag,
    output pump_on_off );
    
    assign pump_on_off = water_flag;
>>>>>>> Stashed changes
    
endmodule