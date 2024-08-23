`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/07/17 10:12:05
// Design Name: 
// Module Name: controler
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

module fnd_cntr(
    input clk, reset_p,
    input [15:0] value,
    output [3:0] com,
    output [7:0] seg_7);
    
    ring_counter_fnd rc (clk, reset_p, com);
    
    reg [3:0] hex_value;
    always @(posedge clk)begin
        case(com)
            4'b1110 : hex_value = value[3:0];
            4'b1101 : hex_value = value[7:4];
            4'b1011 : hex_value = value[11:8];
            4'b0111 : hex_value = value[15:12];
        endcase
    end
    
    decoder_7seg(.hex_value(hex_value), .seg_7(seg_7));
    
endmodule  






module button_cntr (
    input clk, reset_p,
    input btn,
    output btn_pedge, btn_nedge);
 
    reg [20:0] clk_div = 0; //�������Ϳ� 0�ִ°� �ùķ��̼ǿ����� ����, ȸ�ο����� �������Ϳ� 0�� �ټ����⶧�� �������� 0�ټ�����
    always @(posedge clk)clk_div = clk_div + 1;
    
    wire clk_div_nedge; //���̾ 0�ִ°� ������Ű�°�, �ű⿡ 1���� ��Ʈ
    edge_detector_p ed_clk(.clk(clk), .reset_p(reset_p), .cp(clk_div[16]), .n_edge(clk_div_nedge));
    
    reg debounced_btn;
    always @(posedge clk or posedge reset_p) begin
            if(reset_p) debounced_btn = 0;
            else if(clk_div_nedge) debounced_btn = btn;
    end
    
    edge_detector_p ed_btn(.clk(clk), .reset_p(reset_p), .cp(debounced_btn), .n_edge(btn_nedge), .p_edge(btn_pedge));
 
 endmodule
 
 
 
 
 // key_vaild �� Ű �е尡 ���ȴ��� ���θ� Ȯ���ϴ� ����
 // key_vaild = 1�̸� ��ư �Է��� ���� ���̴�.
 // key_vaild = 0�̸� ��ư �Է��� ������ ���� ���� �ǹ��Ѵ�.
 module key_pad_cntr (
    input clk, reset_p,
    input [3:0] row,
    output reg [3:0] col,
    output reg [3:0] key_value,
    output reg key_vaild );
    
    // chattering ������ �����ϱ� ���� 8ms delay_time�� ���� button ���� �ްڴ�.
    reg [19:0] clk_div;
    always @(posedge clk or posedge reset_p) begin
        if(reset_p) clk_div = 0;
        else  clk_div = clk_div + 1;
    end
    
    // Get One Cycle Pulse of Button.
    // clk_8msec_p : Positive edge (��ư�� ������ ���� ����)
    // clk_8msec_n : Negative edge (��ư�� ������ ���� ����)
    wire clk_8msec_p, clk_8msec_n;
    edge_detector_p ed_0(.clk(clk), .reset_p(reset_p), .cp(clk_div[19]), .n_edge(clk_8msec_n), .p_edge(clk_8msec_p));
    
    // ������, row�� col ���� �ٲ� �����Ͻ�.
    
    // col ���� 8ms pulse�� positive edge���� shifting ��Ų��.
    // ��, key_vaild�� Ȱ��ȭ �Ǿ� �ִ� ���ȿ��� col ���� shifting ��Ű�� �ʴ´�.
    // ��ư�� ������ �ִ� ���ȿ��� �ش� ��ư�� col���� ��ȭ��Ű�� �ʴ´�.
    // ��ư �Է��� ������ ���� row�� �̵��Ѵ�.
    
    // ��, row ���� 0�� �ƴϸ� �ش� col���� ��� ��ư �� �������� �ǹ��ϰ�,
    // �ش� col���� �հ����� ��ư���� ���� ���� com ������ shifting���� �ʰ�, ����Ѵ�.
    // �հ����� ��ư���κ��� ���� com ������ Shifting�ϱ� �����Ѵ�.
    always @(posedge clk or posedge reset_p)begin
        if(reset_p) col=4'b0001;
        else if(clk_8msec_p && !key_vaild) begin
            case(col)
                4'b0001: col = 4'b0010;
                4'b0010: col = 4'b0100;
                4'b0100: col = 4'b1000;
                4'b1000: col = 4'b0001;
                default: col = 4'b0001;
            endcase
        end
    end
    
    // col, row  <-> row, col  �� �ٲ����
    // ���� ��������.
    always @(posedge clk or posedge reset_p) begin
        if(reset_p) begin
                key_value = 4'b0000;
                key_vaild = 0;
        end
        else begin
        // ���� ���ǹ��� clk_8msec_p��� 
        // button�� ������ �ٷ� �Ʒ� ���ǹ��� ����Ǵ� ���� �ƴ϶�
        // ���� clk_8msec_p���� ���� �ȴ�. (�ֳ��ϸ� PDT ������)
        
        // ���� ���� clk_8msec_p���� key_value ���� ���� �ʰ� �ϱ� ���ؼ� 
        // if�� �ȿ� clk_8msec_p -> clk_8msec_n ���� �����Ѵ�.
        // clk_8msec_p ��, ��ư�� ������ clk_8msec_n���� key_value ���� �а� �ȴ�.
            if(clk_8msec_n) begin // 8msec pulse�� positive edge�϶� ���� col ���� shift
                if(row)  begin 
                     key_vaild = 1;  
                     case({col, row})
                        8'b0001_0001 : key_value = 4'h0;
                        8'b0001_0010 : key_value = 4'h1;
                        8'b0001_0100 : key_value = 4'h2;
                        8'b0001_1000 : key_value = 4'h3;
                        
                        8'b0010_0001 : key_value = 4'h4;
                        8'b0010_0010 : key_value = 4'h5;
                        8'b0010_0100 : key_value = 4'h6;
                        8'b0010_1000 : key_value = 4'h7;
                        
                        8'b0100_0001 : key_value = 4'h8;
                        8'b0100_0010 : key_value = 4'h9;
                        8'b0100_0100 : key_value = 4'ha;
                        8'b0100_1000 : key_value = 4'hb;
                        
                        8'b1000_0001 : key_value = 4'hc;
                        8'b1000_0010 : key_value = 4'hd;
                        8'b1000_0100 : key_value = 4'he;
                        8'b1000_1000 : key_value = 4'hf;
                        
                        default : key_value = key_value;
                     endcase
                end
                else begin
                     key_vaild = 0;
                     key_value = 0;
                end
            end
        end
    end
    
 endmodule
 
 
 
 
 
 
 module key_pad_FSM (
    input clk, reset_p,
    input [3:0] row,
    output reg [3:0] col,
    output reg [3:0] key_value,
    output reg key_valid );
    
    parameter SCAN0 =            5'b00001;
    parameter SCAN1 =            5'b00010;
    parameter SCAN2 =            5'b00100;
    parameter SCAN3 =            5'b01000;
    parameter KEY_PROCESS =   5'b10000;
 
     // chattering ������ �����ϱ� ���� 8ms delay_time�� ���� button ���� �ްڴ�.
    reg [19:0] clk_div;
    always @(posedge clk or posedge reset_p) begin
        if(reset_p) clk_div = 0;
        else  clk_div = clk_div + 1;
    end
    
    // Get One Cycle Pulse of Button.
    // clk_8msec : Positive edge (��ư�� ������ ���� ����)
    wire clk_8msec_p, clk_8msec_n;
    edge_detector_p ed_0(.clk(clk), .reset_p(reset_p), .cp(clk_div[19]), .n_edge(clk_8msec_n), .p_edge(clk_8msec_p));
 
 
    // 8ms ���� state ���� nex_state �Է¹޴´�.
    reg [4:0] state, next_state;
    
    // D- Flip Flop 
    always @(posedge clk or posedge reset_p) begin
        if(reset_p) state = SCAN0;
        else if(clk_8msec_n) state = next_state;
    end
    
    // state ���� ���� ��ȭ�ϱ� ������ ���� ȸ���̴�.
    // row == 0 �̸� ���� ������ �̵��ϰ�, 
    // row == 1 �̸� ���� �࿡�� �����Ѵ�. 
    // row == 0 Ű �Է��� ������ �ǹ�
    // row == 1 �̸� Ű �Է��� ������ �ǹ� 
    always @(*) begin
        case (state)
            SCAN0:  begin
                if(row == 0) next_state = SCAN1;
                else next_state = KEY_PROCESS;
            end 
            
            SCAN1:  begin
                if(row == 0) next_state = SCAN2;
                else next_state = KEY_PROCESS;
            end 
            
            SCAN2:  begin
                if(row == 0) next_state = SCAN3;
                else next_state = KEY_PROCESS;
            end 
            
            SCAN3:  begin
                if(row == 0) next_state = SCAN0;
                else next_state = KEY_PROCESS;
            end 
            
            KEY_PROCESS:  begin
                if(row == 0) next_state = SCAN0;
                else next_state = KEY_PROCESS;
            end 
            
            default : next_state = SCAN0;
        endcase
    end
    
    // 
//    always @(posedge clk or posedge reset_p) begin
//        if(reset_p) begin
//            key_value = 0;
//            key_valid = 0;
//            col = 0;
//        end
//        else if(clk_8msec) begin
//             if(row)  begin 
//                     key_valid = 1;  
//                     case({col, row})
//                        8'b0001_0001 : key_value = 4'h0;
//                        8'b0001_0010 : key_value = 4'h1;
//                        8'b0001_0100 : key_value = 4'h2;
//                        8'b0001_1000 : key_value = 4'h3;
                        
//                        8'b0010_0001 : key_value = 4'h4;
//                        8'b0010_0010 : key_value = 4'h5;
//                        8'b0010_0100 : key_value = 4'h6;
//                        8'b0010_1000 : key_value = 4'h7;
                        
//                        8'b0100_0001 : key_value = 4'h8;
//                        8'b0100_0010 : key_value = 4'h9;
//                        8'b0100_0100 : key_value = 4'ha;
//                        8'b0100_1000 : key_value = 4'hb;
                        
//                        8'b1000_0001 : key_value = 4'hc;
//                        8'b1000_0010 : key_value = 4'hd;
//                        8'b1000_0100 : key_value = 4'he;
//                        8'b1000_1000 : key_value = 4'hf;
                        
//                        default : key_value = key_value;
//                     endcase
//                end
//                else key_valid = 0;       
//        end
//        case(state)
//                4'b0001 : col = 4'b0001;
//                4'b0010 : col = 4'b0010;
//                4'b0100 : col = 4'b0100;
//                4'b1000 : col = 4'b1000;     
//        endcase
//    end

 always @(negedge clk or posedge reset_p) begin
        if(reset_p) begin
            key_value = 0;
            key_valid = 0;
            col = 0;
        end
        else if(clk_8msec_p) begin
             case(state) 
                    SCAN0 : begin col = 4'b0001; key_valid = 0; end
                    SCAN1 : begin col = 4'b0010; key_valid = 0; end
                    SCAN2 : begin col = 4'b0100; key_valid = 0; end
                    SCAN3 : begin col = 4'b1000; key_valid = 0; end
                    KEY_PROCESS : begin
                            key_valid = 1;  
                            case({col, row})
                                     8'b0001_0001 : key_value = 4'h7;   
                                     8'b0001_0010 : key_value = 4'h8;
                                     8'b0001_0100 : key_value = 4'h9;
                                     8'b0001_1000 : key_value = 4'ha;
                        
                                      8'b0010_0001 : key_value = 4'h4;
                                      8'b0010_0010 : key_value = 4'h5;
                                      8'b0010_0100 : key_value = 4'h6;
                                      8'b0010_1000 : key_value = 4'hb;
                        
                                      8'b0100_0001 : key_value = 4'h1;
                                      8'b0100_0010 : key_value = 4'h2;
                                      8'b0100_0100 : key_value = 4'h3;
                                      8'b0100_1000 : key_value = 4'he;
                        
                                      8'b1000_0001 : key_value = 4'hc;
                                      8'b1000_0010 : key_value = 4'h0;
                                      8'b1000_0100 : key_value = 4'hf;
                                      8'b1000_1000 : key_value = 4'hd;
                        
                                    default : key_value = key_value;
                     endcase
                    end
             endcase
        end
    end
    
 endmodule
 
 
 // �½��� ����(dht11)
module dht11_cntrl(
        input clk, reset_p,
        inout dht11_data,
        output [15:0] led_debug,
        output reg [7:0] humidity, temperature);
        
        parameter S_IDLE = 6'b00_0001; 
        parameter S_LOW_18MS = 6'b00_0010;
        parameter S_HIGH_20US = 6'b00_0100;
        parameter S_LOW_80US = 6'b00_1000;
        parameter S_HIGH_80US = 6'b01_0000;
        parameter S_READ_DATA = 6'b10_0000;
        
        parameter S_WAIT_PEDGE = 2'b01;
        parameter S_WAIT_NEDGE = 2'b10;
        
        reg [5:0] state, next_state;
        reg [1:0] read_state;
        
        assign led_debug[5:0] = state;
        
        wire clk_usec;
        clock_div_100   usec_clk( .clk(clk), .reset_p(reset_p), .clk_div_100_nedge(clk_usec));     // 1us
        
        // ����ũ�μ����� ������ ī��Ʈ 
        // enable �� 1�̸� ī��Ʈ ���� , 1�� �ƴϸ� 0���� ī��Ʈ �ʱ�ȭ 
        reg [21:0] count_usec;
        reg count_usec_en;
        always @(negedge clk or posedge reset_p)begin
                if(reset_p) count_usec = 0;
                else if(clk_usec && count_usec_en) count_usec = count_usec + 1;
                else if(!count_usec_en) count_usec = 0;
        end
        
        always @(negedge clk or posedge reset_p)begin
                if(reset_p) state = S_IDLE;
                else state = next_state;
        end
        
        // data�� in-out ���� �����Ƿ� reg ������ �� �� ���� 
        reg dht11_buffer;
        assign dht11_data = dht11_buffer;
        
        // ���� ������ 
        wire dht_nedge, dht_pedge;
        edge_detector_p ed(.clk(clk), .reset_p(reset_p), .cp(dht11_data), .n_edge(dht_nedge), .p_edge(dht_pedge));
        
        reg [39:0] temp_data;
        reg [5:0] data_count;
        
        // ���� õ�̵��� ���� case��  
        always @(posedge clk or posedge reset_p)begin
                if(reset_p)begin
                        next_state = S_IDLE;
                        read_state = S_WAIT_PEDGE;
                        temp_data = 0;
                        data_count = 0;
                        count_usec_en = 0;
                end
                else begin
                        case(state)
                            S_IDLE : begin
                                    if(count_usec < 22'd3_000_000)begin
                                            count_usec_en = 1;
                                            dht11_buffer = 'bz;     // ���Ǵ��� ����ϸ� Ǯ���� ���� 1�� �ȴ� 
                                    end
                                    else begin
                                            count_usec_en = 0;      // ī��Ʈ�� ���߰� �ʱ�ȭ ��Ŵ 
                                            next_state = S_LOW_18MS;    // ���� state�� õ��
                                    end         
                            end
                            S_LOW_18MS : begin
                                    if(count_usec < 22'd20_000)begin        // �ּҰ��� 18ms �̹Ƿ� �����ְ� 20ms ���� 
                                            dht11_buffer = 0;
                                            count_usec_en = 1;
                                    end       
                                    else begin
                                            count_usec_en = 0;
                                            next_state = S_HIGH_20US;
                                            dht11_buffer = 'bz;
                                    end         
                            end
                            S_HIGH_20US : begin
                                    // DHT11���� Response signal�� ������ ���� ��쿡 ���ؼ� ���� ó��
                                    count_usec_en = 1;
                                    if(count_usec > 22'd100_000) begin
                                        next_state = S_IDLE;
                                        count_usec_en = 0;
                                    end
                                    // DHT 11���� Response Signal�� ������ ���.
                                    else if(dht_nedge) begin     
                                            count_usec_en = 0;
                                            next_state = S_LOW_80US;
                                    end        
                            end
                            S_LOW_80US : begin
                                     // DHT11���� Response signal�� ������ ���� ��쿡 ���ؼ� ���� ó��
                                    count_usec_en = 1;
                                    if(count_usec > 22'd100_000) begin
                                        next_state = S_IDLE;
                                        count_usec_en = 0;
                                    end
                                    // DHT 11���� Response Signal�� ������ ���.
                                    else if(dht_pedge)begin              // �����ͽ�Ʈ�� ����Ȯ�������� ��Ȯ�� �ð��� �ƴ� ������ ��ٸ� 
                                            count_usec_en = 0;
                                            next_state = S_HIGH_80US;
                                    end
                            end
                            S_HIGH_80US : begin
                                     // DHT11���� Response signal�� ������ ���� ��쿡 ���ؼ� ���� ó��
                                    count_usec_en = 1;
                                    if(count_usec > 22'd100_000) begin
                                        next_state = S_IDLE;
                                        count_usec_en = 0;
                                    end
                                    // DHT 11���� Response Signal�� ������ ���.
                                    else if(dht_nedge)begin
                                            count_usec_en = 0;
                                            next_state = S_READ_DATA;
                                    end
                            end
                            S_READ_DATA : begin
                                     // DHT11���� Response signal�� ������ ���� ��쿡 ���ؼ� ���� ó��
                                    count_usec_en = 1;
                                    if(count_usec > 22'd100_000) begin
                                        next_state = S_IDLE;
                                        count_usec_en = 0;
                                        read_state = S_WAIT_PEDGE;
                                    end
                                    else begin
                                         case(read_state)
                                            S_WAIT_PEDGE : begin
                                                    if(dht_pedge) read_state = S_WAIT_NEDGE;
                                            end
                                            S_WAIT_NEDGE :  begin
                                                    if(dht_nedge)begin
                                                            if(count_usec < 95)begin
                                                                    temp_data = {temp_data[38:0] , 1'b0};       // shift ��������(�� ����Ʈ)
                                                            end
                                                            else begin
                                                                    temp_data = {temp_data[38:0] , 1'b1};
                                                            end
                                                            data_count = data_count + 1;
                                                            read_state = S_WAIT_PEDGE; 
                                                            count_usec_en = 0;
                                                    end
                                                    else begin
                                                            count_usec_en = 1;
                                                    end
                                                   
                                            end
                                        endcase 
                                    end
                                    
                                    if(data_count >= 40)begin
                                            data_count = 0;
                                            next_state = S_IDLE;
                                            count_usec_en = 0;
                                            read_state = S_WAIT_PEDGE;
                                            
                                            if(temp_data[39:32] + temp_data[31:24] + temp_data[23:16] + temp_data[15:8] == temp_data[7:0]) begin
                                                 humidity = temp_data[39:32];
                                                 temperature = temp_data[23:16];
                                            end
                                    end       
                            end
                        endcase
                end        
        end
        
endmodule

 
// // data ���� �� �ϳ��ε�, MCU�� DHT���� Data�� �ְ� �޾ƾ� �ϱ� ������ 
// // inout Ű���� ������ ���� input ouput ���� ����Ѵ�.
// module dht11_cntr (
//    input clk, reset_p,
//    inout dht11_data,
//    output reg [7:0] humidity, temperature );
 
//    // Main state
//   parameter S_IDLE                   = 6'b00_0001;
//   parameter S_LOW_18MS          = 6'b00_0010;
//   parameter S_HIGH_20US         = 6'b00_0100;
//   parameter S_LOW_80US          = 6'b00_1000;
//   parameter S_HIGH_80US         = 6'b01_0000;
//   parameter S_READ_DATA        = 6'b10_0000;
    
//   // Sub state of read data �ܰ�
//   parameter S_WAIT_PEDGE       = 2'b01;
//   parameter S_WAIT_NEDGE       = 2'b10;
   
//   // state machine ���� 
//   reg [5:0] state, next_state;
//   reg [1:0] read_state;
   
//   // Counter �������� One Cycle Pulse ����
//   wire clk_usec;
//   clock_div_100 usec_clk(.clk(clk), .reset_p(reset_start), .clk_div_100_nedge(clk_usec));
   
//   // 3�� ��⸦ ���� counter
//   reg [21:0] count_usec;
//   reg count_usec_e;
   
//   always @(negedge clk or posedge reset_p) begin
//        if(reset_p) count_usec_e = 0;
//        else if(clk_usec && count_usec_e) count_usec = count_usec + 1;
//        else if(!count_usec_e) count_usec_e = 0;
//   end
    
//    //  state�� next_state �����ϴ� ����
//    // state �� ó���ϴ� ����
//    always @(negedge clk or posedge reset_p) begin
//        if(reset_p) state = S_IDLE;
//        else state = next_state;
//    end
    
//    // Combinational logic circuit
//    // negative edge : state ���� ����
//    // positive edge : next_state ���� ����
    
    
//    reg dht11_buffer;
//    assign dht11_data = dht11_buffer;
    
//    // Get Edge of DHT data.
//    wire dht_pedge, dht_nedge;
//    edge_detector_p ed_0(.clk(clk), .reset_p(reset_p), .cp(dht11_data), .n_edge(dht_nedge), .p_edge(dht_pedge));
    
    
//    // dht11�κ��� �����͸� �޾Ƽ� �����ϴ� ��������
//    reg [39:0] temp_data;
    
//    // ���ݱ��� ��� data�� ���Դ��� Ȯ��
//    reg [5:0] data_count;
    
//    // state machine ����
//    always @(posedge clk or posedge reset_p) begin
//        if(reset_p) begin
//            next_state = S_IDLE;
//            read_state = S_WAIT_PEDGE;
//            temp_data = 0;
//            data_count = 0;
//        end 
//        else begin
//                case(state)
//                        // 1�ܰ� : S_IDLE
//                        S_IDLE : begin
//                           // Counter�� ���� 3�ʵ��� ���
//                           //  dht11�� ����� ���Ǵ����� ����� 
//                           // ���Ǵ����� ���
//                           if(count_usec < 22'd10_000) begin // 22'd3_000_000
//                                count_usec_e = 1;
//                                dht11_buffer = 'bz;
//                           end
//                           else begin
//                                count_usec_e = 0;
//                                next_state = S_LOW_18MS;                              
//                           end                     
//                        end
                        
//                        // 2�ܰ� : S_LOW_18MS
//                        S_LOW_18MS : begin
//                            // Counter�� ���� 18m�ʵ��� ���
//                           //  dht11�� ����� 0����  ����� 
//                           // 0�� ���
//                           // �׷���, ���� �ְ� 20ms �ʵ��� ���
//                             if(count_usec <22'd20_000) begin
//                                count_usec_e = 1;
//                                dht11_buffer = 0;
//                             end
//                             else begin
//                                count_usec_e = 0;
//                                next_state = S_HIGH_20US;       
//                             end
//                        end
                        
//                        // 3�ܰ� : S_HIGH_20US
//                        S_HIGH_20US : begin
//                            // Counter�� ���� 20us�ʵ��� ���
//                           //  dht11�� ����� 0����  ����� 
//                           // 0�� ���
//                             if(count_usec <22'd20) begin
//                                count_usec_e = 1;
//                                dht11_buffer = 'bz;  
//                             end
//                             else if(dht_nedge) begin
//                                    count_usec_e = 0;
//                                    next_state = S_LOW_80US;
//                             end
//                        end
                        
//                        // 4�ܰ� : S_LOW_80US
//                        // dht ��ȣ�� positiv edge�� �߻��� ������ ��ٸ���.
//                        S_LOW_80US : begin
//                             if(dht_pedge) begin
//                                    next_state = S_HIGH_80US;
//                             end
//                        end             
                        
//                         // 5�ܰ� : S_HIGH_80US
//                         // dht ��ȣ�� negative edge�� �߻��� ������ ��ٸ���.
//                        S_HIGH_80US : begin
//                            if(dht_nedge) begin
//                                    next_state = S_READ_DATA;
//                             end
//                        end
                        
                        
//                         // 6�ܰ� : S_READ_DATA
//                         // dht ��ȣ�� negative edge�� �߻��� ������ ��ٸ���.
//                        S_READ_DATA : begin
//                           case (read_state) 
//                                    S_WAIT_PEDGE : begin
//                                        if(dht_pedge) read_state = S_WAIT_NEDGE;
//                                        count_usec_e = 0;
//                                    end
                                    
//                                    S_WAIT_NEDGE : begin
//                                        if(dht_nedge) begin
//                                            if(count_usec < 45)  temp_data = {temp_data[38:0],1'b 0};        
//                                            else   temp_data = {temp_data[38:0], 1'b1};
                                            
//                                            data_count = data_count + 1;
//                                            read_state = S_WAIT_PEDGE;
//                                        end 
//                                        else count_usec_e = 1;
//                                    end        
//                           endcase
                           
//                           // DHT�κ��� �����͸� �ٹ��� ��, ����, �µ� �ޱ�.
//                           if(data_count >= 40) begin
//                                data_count = 0;
//                                next_state = S_IDLE;
//                                humidity = temp_data[39 : 32];    
//                                temperature = temp_data[23 : 16];    
//                           end
//                        end
//                endcase
//        end
//    end
    
//endmodule


// 
module HC_SR04_cntr (
    input clk, reset_p, 
    input hc_sr04_echo,
    output reg hc_sr04_trig,
    output reg [21:0] distance,
    output [7:0] led_debug);
    
    // For Test
    assign led_debug[3:0] = state;
    
    // Define state 
    parameter S_IDLE                      = 4'b0001;
    parameter S_10US_TTL               = 4'b0010;
    parameter S_WAIT_PEDGE           = 4'b0100;
    parameter S_CALC_DIST             = 4'b1000;
    
    // Define state, next_state value.
    reg [3:0] state, next_state;
    
    // ���� next_state�� state ������ �ִ°�?
    always @(posedge clk or posedge reset_p) begin
        if(reset_p) state = S_IDLE;
        else state = next_state;
    end
    
    // get 10us negative one cycle pulse
    wire clk_usec;
    clock_div_100   usec_clk( .clk(clk), .reset_p(reset_p), .clk_div_100_nedge(clk_usec));     // 1us
    
    // making usec counter.
    reg [21:0] counter_usec;
    reg counter_usec_en;
    
    always @(posedge clk or posedge reset_p) begin
        if(reset_p) begin counter_usec = 0;
        end else if(clk_usec && counter_usec_en) counter_usec = counter_usec + 1;
        else if(!counter_usec_en) counter_usec = 0;
    end
    
    
    
    
    // hc_sr04_data�� Negative edge, Positive edge ���.
    wire hc_sr04_echo_n_edge, hc_sr04_echo_p_edge;
    edge_detector_p edge_detector_0 (.clk(clk), .reset_p(reset_p), .cp(hc_sr04_echo), .n_edge(hc_sr04_echo_n_edge), .p_edge(hc_sr04_echo_p_edge));
    
    reg cnt_e;
    wire [11:0] cm;
    sr04_div_58 clk_div_58(.clk(clk), .reset_p(reset_p), .clk_usec(clk_usec), .cnt_e(cnt_e), .cm(cm)); 
    
    // Echo Pulse Ȱ��ȭ�ð� �ӽ� �����ϴ� ��������
    reg [21:0] echo_time;
    
    // ���� õ�̵��� ���� case�� ����
    // �� ���¿� ���� ���� ����
    always @(negedge clk or posedge reset_p) begin
        if(reset_p) begin
            next_state = S_IDLE;
            counter_usec_en = 0; 
            cnt_e = 0; 
        end else begin
            case(state)
                S_IDLE : begin        
                    if(counter_usec < 22'd3_000_000) begin
                        counter_usec_en = 1;  
                        hc_sr04_trig = 0;
                    end
                    else begin
                        counter_usec_en = 0;
                        next_state = S_10US_TTL;
                    end
                end
                
                
                
                S_10US_TTL : begin
                    if(counter_usec < 22'd10) begin
                        counter_usec_en = 1;
                        hc_sr04_trig = 1;
                    end
                    else begin
                        hc_sr04_trig = 0;
                        counter_usec_en = 0;
                        next_state = S_WAIT_PEDGE;
                    end
                end
                
                
                
                S_WAIT_PEDGE :  
                    if(hc_sr04_echo_p_edge) begin
                         next_state = S_CALC_DIST;    
                         cnt_e = 1;
                    end     
                
                
                
                S_CALC_DIST : begin          
                     if(hc_sr04_echo_n_edge) begin
                                distance = cm;
                                cnt_e = 0;
                                next_state = S_IDLE;
                      end
                      else next_state = S_CALC_DIST;
                end
            endcase
        end
    end
    
    
//    // ������ ������ ������� �ʱ� ���� echo_time (echo pulse�� Ȱ��ȭ �Ǵ� �ð�)�� ���� ����
//    // behavioral modeling�ϸ� ������ ���� ȸ�� ��ſ� MUX�� ������
//   always @(posedge clk or posedge reset_p) begin
//    if(reset_p) begin
//        distance = 0;
//    end
//    else begin
//        if(echo_time < 58) distance = 1;
//        else if(echo_time < 116) distance = 2;
//        else if(echo_time < 174) distance = 3;
//        else if(echo_time < 232) distance = 4;
//        else if(echo_time < 290) distance = 5;
//        else if(echo_time < 348) distance = 6;
//        else if(echo_time < 406) distance = 7;
//        else if(echo_time < 464) distance = 8;
//        else if(echo_time < 522) distance = 9;
//        else if(echo_time < 580) distance = 10;
//        else if(echo_time < 638) distance = 11;
//        else if(echo_time < 696) distance = 12;
//        else if(echo_time < 754) distance = 13;
//        else if(echo_time < 812) distance = 14;
//        else if(echo_time < 870) distance = 15;
//        else if(echo_time < 928) distance = 16;
//        else distance = 17; // 928 �̻��� ��쵵 16���� ����
//    end
//end

    
endmodule




module HC_SR04_cntr_test (
    input clk, reset_p, 
    input hc_sr04_echo,
    output reg hc_sr04_trig,
    output reg [22:0] distance,
    output [7:0] led_debug
);
    
    // For Test
    assign led_debug = {4'b0, state};
    
    // Define state 
    localparam S_IDLE       = 4'b0001;
    localparam S_10US_TTL   = 4'b0010;
    localparam S_WAIT_PEDGE = 4'b0100;
    localparam S_CALC_DIST  = 4'b1000;
    
    // Define state register
    reg [3:0] state;
    
    // get 10us negative one cycle pulse
    wire clk_usec;
    clock_div_100 usec_clk(.clk(clk), .reset_p(reset_p), .clk_div_100_nedge(clk_usec));     // 1us
    
    // making usec counter.
    reg [22:0] counter_usec;
    
    // hc_sr04_data�� Negative edge, Positive edge ���.
    wire hc_sr04_echo_n_edge, hc_sr04_echo_p_edge;
    edge_detector_p edge_detector_0 (.clk(clk), .reset_p(reset_p), .cp(hc_sr04_echo), .n_edge(hc_sr04_echo_n_edge), .p_edge(hc_sr04_echo_p_edge));
    
    // ���� �ӽ� �� ���� ����
    always @(posedge clk or posedge reset_p) begin
        if(reset_p) begin
            state <= S_IDLE;
            counter_usec <= 0;
            hc_sr04_trig <= 0;
            distance <= 0;
        end else begin
            case(state)
                S_IDLE: begin           
                    hc_sr04_trig <= 0;
                    if(clk_usec) begin
                        if(counter_usec < 23'd3_000_000)
                            counter_usec <= counter_usec + 1;
                        else begin
                            counter_usec <= 0;
                            state <= S_10US_TTL;
                        end
                    end
                end
                
                S_10US_TTL: begin
                    if(clk_usec) begin
                        if(counter_usec < 23'd10) begin
                            hc_sr04_trig <= 1;
                            counter_usec <= counter_usec + 1;
                        end else begin
                            hc_sr04_trig <= 0;
                            counter_usec <= 0;
                            state <= S_WAIT_PEDGE;
                        end
                    end
                end
                
                S_WAIT_PEDGE: begin      
                    if(hc_sr04_echo_p_edge) begin
                        state <= S_CALC_DIST;
                        counter_usec <= 0;
                    end
                end
                
                S_CALC_DIST: begin
                    if(clk_usec)
                        counter_usec <= counter_usec + 1;
                    
                    if(hc_sr04_echo_n_edge) begin
                        distance <= counter_usec / 58;
                        state <= S_IDLE;
                    end
                end
            endcase
        end
    end
    
endmodule




module pwm_100step (
    input clk, reset_p,
    input [6:0] duty,
    output pwm);
    
    //  Prescaler 100
    parameter sys_clk = 100_000_000;  // System Clock Pulse ���ļ�
    parameter pwm_freq = 10_000;     //  LED�� ���������� �������� ���� ���ļ�
    parameter duty_step = 100;          // Duty ratio�� �ܰ�
    
    parameter temp = sys_clk / duty_step / pwm_freq;   
    parameter temp_half = temp / 2;
    
    integer cnt_sysclk;
    
     always @(negedge clk or posedge reset_p)begin
        if(reset_p)cnt_sysclk = 0;
        else begin
                if(cnt_sysclk >= temp - 1) cnt_sysclk = 0;
                else cnt_sysclk = cnt_sysclk + 1;
        end
    end
    
    
    wire pwm_freqX100;
    assign pwm_freqX100 = (cnt_sysclk < temp_half) ? 0 : 1;
    
    wire pwm_freqX100_nedge;
    edge_detector_n edge_detector_0 (.clk(clk), .reset_p(reset_p), .cp(pwm_freqX100), .n_edge(pwm_freqX100_nedge));
    
    
    // Prescaler 128
    reg [6:0] cnt_duty;   
    
    always @(negedge clk or posedge reset_p)begin
        if(reset_p)cnt_duty = 0;
        else if(pwm_freqX100_nedge)begin
               if(cnt_duty >=99) cnt_duty = 0;
               else cnt_duty = cnt_duty + 1; 
        end
    end
    
    assign pwm = (cnt_duty < duty) ? 1 : 0;
    
endmodule







module pwm_Nstep_freq 
#(
    parameter sys_clk = 100_000_000,  // System Clock Pulse ���ļ�
    parameter pwm_freq = 10_000,    //  LED�� ���������� �������� ���� ���ļ�
    parameter duty_step = 100,          // Duty ratio�� �ܰ�
    parameter temp = sys_clk / duty_step / pwm_freq,
    parameter temp_half = temp / 2)
(
    input clk, reset_p,
    input [31:0] duty,
    output pwm);
    
    integer cnt_sysclk;
    
     always @(negedge clk or posedge reset_p)begin
        if(reset_p)cnt_sysclk = 0;
        else begin
                if(cnt_sysclk >= temp - 1) cnt_sysclk = 0;
                else cnt_sysclk = cnt_sysclk + 1;
        end
    end
    
    
    wire pwm_freqXstep;
    assign pwm_freqXstep = (cnt_sysclk < temp_half) ? 0 : 1;
    
    wire pwm_freqXstep_nedge;
    edge_detector_n edge_detector_0 (.clk(clk), .reset_p(reset_p), .cp(pwm_freqXstep), .n_edge(pwm_freqXstep_nedge));
    
    
    integer cnt_duty;   
    
    always @(negedge clk or posedge reset_p)begin
        if(reset_p)cnt_duty = 0;
        else if(pwm_freqXstep_nedge)begin
               if(cnt_duty >=duty_step-1) cnt_duty = 0;
               else cnt_duty = cnt_duty + 1; 
        end
    end
    
    assign pwm = (cnt_duty < duty) ? 1 : 0;
    
endmodule





// i2c ���
module I2C_master (
    input clk, reset_p,
    input [6:0] addr, // Slave�� �ּҴ� 7bit�̴�.
    input rd_wr,       // �����͸� read�Ұ����� write�� ������
    input [7:0] data,  // Slave������ ���� �������� ũ��� 8bit
    input comm_go,  // comm_go ������ ��ü ����� ������ enable�����ִ� ����
    output reg scl, sda,
    output reg [15:0] led );
    
    // 7���� state�� ����
    // ��α� �Խñ� ����
    parameter IDLE = 7'b000_0001;
    parameter COMM_START = 7'b000_0010;
    parameter SEND_ADDR = 7'b000_0100;
    parameter RD_ACK = 7'b000_1000;
    parameter SEND_DATA = 7'b001_0000;
    parameter SCL_STOP = 7'b010_0000;
    parameter COMM_STOP = 7'b100_0000;
    
    
    //  Slave �ּ� + Master �ʿ��� Read�Ұ����� Write�Ұ������� ��� �ִ� 8bit wire
    wire [7:0] addr_rw;
    assign addr_rw = {addr, rd_wr};
    
    // I2C ��ſ��� ����ϴ� Clock signal�� �Ϲ������� 100kHz�� ��� == 10us period �� Clock Pulse ����
    // Master���� Clock Speed�� �����ش�.
    // I2C ����� Clock Speed�� ������ �ӵ� ���� Master�� ���� �����ȴ�.
    // �̹� ���������� Clock Speed�� 100kHz ���ļ��� ���´�.
    wire clk_usec;
    clock_div_100 usec_clk (.clk(clk), .reset_p(reset_p), .clk_div_100_nedge(clk_usec));
    
    
    // usec one cycle pulse�� ���� 5�� ī��Ʈ�ϰ�, Toggle�ϴ� �������� 
    // �ֱⰢ 10usec�� Clock Pulse�� �����.
    reg [2:0] counter_usec5; // 10us �ֱ��� Clock Pulse�� ����� ���� Register
    reg scl_e;  // scl ��ȣ���� enable
    
    // 10usec �ֱ��� Clock Pulse�� �����
    always @(posedge clk or posedge reset_p) begin
        if(reset_p)  begin
             counter_usec5 = 0;   
             scl = 1;   // IDLE ���¿����� High-level�̴�.
        end
        else if(scl_e) begin
                if(clk_usec) begin
                    if(counter_usec5 >= 4) begin
                        counter_usec5 = 0;
                        scl = ~scl;              // SCL ��ȣ���� ���� Toggle��Ų��.
                     end
                    else  counter_usec5 = counter_usec5 + 1;
                end 
        end
        else if(!scl_e) begin
                scl = 1;   // SCL ��ȣ���� Disable�̸� 1�� �ʱ�ȭ
                counter_usec5 = 0;   
        end
    end 
    
    
    // Get edge of 10usec�� Clock Pulse 
    // Clock Signal edge�� ���缭 �����͸� ������ ���̱� ������ edge�� �ʿ��ϴ�.
    wire scl_nedge, scl_pedge;
    edge_detector_n scl_edge (.clk(clk), .reset_p(reset_p), .cp(scl), .p_edge(scl_pedge), .n_edge(scl_nedge));
    
    //  Get positive edge of Comm-go
    wire comm_go_pedge;
    edge_detector_n comm_go_edge (.clk(clk), .reset_p(reset_p), .cp(comm_go), .p_edge(comm_go_pedge));
    
    // state�� next state ���� ����
    reg [6:0] state, next_state;
    
    // ���� ���� ���·� �Ѿ�°�?
    always @(negedge clk or posedge reset_p) begin
         if(reset_p) state = IDLE;
         else state = next_state;
    end
    
    
    // 8bit �����͸� ���������� ������ ���� register
    reg [2:0] cnt_bit;
    
    // 
    reg stop_flag;
    
    always @(posedge clk or posedge reset_p) begin
        if(reset_p) begin
            next_state = IDLE;
            scl_e = 0;
            sda = 1;
            cnt_bit = 7;
            stop_flag = 0;
        end
        else begin
            case(state)
                 // 1�ܰ� : IDLE
                 IDLE : begin
                        scl_e = 0;       // SCL Disable ����
                        sda = 1;        // SDA ��ȣ���� 1�� ����
                        
                        if(comm_go_pedge) next_state = COMM_START;
                 end
                 
                 // 2�ܰ� : COMM_START
                 COMM_START : begin
                       sda = 0;        // Start Start Signal 
                       scl_e = 1;       // SCL able ����
                       
                       next_state = SEND_ADDR;
                 end
                 
                 // 3�ܰ� : SEND_ADDR
                 SEND_ADDR : begin
                        if(scl_nedge) sda = addr_rw[cnt_bit];
                        if(scl_pedge) begin
                             if(cnt_bit == 0) begin
                                cnt_bit = 7;
                                next_state = RD_ACK;
                             end
                             else cnt_bit = cnt_bit - 1;
                        end
                 end
                 
                 // 4�ܰ� : RD_ACK
                 // SDA ��ȣ�� ���� �ʰڴ�.
                 // �ֳ��ϸ� Direct���� �����ϱ� ������
                 RD_ACK : begin
                        if(scl_nedge) sda = 'bz;   // SDA ��ȣ������ ���� �����͸� ���� �� �ֱ� ������ �����ش�.
                        else if(scl_pedge) begin
                            if(stop_flag) begin     // stop_flag == 0�̸� ������ ������ ���̱� ������ next state == SEND_DATA
                                                         // stop_flag == 1�̸� ������ ���� �����̱� ������ next state == SCL_STOP
                                stop_flag = 0;
                                next_state = SCL_STOP;
                            end
                            else begin
                                stop_flag = 1;
                                next_state = SEND_DATA;
                             end
                         end
                 end
                 
                 // 5�ܰ� : SEND_DATA
                 SEND_DATA : begin
                        if(scl_nedge) sda = data[cnt_bit];
                        if(scl_pedge) begin
                             if(cnt_bit == 0) begin
                                cnt_bit = 7;
                                next_state = RD_ACK;
                             end
                             else cnt_bit = cnt_bit - 1;
                        end
                 end
                 
                 // 6�ܰ� : SCL_STOP
                 SCL_STOP : begin
                        if(scl_nedge) sda = 0;         // SDA�� Positive edge�� �ֱ� ���� ������ 0���� 
                        else if(scl_pedge) next_state = COMM_STOP;
                 end
                 
                 // 7�ܰ� : COMM_STOP
                 // �ٷ� SDA�� ��ȣ ���� 1�� �ָ� ������ �� �ֱ� ������
                 // 3usec delay time�ڿ� SDA�� ��ȣ���� 0-> 1�� ��ȭ���� �ش�.
                 COMM_STOP : begin
                        if(counter_usec5 >= 3) begin
                            scl_e = 0;
                            sda = 1;
                            next_state = IDLE;
                        end
                 end
            endcase
        end
    end
    
 endmodule
 
 
 
 
 
module i2c_lcd_send_byte (
        input clk, reset_p,
        input [6:0] addr,
        input [7:0] send_buffer,
        input rs, send,               // 
        output scl, sda,
        output reg busy,
        output [15:0] led );        // Register�� LCD�� �����͸� ������ ���ȿ��� 
                                         // �ܺο��� ������ ������ ���� �������� ǥ���ϱ� ����
                                         // busy == 1 �̸� ������ �������� ����, busy == 0�̸� ������ ���� ���� �ƴ� ����


        // Decalare State Machine
        parameter IDLE                                          = 6'b00_0001;
        parameter SEND_HIGH_NIBBLE_DISABLE        = 6'b00_0010;
        parameter SEND_HIGH_NIBBLE_ENABLE         = 6'b00_0100;
        parameter SEND_LOW_NIBBLE_DISABLE         = 6'b00_1000;
        parameter SEND_LOW_NIBBLE_ENABLE          = 6'b01_0000;
        parameter SEND_DISABLE                            = 6'b10_0000;


        // Declare variables.
        reg [7:0] data;
        reg comm_go;
        
        //  Get positive edge of send
        wire send_pedge;
        edge_detector_n comm_go_edge (.clk(clk), .reset_p(reset_p), .cp(send), .p_edge(send_pedge));
        
        // Get usecond clock
        wire clk_usec;
        clock_div_100 usec_clk (.clk(clk), .reset_p(reset_p), .clk_div_100_nedge(clk_usec));
        
        // ����ũ�μ����� ������ ī��Ʈ 
        // enable �� 1�̸� ī��Ʈ ���� , 1�� �ƴϸ� 0���� ī��Ʈ �ʱ�ȭ 
        reg [21:0] count_usec;
        reg count_usec_en;
        always @(negedge clk or posedge reset_p)begin
                if(reset_p) count_usec = 0;
                else if(clk_usec && count_usec_en) count_usec = count_usec + 1;
                else if(!count_usec_en) count_usec = 0;
        end
        
        // Declare state, next state variable
        reg [5:0] state, next_state;
        
        // ���� ���� ���·� �Ѿ�°�?
        always @(negedge clk or posedge reset_p) begin
                if(reset_p) state = IDLE;
                else state = next_state;
        end
        
        always @(posedge clk or posedge reset_p) begin
                if(reset_p) begin
                        next_state = IDLE;
                        busy = 0;
                        comm_go = 0;
                        count_usec_en = 0;
                        data = 0; 
                end
                else begin
                        case(state)
                                // 1�ܰ�) IDLE
                                IDLE : begin
                                        if(send_pedge) begin 
                                                next_state = SEND_HIGH_NIBBLE_DISABLE;
                                                busy = 1;   
                                        end
                                end  
                                
                                // 2�ܰ�) SEND_HIGH_NIBBLE_DISABLE
                                SEND_HIGH_NIBBLE_DISABLE : begin
                                        if(count_usec <= 22'd200) begin
                                                // ������ ����
                                                data = {send_buffer[7:4], 3'b100, rs}; // data, BT, Enable, RW, RS
                                                comm_go = 1;
                                                count_usec_en = 1;
                                        end
                                        else begin
                                                count_usec_en = 0;
                                                comm_go = 0;
                                                next_state = SEND_HIGH_NIBBLE_ENABLE;
                                        end
                                end 
                                
                                // 3�ܰ�) SEND_HIGH_NIBBLE_ENABLE
                                SEND_HIGH_NIBBLE_ENABLE : begin
                                         if(count_usec <= 22'd200) begin
                                                // ������ ����
                                                data = {send_buffer[7:4], 3'b110, rs}; // data, BT, Enable, RW, RS
                                                comm_go = 1;
                                                count_usec_en = 1;
                                        end
                                        else begin
                                                count_usec_en = 0;
                                                comm_go = 0;
                                                next_state = SEND_LOW_NIBBLE_DISABLE;
                                        end
                                end 
                                
                                // 4�ܰ�) SEND_LOW_NIBBLE_DISABLE
                                SEND_LOW_NIBBLE_DISABLE : begin
                                        if(count_usec <= 22'd200) begin
                                                // ������ ����
                                                data = {send_buffer[3:0], 3'b100, rs}; // data, BT, Enable, RW, RS
                                                comm_go = 1;
                                                count_usec_en = 1;
                                        end
                                        else begin
                                                count_usec_en = 0;
                                                comm_go = 0;
                                                next_state = SEND_LOW_NIBBLE_ENABLE;
                                        end
                                end     
                                
                                // 5�ܰ�) SEND_LOW_NIBBLE_ENABLE
                                SEND_LOW_NIBBLE_ENABLE : begin
                                        if(count_usec <= 22'd200) begin
                                                // ������ ����
                                                data = {send_buffer[3:0], 3'b110, rs}; // data, BT, Enable, RW, RS
                                                comm_go = 1;
                                                count_usec_en = 1;
                                        end
                                        else begin
                                                count_usec_en = 0;
                                                comm_go = 0;
                                                next_state = SEND_DISABLE;
                                        end
                                end 
                                
                                // 6�ܰ�) SEND_DISABLE
                                SEND_DISABLE : begin
                                         if(count_usec <= 22'd200) begin
                                                // ������ ����
                                                data = {send_buffer[3:0], 3'b100, rs}; // data, BT, Enable, RW, RS
                                                comm_go = 1;
                                                count_usec_en = 1;
                                        end
                                        else begin
                                                count_usec_en = 0;
                                                comm_go = 0;
                                                next_state = IDLE;
                                                busy = 0;
                                        end
                                end 
                        endcase
                end
        end

        // Instance of I2C master module
        I2C_master I2C_master_0 (.clk(clk), .reset_p(reset_p), .addr(addr),  .rd_wr(0), .data(data),  .comm_go(comm_go), .scl(scl), .sda(sda), .led(led));
        
endmodule   

module dht11_control(
    input clk, reset_p, 
    inout dht11_data,
    output [15:0] dht11_value);
    
    wire [7:0] humidity, temperature; 
    dht11_cntrl dth11( .clk(clk), .reset_p(reset_p), .dht11_data(dht11_data), .humidity(humidity), .temperature(temperature), .led_debug(led_debug));
    
    wire [15:0] humidity_bcd, temperature_bcd;
    bin_to_dec bcd_humi(.bin({4'b0, humidity}),  .bcd(humidity_bcd));
    bin_to_dec bcd_temp(.bin({4'b0, temperature}),  .bcd(temperature_bcd));
    
    assign value = {humidity_bcd[7:0], temperature_bcd[7:0]};
    
endmodule
