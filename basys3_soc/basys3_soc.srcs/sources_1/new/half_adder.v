// Module about AND Gate
module and_gate (
    // Input variable a, b 
    // Output variable q
    input a, b,
    output reg q);
    
    // sensitive variable of always = a, b
    always @(a, b) begin
        case({a, b})
            2'b00 : q = 0;
            2'b01 : q = 0;
            2'b10 : q = 0;
            2'b11 : q = 1;
        endcase
    end
    
endmodule

// Module about XOR Gate
module xor_gate (
    input a, b,
    output reg q );
    
    // sensitive variable of always block
    always @(a, b) begin 
         case({a, b}) 
             2'b00 : q = 0;
             2'b01 : q = 1;
             2'b10 : q = 1;
             2'b11 : q = 0;
           endcase
     end
    
endmodule


// Module about Half-adder
module half_adder (
    input a, b,
    output s, c);
    
    // Module('and_gate')�� instance ������ carry ����.
    // Java���� Class�� instance ����� ����
    // Module�� �ɹ� a, b, c�� ���� ����
    and_gate carry (.a(a), .b(b), .q(c));
    
    // Module('xor_gate')�� instance ������ sum ����.
    xor_gate sum (.a(a), .b(b), .q(s));
    
endmodule