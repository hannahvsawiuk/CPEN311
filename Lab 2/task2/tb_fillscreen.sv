// define timescale
`timescale 1ns/100ps 

module tb_fillscreen;

    // inputs
    logic clk, rstn, start;
    logic [2:0] colour;  

    // outputs
    logic done, vga_plot;
    logic [7:0] vga_x;
    logic [6:0] vga_y;
    logic [2:0] vga_colour;


    //module instantiation
    fillscreen dut (.*);

    // generate 50MHz clock 
    initial begin
        clk = 1'b0; #10;
        forever begin
        clk = 1'b1; #10;
        clk = 1'b0; #10;
        end
    end

    initial begin
        rstn = 0; #10; // reset everything
        rstn = 1;
        start = 1;
        repeat (19200) begin
            #20;
        end
        rstn = 0; #20;
        rstn = 1; #20;
        $stop;
    end

endmodule