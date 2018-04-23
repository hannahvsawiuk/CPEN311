module tb_card7seg;
    reg [3:0] card;  
    wire [6:0] HEX0; 

    card7seg hexdisp (.card(card), .HEX(HEX0)); //module instantiation 

    //display output
    initial begin
        card = 0;
        repeat (16) begin
            $display ("card = %b  HEX0 = %b", card, HEX0);
            card += 1; #20; 
        end
        $stop;
    end
endmodule