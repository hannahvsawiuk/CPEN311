// define timescale
`timescale 1ns/100ps 

module tb_statemachine;
    // inputs
    logic clk, rstn, finished, pdone;

    // outputs
    logic initx, loadx, inity, loady, plot, initc, loadc, set;


    //module instantiation
    statemachine dut (.*);

    // generate 50MHz clock 
    initial begin
        clk = 1'b0; #10;
        forever begin
        clk = 1'b1; #10;
        clk = 1'b0; #10;
        end
    end

    initial begin
        rstn = 0; 
        finished = 0; 
        pdone = 0;
        #20; // reset everything
        rstn = 1;
        repeat (5) begin
            pdone = 1;
            #1000;
            pdone = 0;
            #100;
        end
        pdone = 1;
        finished = 1;
        #100;
        pdone = 0;
        #100;
        rstn = 0; #10;
        rstn = 1; #10;
        $stop;
    end

endmodule
