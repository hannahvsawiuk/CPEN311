module tb_scorehand;
    // Inputs become regs and outputs become wires. No intermediate connections are included
    reg [3:0] card1; 
    reg [3:0] card2; 
    reg [3:0] card3; 
    wire [3:0] total;
    
    //module instantiation
    scorehand testscore (.card1(card1), .card2(card2), .card3(card3), .total(total)); 

    initial begin
        repeat (15) begin //test 15 different combinations
        card1 = $urandom_range(13);
        card2 = $urandom_range(13);
        card3 = $urandom_range(13);
        #20; $display("Card1 = %d  Card2 = %d  Card3 = %d  Total = %d", card1, card2, card3, total);
        end
    $stop;
    end
endmodule

