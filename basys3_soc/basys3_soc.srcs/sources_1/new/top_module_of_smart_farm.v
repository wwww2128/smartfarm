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
    input rx,
    output tx,
    output hc_sr04_trig,
    output left_window_pwm, right_window_pwm,
    output fan_pwm,
    output fan_dir_pwm,
    output led_pwm,
    output warning_water_level_led,
    output pump_on_off,
    output [3:0] half_step_mode_sequence,
    output scl, sda,
    output [3:0] com,
    output [7:0] seg_7);
    
    // Button Control module
    wire btn_led_light, btn_window_mode, btn_electric_fan_power;
    button_cntr btn0(.clk(clk), .reset_p(reset_p), .btn(btn[0]), .btn_pedge(btn_led_light));
    button_cntr btn1(.clk(clk), .reset_p(reset_p), .btn(btn[1]), .btn_pedge(btn_window_mode));
    button_cntr btn2(.clk(clk), .reset_p(reset_p), .btn(btn[2]), .btn_pedge(btn_electric_fan_power));
    
    // Declare Switch
    wire sw_led_up, sw_led_down, sw_window_open, sw_window_close, sw_cntr_electirc_fan_dir, sw_electric_fan_mode;
    wire sw_led_mode, sw_led_height_mode;
    assign sw_led_height_mode = sw[0];
    assign sw_led_up = sw[1];
    assign sw_led_down = sw[2];
    assign sw_window_open = sw[6];
    assign sw_window_close = sw[7];
    assign sw_led_mode = sw[10];
    assign sw_cntr_electirc_fan_dir = sw[11];
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
    window_control window_control_instance (.clk(clk), .reset_p(reset_p), .dht11_value(dht11_value), .sw_window_open(sw_window_open), .sw_window_close(sw_window_close), .btn_window_control(btn_window_mode), .left_window_pwm(left_window_pwm), .right_window_pwm(right_window_pwm));
    electric_fan_control electric_fan_control_instance (.clk(clk), .reset_p(reset_p), .sw_cntr_electirc_fan_dir(sw_cntr_electirc_fan_dir), .sw_electric_fan_mode(sw_electric_fan_mode), .dht11_value(dht11_value), .btn_electric_fan_power(btn_electric_fan_power), .fan_pwm(fan_pwm), .fan_dir_pwm(fan_dir_pwm));
    led_control led_control_instance (.clk(clk), .reset_p(reset_p), .sw_led_mode(sw_led_mode), .btn_led_light(btn_led_light), .water_flag(water_flag), .sunlight_value(sunlight_value), .led_pwm(led_pwm), .warning_water_level_led(warning_water_level_led));
    water_pump water_pump_instance (.clk(clk), .reset_p(reset_p), .water_flag(water_flag), .pump_on_off(pump_on_off));  
    led_height_control led_height_control_instance ( .clk(clk), .reset_p(reset_p), .sw_led_height_mode(sw_led_height_mode), .led_up_down(led_up_down), .distance_between_plant_and_led(distance_between_plant_and_led),
                        .sw_led_up(sw_led_up), .sw_led_down(sw_led_down), .half_step_mode_sequence(half_step_mode_sequence));
    
    // Instance of a module that displays temperature and humidity information      
    lcd_display_control lcd_display_control_instance (.clk(clk), .reset_p(reset_p), .dht11_value(dht11_value), .sunlight_value(sunlight_value), .water_flag(water_flag), .scl(scl), .sda(sda));
    uart_app_control uart_app_control_instance (.clk(clk), .reset_p(reset_p), .rx(rx), .dht11_value(dht11_value), .tx(tx));
    
    // Show temperature, humidity to FND
    show_the_fnd show_the_fnd_instance(.clk(clk), .reset_p(reset_p), .hex_value(dht11_value), .sunlight_value(sunlight_value), .com(com), .seg_7(seg_7));
    
    
endmodule

///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
////////////////////////        temp Module        ////////////////////////////
///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////

module show_the_fnd (
    input clk, reset_p,
    input [15:0] hex_value,
    input [7:0] sunlight_value,
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
    
    // 만약 식물 간에 거리가 5cm 미만이면 led_up_down = 1
    //      식물 간에 거리가 5cm 이상이면 led_uo_down = 0
    assign led_up_down = (distance_cm < 22'd5) ? 1 : 0;
    
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

     // ADC Module instance
       xadc_wiz_10 xadc_cds (
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
    output left_window_pwm, right_window_pwm);
    
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
    // right_min_duty == Window Open, right_max_duty == Window Close
    // left_min_duty == Window Close, left_max_duty == Window Open
    reg [5:0] left_duty, right_duty;
    reg [5:0] right_min_duty, right_max_duty;
    reg [5:0] left_min_duty, left_max_duty;

    
    // 각 상태 단계의 동작 및 다음 상태 전이 조건 정의
    always @(negedge clk or posedge reset_p) begin
        if(reset_p) begin
           next_state =  S_MANUAL_MODE;
           right_duty = right_max_duty;
           left_duty = left_min_duty;
              
           right_max_duty = 6'd21;
           right_min_duty = 6'd5;
           
           left_max_duty = 6'd25;
           left_min_duty = 6'd9;
        end
        else begin
            case (state) 
                // 1단계) 수동 조작 단계
                S_MANUAL_MODE: begin
                    if(sw_window_open) begin
                        if(right_duty > right_min_duty) right_duty = right_duty - 1;
                        if(left_duty < left_max_duty) left_duty = left_duty + 1;
                    end
                    else if(sw_window_close) begin
                        if(right_duty < right_max_duty) right_duty = right_duty + 1;
                        if(left_duty > left_min_duty) left_duty = left_duty - 1;
                    end 
                    
                    next_state = S_AUTO_MODE;        
                end
                
                // 2단계) 자동 조작 단계
                 S_AUTO_MODE : begin
                    if(temperature < 8'd27 || humidity < 8'd40) begin
                        right_duty = right_max_duty;
                        left_duty = left_min_duty;
                    end
                    else begin 
                        right_duty = right_min_duty;
                        left_duty = left_max_duty;
                    end
                    
                    next_state = S_MANUAL_MODE;
                 end   
            endcase 
        end
    end
    
    // Instance of pwm_control module
    pwm_Nstep_freq #(
    .duty_step(200),
    .pwm_freq(50)) 
    pwm_right_servo_motor (.clk(clk), .reset_p(reset_p), .duty(right_duty), .pwm(right_window_pwm));
    
    pwm_Nstep_freq #(
    .duty_step(200),
    .pwm_freq(50)) 
    pwm_left_servo_motor (.clk(clk), .reset_p(reset_p), .duty(left_duty), .pwm(left_window_pwm));
    
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
    
    // clock divider 1sec
    wire clk_1usec, clk_1msec, clk_1sec;
    clock_div_100   usec_clk( .clk(clk), .reset_p(reset_p), .clk_div_100(clk_1usec)); 
    clock_div_1000 msec_clk(.clk(clk), .reset_p(reset_p), .clk_source(clk_1usec), .clk_div_1000_nedge(clk_1msec));
    clock_div_1000 sec_clk(.clk(clk), .reset_p(reset_p), .clk_source(clk_1msec), .clk_div_1000_nedge(clk_1sec));
    
    // Declare necessary variables
    reg [4:0] dir_duty;
    reg [4:0] dir_min_duty;
    reg [4:0] dir_max_duty;
    reg direction_of_fan; // direction_of_fan == 0 이면 감소, direction_of_fan == 1 이면 증가
    
    // 언제 다음 state로 전이되는가>
    always @(posedge clk or posedge reset_p) begin
        if(reset_p) dir_state = S_SERVO_STOP;
        else if(sw_cntr_electirc_fan_dir) dir_state = S_SERVO_START;
        else if(!sw_cntr_electirc_fan_dir) dir_state = S_SERVO_STOP;
    end
  
    always @(negedge clk or posedge reset_p) begin
        if(reset_p) begin
            dir_min_duty = 5'd8;
            dir_max_duty = 5'd22;
            dir_duty = 5'd15;
            direction_of_fan = 0;
        end
        else if(clk_1sec) begin
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

// LED Height Control module
module led_height_control(
    input clk, reset_p,
    input sw_led_height_mode,
    input led_up_down,
    input [7:0] distance_between_plant_and_led,
    input sw_led_up, sw_led_down,
    output [3:0] half_step_mode_sequence);
    
    // Declare necessary variables
    reg up_down, motor_enable;
    
    // Select up_down, motor_enable
    always @(posedge clk or posedge reset_p) begin
        if(reset_p) begin
            up_down = 1;
            motor_enable = 0;
        end
        else begin
            if(sw_led_up) begin
                up_down = 1;
                if(sw_led_down) motor_enable = 0;
                else motor_enable = 1;
            end
            else if(sw_led_down) begin
                up_down = 0;
                if(sw_led_up) motor_enable = 0;
                else motor_enable = 1;
            end
            else motor_enable = 0;
        end
    end
    
    
    // Instance of Step motor control module
    step_motor_control step_motor_control_instance (.clk(clk), .reset_p(reset_p), .up_down(up_down), .motor_enable(motor_enable), .half_step_mode_sequence(half_step_mode_sequence));
endmodule


// Step Motor Control Module
module step_motor_control (
    input clk, reset_p,
    input up_down,
    input motor_enable,
    output reg [3:0] half_step_mode_sequence );
    
    // 1msec clk
    wire clk_1usec, clk_1mssec;
    clock_div_100 usec_clk( .clk(clk), .reset_p(reset_p), .clk_div_100(clk_1usec));
    clock_div_1000 msec_clk(.clk(clk), .reset_p(reset_p), .clk_source(clk_1usec), .clk_div_1000_nedge(clk_1mssec));
    
    // msecond counter
    reg [1:0] counter;
    reg counter_enable;
    
    always @(negedge clk or posedge reset_p) begin
        if(reset_p) counter = 0;
        else if(clk_1mssec && counter_enable) counter = counter + 1;
        else if(!counter_enable) counter = 0;       
    end
    
    // Control step motor
    // Half step 시퀀스
    wire [3:0] half_step_sequence [0:7];
    assign half_step_sequence[0] = 4'b1001; // 0x9
    assign half_step_sequence[1] = 4'b0001; // 0x1
    assign half_step_sequence[2] = 4'b0011; // 0x3
    assign half_step_sequence[3] = 4'b0010; // 0x2
    assign half_step_sequence[4] = 4'b0110; // 0x6
    assign half_step_sequence[5] = 4'b0100; // 0x4
    assign half_step_sequence[6] = 4'b1100; // 0xC
    assign half_step_sequence[7] = 4'b1000; // 0x8
    
    // Declare State Machine
    parameter S_SEND_SEQUENCE = 2'b01;
    parameter S_WAIT_1MS = 2'b10;
    
    reg [1:0] state, next_state;
    
    // 언제 다음 state로 전이되는가?
    always @(negedge clk or posedge reset_p) begin
        if(reset_p) state = S_SEND_SEQUENCE;
        else state = next_state;
    end
    
    // Delcare Data count
    reg [2:0] reg_cnt_data;
    
    always @(posedge clk or posedge reset_p) begin
        if(reset_p) begin
            counter_enable = 0; 
            reg_cnt_data = 0;
            next_state = S_SEND_SEQUENCE;
        end
        else begin
            if(motor_enable) begin
                case (state)
                    S_SEND_SEQUENCE : begin
                        case(up_down) 
                            1 : begin
                                half_step_mode_sequence = half_step_sequence[reg_cnt_data];
                                reg_cnt_data = reg_cnt_data + 1;
                            end
                    
                            0 : begin
                                half_step_mode_sequence = half_step_sequence[reg_cnt_data];
                                reg_cnt_data = reg_cnt_data - 1;
                            end 
                        endcase
                        
                        next_state = S_WAIT_1MS;
                    end
                    
                    S_WAIT_1MS : begin
                        if(counter < 2'd1) 
                            counter_enable = 1;
                        else begin
                            counter_enable = 0;
                            next_state = S_SEND_SEQUENCE;
                        end
                    end   
                endcase
            end
        end
    end
    
endmodule


// Water Pump Control module
module water_pump (
    input clk, reset_p,
    input water_flag,
    output pump_on_off );
    
    assign pump_on_off = water_flag;
    
endmodule

module baud_rate_generator
    #(              // 9600 baud
        parameter   N = 10,     // number of counter bits
                    M = 868     // counter limit value
    )
    (
        input clk,       // basys 3 clock
        input reset_p,            // reset
        output tick             // sample tick
    );
    
    // Counter Register
    reg [N-1:0] counter;        // counter value
    wire [N-1:0] next;          // next counter value
    
    // Register Logic
    always @(posedge clk, posedge reset_p)
        if(reset_p)
            counter <= 0;
        else
            counter <= next;
            
    // Next Counter Value Logic
    assign next = (counter == (M-1)) ? 0 : counter + 1;
    
    // Output Logic
    assign tick = (counter == (M-1)) ? 1'b1 : 1'b0;
       
endmodule


module uart_transmitter
    #(
        parameter   DBITS = 8,          // number of data bits
                    SB_TICK = 16        // number of stop bit / oversampling ticks (1 stop bit)
    )
    (
        input clk,               // basys 3 FPGA
        input reset_p,                    // reset
        input tx_start,                 // begin data transmission (FIFO NOT empty)
        input sample_tick,              // from baud rate generator
        input [DBITS-1:0] data_in,      // data word from FIFO
        output reg tx_done,             // end of transmission
        output tx                       // transmitter data line
    );
    
    // State Machine States
    localparam [1:0]    idle  = 2'b00,
                        start = 2'b01,
                        data  = 2'b10,
                        stop  = 2'b11;
    
    // Registers                    
    reg [1:0] state, next_state;            // state registers
    reg [3:0] tick_reg, tick_next;          // number of ticks received from baud rate generator
    reg [2:0] nbits_reg, nbits_next;        // number of bits transmitted in data state
    reg [DBITS-1:0] data_reg, data_next;    // assembled data word to transmit serially
    reg tx_reg, tx_next;                    // data filter for potential glitches
    
    // Register Logic
    always @(posedge clk or posedge reset_p)
        if(reset_p) begin
            state <= idle;
            tick_reg <= 0;
            nbits_reg <= 0;
            data_reg <= 0;
            tx_reg <= 1'b1;
        end
        else begin
            state <= next_state;
            tick_reg <= tick_next;
            nbits_reg <= nbits_next;
            data_reg <= data_next;
            tx_reg <= tx_next;
        end
    
    // State Machine Logic
    always @* begin
        next_state = state;
        tx_done = 1'b0;
        tick_next = tick_reg;
        nbits_next = nbits_reg;
        data_next = data_reg;
        tx_next = tx_reg;
        
        case(state)
            idle: begin                     // no data in FIFO
                tx_next = 1'b1;             // transmit idle
                if(tx_start) begin          // when FIFO is NOT empty
                    next_state = start;
                    tick_next = 0;
                    data_next = data_in;
                end
            end
            
            start: begin
                tx_next = 1'b0;             // start bit
                if(sample_tick)
                    if(tick_reg == 15) begin
                        next_state = data;
                        tick_next = 0;
                        nbits_next = 0;
                    end
                    else
                        tick_next = tick_reg + 1;
            end
            
            data: begin
                tx_next = data_reg[0];
                if(sample_tick)
                    if(tick_reg == 15) begin
                        tick_next = 0;
                        data_next = data_reg >> 1;
                        if(nbits_reg == (DBITS-1))
                            next_state = stop;
                        else
                            nbits_next = nbits_reg + 1;
                    end
                    else
                        tick_next = tick_reg + 1;
            end
            
            stop: begin
                tx_next = 1'b1;         // back to idle
                if(sample_tick)
                    if(tick_reg == (SB_TICK-1)) begin
                        next_state = idle;
                        tx_done = 1'b1;
                    end
                    else
                        tick_next = tick_reg + 1;
            end
        endcase    
    end
    
    // Output Logic
    assign tx = tx_reg;
 
endmodule

module uart_receiver
    #(
        parameter   DBITS = 8,          // number of data bits in a data word
                    SB_TICK = 16        // number of stop bit / oversampling ticks (1 stop bit)
    )
    (
        input clk,               // basys 3 FPGA
        input reset_p,                    // reset
        input rx,                       // receiver data line
        input sample_tick,              // sample tick from baud rate generator
        output reg data_ready,          // signal when new data word is complete (received)
        output [DBITS-1:0] data_out     // data to FIFO
    );
    
    // State Machine States
    localparam [1:0] idle  = 2'b00,
                     start = 2'b01,
                     data  = 2'b10,
                     stop  = 2'b11;
    
    // Registers                 
    reg [1:0] state, next_state;        // state registers
    reg [3:0] tick_reg, tick_next;      // number of ticks received from baud rate generator
    reg [2:0] nbits_reg, nbits_next;    // number of bits received in data state
    reg [7:0] data_reg, data_next;      // reassembled data word
    
    // Register Logic
    always @(posedge clk, posedge reset_p)
        if(reset_p) begin
            state <= idle;
            tick_reg <= 0;
            nbits_reg <= 0;
            data_reg <= 0;
        end
        else begin
            state <= next_state;
            tick_reg <= tick_next;
            nbits_reg <= nbits_next;
            data_reg <= data_next;
        end        

    // State Machine Logic
    always @* begin
        next_state = state;
        data_ready = 1'b0;
        tick_next = tick_reg;
        nbits_next = nbits_reg;
        data_next = data_reg;
        
        case(state)
            idle:
                if(~rx) begin               // when data line goes LOW (start condition)
                    next_state = start;
                    tick_next = 0;
                end
            start:
                if(sample_tick)
                    if(tick_reg == 7) begin
                        next_state = data;
                        tick_next = 0;
                        nbits_next = 0;
                    end
                    else
                        tick_next = tick_reg + 1;
            data:
                if(sample_tick)
                    if(tick_reg == 15) begin
                        tick_next = 0;
                        data_next = {rx, data_reg[7:1]};
                        if(nbits_reg == (DBITS-1))
                            next_state = stop;
                        else
                            nbits_next = nbits_reg + 1;
                    end
                    else
                        tick_next = tick_reg + 1;
            stop:
                if(sample_tick)
                    if(tick_reg == (SB_TICK-1)) begin
                        next_state = idle;
                        data_ready = 1'b1;
                    end
                    else
                        tick_next = tick_reg + 1;
        endcase                    
    end
    
    // Output Logic
    assign data_out = data_reg;

endmodule

module fifo
    #(
       parameter    DATA_SIZE      = 8,        // number of bits in a data word
                    ADDR_SPACE_EXP = 4         // number of address bits (2^4 = 16 addresses)
    )
    (
       input clk,                              // FPGA clock           
       input reset_p,                            // reset button
       input write_to_fifo,                    // signal start writing to FIFO
       input read_from_fifo,                   // signal start reading from FIFO
       input [DATA_SIZE-1:0] write_data_in,    // data word into FIFO
       output [DATA_SIZE-1:0] read_data_out,   // data word out of FIFO
       output empty,                           // FIFO is empty (no read)
       output full                             // FIFO is full (no write)
);

    // signal declaration
    reg [DATA_SIZE-1:0] memory [2**ADDR_SPACE_EXP-1:0];     // memory array register
    reg [ADDR_SPACE_EXP-1:0] current_write_addr, current_write_addr_buff, next_write_addr;
    reg [ADDR_SPACE_EXP-1:0] current_read_addr, current_read_addr_buff, next_read_addr;
    reg fifo_full, fifo_empty, full_buff, empty_buff;
    wire write_enabled;
    
    // register file (memory) write operation
    always @(posedge clk)
        if(write_enabled)
            memory[current_write_addr] <= write_data_in;
            
    // register file (memory) read operation
    assign read_data_out = memory[current_read_addr];
    
    // only allow write operation when FIFO is NOT full
    assign write_enabled = write_to_fifo & ~fifo_full;
    
    // FIFO control logic
    // register logic
    always @(posedge clk or posedge reset_p)
        if(reset_p) begin
            current_write_addr  <= 0;
            current_read_addr   <= 0;
            fifo_full           <= 1'b0;
            fifo_empty          <= 1'b1;       // FIFO is empty after reset
        end
        else begin
            current_write_addr  <= current_write_addr_buff;
            current_read_addr   <= current_read_addr_buff;
            fifo_full           <= full_buff;
            fifo_empty          <= empty_buff;
        end

    // next state logic for read and write address pointers
    always @* begin
        // successive pointer values
        next_write_addr = current_write_addr + 1;
        next_read_addr  = current_read_addr + 1;
        
        // default: keep old values
        current_write_addr_buff = current_write_addr;
        current_read_addr_buff  = current_read_addr;
        full_buff  = fifo_full;
        empty_buff = fifo_empty;
        
        // Button press logic
        case({write_to_fifo, read_from_fifo})     // check both buttons
            // 2'b00: neither buttons pressed, do nothing
            
            2'b01:  // read button pressed?
                if(~fifo_empty) begin   // FIFO not empty
                    current_read_addr_buff = next_read_addr;
                    full_buff = 1'b0;   // after read, FIFO not full anymore
                    if(next_read_addr == current_write_addr)
                        empty_buff = 1'b1;
                end
            
            2'b10:  // write button pressed?
                if(~fifo_full) begin    // FIFO not full
                    current_write_addr_buff = next_write_addr;
                    empty_buff = 1'b0;  // after write, FIFO not empty anymore
                    if(next_write_addr == current_read_addr)
                        full_buff = 1'b1;
                end
                
            2'b11:  begin   // write and read
                current_write_addr_buff = next_write_addr;
                current_read_addr_buff  = next_read_addr;
                end
        endcase         
    end

    // output
    assign full = fifo_full;
    assign empty = fifo_empty;

endmodule


module uart_top
    #(
        parameter   DBITS = 8,          // number of data bits in a word
                    SB_TICK = 16,       // number of stop bit / oversampling ticks
                    BR_LIMIT = 651,     // baud rate generator counter limit
                    BR_BITS = 10,       // number of baud rate generator counter bits
                    FIFO_EXP = 2        // exponent for number of FIFO addresses (2^2 = 4)
    )
    (
        input clk,                      // FPGA clock
        input reset_p,                  // reset
        input read_uart,                // button
        input write_uart,               // button
        input rx,                       // serial data in
        input [DBITS-1:0] write_data,   // data from Tx FIFO
        output rx_full,                 // do not write data to FIFO
        output rx_empty,                // no data to read from FIFO
        output tx,                      // serial data out
        output [DBITS-1:0] read_data    // data to Rx FIFO
    );
    
    // Connection Signals
    wire tick;                          // sample tick from baud rate generator
    wire rx_done_tick;                  // data word received
    wire tx_done_tick;                  // data transmission complete
    wire tx_empty;                      // Tx FIFO has no data to transmit
    wire tx_fifo_not_empty;             // Tx FIFO contains data to transmit
    wire [DBITS-1:0] tx_fifo_out;       // from Tx FIFO to UART transmitter
    wire [DBITS-1:0] rx_data_out;       // from UART receiver to Rx FIFO
    
    // Instantiate Modules for UART Core
    baud_rate_generator 
        #(
            .M(BR_LIMIT), 
            .N(BR_BITS)
         ) 
        BAUD_RATE_GEN   
        (
            .clk(clk), 
            .reset_p(reset_p),
            .tick(tick)
         );
    
    uart_receiver
        #(
            .DBITS(DBITS),
            .SB_TICK(SB_TICK)
         )
         UART_RX_UNIT
         (
            .clk(clk),
            .reset_p(reset_p),
            .rx(rx),
            .sample_tick(tick),
            .data_ready(rx_done_tick),
            .data_out(rx_data_out)
         );
    
    uart_transmitter
        #(
            .DBITS(DBITS),
            .SB_TICK(SB_TICK)
         )
         UART_TX_UNIT
         (
            .clk(clk),
            .reset_p(reset_p),
            .tx_start(tx_fifo_not_empty),
            .sample_tick(tick),
            .data_in(tx_fifo_out),
            .tx_done(tx_done_tick),
            .tx(tx)
         );
    
    fifo
        #(
            .DATA_SIZE(DBITS),
            .ADDR_SPACE_EXP(FIFO_EXP)
         )
         FIFO_RX_UNIT
         (
            .clk(clk),
            .reset_p(reset_p),
            .write_to_fifo(rx_done_tick),
            .read_from_fifo(read_uart),
            .write_data_in(rx_data_out),
            .read_data_out(read_data),
            .empty(rx_empty),
            .full(rx_full)            
          );
       
    fifo
        #(
            .DATA_SIZE(DBITS),
            .ADDR_SPACE_EXP(FIFO_EXP)
         )
         FIFO_TX_UNIT
         (
            .clk(clk),
            .reset_p(reset_p),
            .write_to_fifo(write_uart),
            .read_from_fifo(tx_done_tick),
            .write_data_in(write_data),
            .read_data_out(tx_fifo_out),
            .empty(tx_empty),
            .full()                // intentionally disconnected
          );
    
    // Signal Logic
    assign tx_fifo_not_empty = ~tx_empty;
  
endmodule

module uart_test(
    input clk,       // Basys 3 FPGA clock signal
    input reset_p,   // Reset button (btnR)
    input rx,        // USB-RS232 Rx
    input btn,       // Button to toggle LED (btnL)
    output tx,       // USB-RS232 Tx
    output [3:0] com, // 7-segment display common anodes
    output [7:0] seg_7, // 7-segment display segments
    output reg [15:0] led_debug // LED debug output
    );

    // Connection Signals
    wire btn_tick, rx_full, rx_empty;
    wire [7:0] rec_data;
    reg [7:0] tx_data; // Data to be transmitted
    reg led_state;    // LED state (on or off)
    reg read_uart;    // Signal to trigger UART read

    // Button Debouncer
    button_cntr btn0(.clk(clk), .reset_p(reset_p), .btn(btn), .btn_pedge(btn_tick));

    // Complete UART Core
    uart_top UART_UNIT
        (
            .clk(clk),
            .reset_p(reset_p),
            .read_uart(read_uart), // Read UART data when triggered
            .write_uart(btn_tick), // Write UART data when button is ticked
            .rx(rx),
            .write_data(tx_data), // Data to be transmitted
            .rx_full(rx_full),
            .rx_empty(rx_empty),
            .read_data(rec_data),
            .tx(tx)
        );

    // LED and FND Logic
    always @(posedge clk or posedge reset_p) begin
        if (reset_p) begin
            led_state <= 1'b0; // Reset LED state to OFF
            tx_data <= 8'h30; // Reset tx_data to '0'
            led_debug <= 16'h0000; // Reset LEDs
            read_uart <= 1'b0; // Reset UART read trigger
        end else begin
            if (btn_tick) begin
                // Toggle LED state when button is pressed
                led_state <= ~led_state;
                led_debug <= (led_state) ? 16'hFFFF : 16'h0000; // Toggle LEDs
                tx_data <= (led_state) ? 8'h30 : 8'h31; // Send '1' or '0' based on LED state
            end

            if (!rx_empty) begin
                // Check if data is available in the receive buffer
                case (rec_data)
                    8'h30: begin // ASCII '0'
                        led_debug <= 16'h0000; // Turn off all LEDs
                        tx_data <= 8'h30; // Send '0' to indicate LED state is OFF
                    end
                    8'h31: begin // ASCII '1'
                        led_debug <= 16'hFFFF; // Turn on all LEDs
                        tx_data <= 8'h31; // Send '1' to indicate LED state is ON
                    end
                    default: begin
                        led_debug <= led_debug; // No change for other characters
                    end
                endcase
                read_uart <= 1'b1; // Trigger UART read
            end else begin
                read_uart <= 1'b0; // Reset UART read trigger when no data
            end
        end
    end

    // FND Display Logic
    // Display the status of the LEDs on the 7-segment display
    fnd_cntr fnd_cntr_inst(
        .clk(clk),
        .reset_p(reset_p),
        .value({8'b0, led_debug[7:0]}), // Display the lower 8 bits of led_debug
        .com(com),
        .seg_7(seg_7)
    );

endmodule
