`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/07/23 12:15:27
// Design Name: 
// Module Name: tb_dht11_cntr
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


module tb_dht11_cntr();

    parameter [7:0] humi_data = 8'd80;
    parameter [7:0] tmpr_data = 8'd30;
    parameter [7:0] check_sum = humi_data + tmpr_data; 
    parameter [39:0] data = {humi_data, 8'b0, tmpr_data, 8'b0, check_sum};
    // �ռ� ���� 8bit 4�� ������ �� ���ؼ� 
    // ��Ű��� ������ �߻��ߴ� �� ���� Ȯ��

    // Set type of input & output
    reg clk, reset_p; 
    wire [7:0] humidity, temperature;
    
    // tri1 : pull-up ������ �޷��ִ� wire
    // tri0 : pull-down ������ �޷��ִ� wire
    // ���Ǵ����� ����ϸ� 1�� ����Ѵ�.
    tri1 dht11_data;

   
    // dht11_data�� inout�̱� ������ 
    // �ϴ� wire������ �����ϰ�,
    // wr_en ���� ���� dht �����͸� ������, ���Ǵ��� ����� ������.
    // wr_en = 1 �̸� data_buffer;
    reg data_buffer, wr_en;  
    assign dht11_data = wr_en ? data_buffer : 'bz;
    
    
    // Create instance
    dht11_cntr DUT(.clk(clk), .reset_p(reset_p), .dht11_data(dht11_data), .humidity(humidity), .temperature(temperature) );

    // initialization.
    initial begin
        clk = 0;
        reset_p = 1;
        wr_en = 0;
    end
    
    // set clock pulse
    always #5 clk = ~clk;
    
     integer i;
    
    // processing of simulation.
    initial begin
        #10;
        reset_p = 0; #10;
        
        // wait ���� ���ǹ��� ������ ���� �ݺ��� ó�� ��ٸ�
        // 1�ܰ�) wait for negative edge
        wait(!dht11_data);
        
        // 2�ܰ�) wait for positive edge
        wait(dht11_data);
        
        // 3�ܰ�) 20us�� ��ٷȴٰ� 
        // 80us ���� dth_data = 0�� ���
        #20_000;
        data_buffer = 0; wr_en = 1; #80_000;
        
         // 4�ܰ�) 80us ���� dth_data = 'bz ���
        wr_en = 0; #80_000;
        
        //  5�ܰ�) DHT���� Basys3 ���� ������ ������.
        for(i=0; i<40; i= i+1) begin
               wr_en = 1; data_buffer = 0; #50_000;
     
                 // dht_data ���� 0->1�� ��ȯ   
                data_buffer = 1;     
                if(data[39-i]) #70_000;
                else #29_000;
        end     
        
         wr_en = 1; data_buffer = 0; #10;
         wr_en = 0; #10_000;
         
         $finish;
    end 
    
    
endmodule
