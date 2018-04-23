
module tb_reg4;
    reg [3:0] new_card;
    reg load_card, resetb, slow_clock;

    wire [3:0] card_out;

    reg4 testreg4 (.new_card(new_card), .load_card(load_card), .resetb(resetb), .slow_clock(slow_clock), .card_out(card_out));

     // generate slow_clock signal 
    initial begin
        slow_clock = 1'b0; #50;
        forever begin
        slow_clock = 1'b1; #50;
        slow_clock = 1'b0; #50;
        end
    end

    initial begin
            load_card = 1'b0; #150;
        forever begin
            load_card = 1'b1; #150;
            load_card = 1'b0; #150;
        end
    end

    initial begin
        resetb = 1'b1;
        new_card = 4'b0;
        repeat (15) begin
            new_card += 4'b0001; #100;
        end
        resetb = 1'b0; #100;
        $stop;
    end
endmodule