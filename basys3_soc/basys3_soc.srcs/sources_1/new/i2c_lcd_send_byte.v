`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/08/26 12:28:38
// Design Name: 
// Module Name: i2c_lcd_send_byte
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

// I2C Text ����
module i2c_txtld_top (
    input clk, reset_p,
    output scl, sda,
    output [15:0] led_debug
);

    // Declare state machine
    parameter IDLE = 6'b00_0001;
    parameter INIT = 6'b00_0010;
    parameter SEND_DATA = 6'b00_0100;
    parameter SEND_COMMAND = 6'b00_1000;
    parameter SEND_STRING = 6'b01_0000;

    // Get usecond clock
    wire clk_usec;
    clock_div_100 usec_clk (
        .clk(clk),
        .reset_p(reset_p),
        .clk_div_100_nedge(clk_usec)
    );

    // ����ũ�μ����� ������ ī��Ʈ
    reg [21:0] count_usec;
    reg count_usec_en;

    always @(negedge clk or posedge reset_p) begin
        if (reset_p)
            count_usec = 0;
        else if (clk_usec && count_usec_en)
            count_usec = count_usec + 1;
        else if (!count_usec_en)
            count_usec = 0;
    end

    // Declare register of text
    reg [7:0] send_buffer;

    // Declare variables
    reg rs, send;
    wire busy;

    // Instance of i2c lcd send byte
    i2c_lcd_send_byte i2c_lcd_send_byte_0 (
        .clk(clk),
        .reset_p(reset_p),
        .addr(7'h27),
        .send_buffer(send_buffer),
        .rs(rs),
        .send(send),
        .scl(scl),
        .sda(sda),
        .busy(busy),
        .led(led_debug)
    );

    // Declare state, next state
    reg [5:0] state, next_state;

    // State transition
    always @(negedge clk or posedge reset_p) begin
        if (reset_p)
            state = IDLE;
        else
            state = next_state;
    end

    // �ʱ�ȭ �÷��� ��������
    reg init_flag;

    // Counting for data
    reg [3:0] cnt_data;

    // ���ڿ� Register
    reg [8*5-1:0] hello;
    reg [3:0] cnt_string;

    // �� ���¿� ���� ���� ����
    always @(posedge clk or posedge reset_p) begin
        if (reset_p) begin
            next_state = IDLE;
            init_flag = 0;
            count_usec_en = 0;
            cnt_data = 0;
            rs = 0;
            hello = "HELLO"; // C���ó�� �������� NULL�� ����.
            cnt_string = 0;
        end
        else begin
            case (state)
                // IDLE ����
                IDLE: begin
                    if (init_flag) begin
                        if (btn_pedge[0])
                            next_state = SEND_DATA;
                        if (btn_pedge[1])
                            next_state = SEND_COMMAND;
                        if (btn_pedge[2])
                            next_state = SEND_STRING;                                           
                    end
                    else begin
                        if (count_usec <= 22'd80_000) begin
                            count_usec_en = 1;
                        end
                        else begin
                            count_usec_en = 0;
                            next_state = INIT;
                        end
                    end
                end
                
                // INIT ����
                INIT: begin
                    if (busy) begin
                        send = 0;
                        if (cnt_data >= 6) begin
                            init_flag = 1;
                            cnt_data = 0;
                            next_state = IDLE;
                        end
                    end
                    else if (!send) begin
                        case (cnt_data)
                            0: send_buffer = 8'h33;
                            1: send_buffer = 8'h32;
                            2: send_buffer = 8'h28; // 2��, 5X8 Dots ���
                            3: send_buffer = 8'h0f; // Display: 1, Cursor: on + ������ 
                            4: send_buffer = 8'h01;
                            5: send_buffer = 8'h06;
                        endcase
                        rs = 0;
                        cnt_data = cnt_data + 1;
                        send = 1;
                    end
                end
                
                // SEND_DATA ����
                SEND_DATA: begin
                    if (busy) begin
                        next_state = IDLE;
                        send = 0;
                        if (cnt_data >= 9)
                            cnt_data = 0;
                        else
                            cnt_data = cnt_data + 1;
                    end
                    else begin
                        send_buffer = "0" + cnt_data; // A�� �ƽ�Ű �ڵ�
                        rs = 1;
                        send = 1;
                    end
                end
                
                // SEND_COMMAND ����
                SEND_COMMAND: begin
                    if (busy) begin
                        next_state = IDLE;
                        send = 0;
                        if (cnt_data >= 9)
                            cnt_data = 0;
                        else
                            cnt_data = cnt_data + 1;
                    end
                    else begin
                        send_buffer = 8'h14;
                        rs = 0;
                        send = 1;
                    end
                end
                
                // SEND_STRING ����
                SEND_STRING: begin
                    if (busy) begin
                        send = 0;
                        if (cnt_string >= 5) begin
                            cnt_string = 0;
                            next_state = IDLE;
                        end
                    end
                    else if (!send) begin
                        case (cnt_string)
                            0: send_buffer = hello[39 : 32];
                            1: send_buffer = hello[31 : 24];
                            2: send_buffer = hello[23 : 16];
                            3: send_buffer = hello[15 : 8];
                            4: send_buffer = hello[7 : 0];
                        endcase
                        rs = 1;
                        cnt_string = cnt_string + 1;
                        send = 1;
                    end
                end
            endcase
        end
    end
endmodule

// LCD ���÷��̿� i2c ��� 
// 1 byte ���� ������ ����
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
        parameter IDLE                            = 6'b00_0001;
        parameter SEND_HIGH_NIBBLE_DISABLE        = 6'b00_0010;
        parameter SEND_HIGH_NIBBLE_ENABLE         = 6'b00_0100;
        parameter SEND_LOW_NIBBLE_DISABLE         = 6'b00_1000;
        parameter SEND_LOW_NIBBLE_ENABLE          = 6'b01_0000;
        parameter SEND_DISABLE                    = 6'b10_0000;


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


// I2C_master
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