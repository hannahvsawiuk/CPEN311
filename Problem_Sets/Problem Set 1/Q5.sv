module q5 (
    input clk,
    input [7:0] xn,
    input b1,
    input b2, 
    input a1,
    input a2,
    output [7:0] yn
);

    wire [7:0] reg1_out, reg2_out, reg3_out, reg4_out, mult1_out, mult2_out, mult3_out, mult4_out, add2_out1, add3_out;

    reg8a reg8 (.clk(clk), .in(xn), .out(reg1_out));
    reg8b reg8 (.clk(clk), .in(reg1_out), .out(reg2_out));
    reg8c reg8 (.clk(clk), .in(yn), .out(reg3_out));
    reg8d reg8 (.clk(clk), .in(reg3_out), .out(reg4_out));

    multa multiplier (.in1(reg1_out), .in2(b1), .out(mult1_out));
    multb multiplier (.in1(reg2_out), .in2(b2), .out(mult2_out));
    multc multiplier (.in1(reg3_out), .in2(a1), .out(mult3_out));
    multd multiplier (.in1(reg4_out), .in2(a2), .out(mult4_out));

    add2a #(2) adder (.in1(mult2_out), .in2(mult4_out), .in3(8'bz), .out(add2_out1));
    add3a #(3) adder (.in1(mult1_out), .in2(mult3_out), .in3(add3_out));
    add2b #(2) adder (.in1(xn), in2(add3_out), .in3(8'bz), .out(yn));

    
endmodule

module adder;
parameter num_ins = 2;
input in1[7:0];
input in2[7:0];
input in3 [7:0];
output out [7:0];

    assign out = (inputs == 2)? in1 + in2 : in1 + in2 + in3;

endmodule

module multiplier (
    input [7:0] in1,
    input [7:0] in2,
    input [7:0] out
);
    assign out = in1*in2;
endmodule

module reg8 (
    input clk,
    input [7:0] in,
    input [7:0] out
);
    always_ff @ (posedge clk) begin
        out <= in;
    end
endmodule