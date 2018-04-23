// define timescale
`timescale 1ns/100ps 

module tb_task2;

    // inputs
    logic CLOCK_50, KEY[3:0];

    // outputs
    logic [9:0] VGA_R, VGA_G, VGA_B;
    logic VGA_HS, VGA_VS, VGA_SYNC, VGA_CLK;

    //module instantiation
    task2 dut (.*);

    // generate 50MHz clock 
    initial begin
        CLOCK_50 = 1'b0; #10;
        forever begin
        CLOCK_50 = 1'b1; #10;
        CLOCK_50 = 1'b0; #10;
        end
    end

    initial begin
        KEY[3] = 0; #10; // reset everything
        KEY[3] = 1;
        #384000;
        KEY[3] = 0; #10;
        $stop;
    end

endmodule