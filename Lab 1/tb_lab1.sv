// define timescale
`timescale 1ns/100ps 



module tb_lab1;

    // inputs
    reg CLOCK_50;
    reg [3:0] KEY;

    // outputs
    wire [9:0] LEDR;
    wire [6:0] HEX5, HEX4, HEX3, HEX2, HEX1, HEX0;

    // module instantiation
    lab1 testlab1 (.CLOCK_50(CLOCK_50), 
                   .KEY(KEY), 
                   .LEDR(LEDR), 
                   .HEX5(HEX5), 
                   .HEX4(HEX4), 
                   .HEX3(HEX3), 
                   .HEX2(HEX2), 
                   .HEX1(HEX1), 
                   .HEX0(HEX0));

    // generate 50MHz clock 
    initial begin
        CLOCK_50 = 1'b0; #10;
        forever begin
        CLOCK_50 = 1'b1; #10;
        CLOCK_50 = 1'b0; #10;
        end
    end

    // generate slow clock
    initial begin
        KEY[0] = 1'b0; #100;
        forever begin
        KEY[0] = 1'b1; #100;
        KEY[0] = 1'b0; #100;
        end
    end

    initial begin
        KEY[3] = 1'b0; //reset everything.
        #40;
        KEY[3] = 1'b1; // run sim
        #4000;
        KEY[3] = 1'b0; // reset
        #100;
        $stop;
    end

endmodule
                  