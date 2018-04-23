`timescale 1ns/100ps 

module tb_dealcard;

    reg clock, resetb;
    wire [3:0] new_card;
	
    dealcard testdeal (.clock(clock), .resetb(resetb), .new_card(new_card));

   initial begin
        clock = 1'b0; #10;
        forever begin
        clock = 1'b1; #10;
        clock = 1'b0; #10;
        end
    end

    initial begin
        resetb = 1'b1; #100
        repeat (10) begin
        resetb = $urandom_range(0,1); #100;
        end   
        $stop;     
    end

endmodule
