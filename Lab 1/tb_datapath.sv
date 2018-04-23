// define timescale
`timescale 1ns/100ps 

module tb_datapath;
    // inputs
    reg slow_clock, fast_clock, resetb; 
    reg load_pcard1, load_pcard2, load_pcard3; 
    reg load_dcard1, load_dcard2, load_dcard3;
    // outputs
    wire [3:0] pcard3_out, pscore_out, dscore_out;
    wire [6:0] HEX5, HEX4, HEX3, HEX2, HEX1, HEX0;
    wire [36:0] HEXseg;

    // testbench variables
    integer i = 6;
    integer index_start;

    //module instantiation
datapath dp(.slow_clock(slow_clock),
            .fast_clock(fast_clock),
            .resetb(resetb),
            .load_pcard1(load_pcard1),
            .load_pcard2(load_pcard2),
            .load_pcard3(load_pcard3),
            .load_dcard1(load_dcard1),
            .load_dcard2(load_dcard2),
            .load_dcard3(load_dcard3),
            .dscore_out(dscore_out),
            .pscore_out(pscore_out),
            .pcard3_out(pcard3_out),
            .HEX5(HEX5),
            .HEX4(HEX4),
            .HEX3(HEX3),
            .HEX2(HEX2),
            .HEX1(HEX1),
            .HEX0(HEX0));

    // generate 50MHz clock 
    initial begin
        fast_clock = 1'b0; #10;
        forever begin
        fast_clock = 1'b1; #10;
        fast_clock = 1'b0; #10;
        end
    end
    // generate signal for slow_clock
    initial begin
        slow_clock = 1'b0; #50;
        forever begin
        slow_clock = 1'b1; #50;
        slow_clock = 1'b0; #50;
        end
    end

    assign HEXseg = {HEX0, HEX1, HEX2, HEX3, HEX4, HEX5};

    initial begin
        // reset everything
        resetb = 1'b0;
        {load_pcard1,load_pcard2,load_pcard3,load_dcard1,load_dcard2,load_dcard3} = 6'b0;
        #10;
        // stop reset and begin
        resetb = 1'b1;
        while(i > 0) begin
            {load_pcard1,load_pcard2,load_pcard3,load_dcard1,load_dcard2,load_dcard3} = 1 << (i-1);
            #100; // wait
            index_start = 6*i; 
            assert(HEXseg[index_start +: 6] != {7{1'b1}}) begin 
                $display("HEX Test %d passed", i); 
            end else begin  
                $error("HEX Test %d failed", i); 
            end          
            i = i - 1;
        end
        resetb = 1'b0;
        #100;
        $stop;
    end
endmodule

