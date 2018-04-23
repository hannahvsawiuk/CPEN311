module datapath(input slow_clock, input fast_clock, input resetb,
                input load_pcard1, input load_pcard2, input load_pcard3,
                input load_dcard1, input load_dcard2, input load_dcard3,
                output [3:0] pcard3_out,
                output [3:0] pscore_out, output [3:0] dscore_out,
                output[6:0] HEX5, output[6:0] HEX4, output[6:0] HEX3,
                output[6:0] HEX2, output[6:0] HEX1, output[6:0] HEX0);

/*
Instructor comments
============================			
The code describing your datapath will go here. Your datapath will hierarchically instantiate 
six (6) card7seg blocks, two (2) scorehand blocks, and a (1) dealcard block.  **HINT**
The registers may either be instatiated or included as sequential always blocks directly in this file.
Follow the block diagram in the Lab 1 handout closely as you write this code.
*/
//==================================//
//      Intermediate Wire(s)        // 
//==================================//
// connect the individual blocks in the 
    wire [3:0] new_card;  
    wire [3:0] pcard1_out, pcard2_out, dcard1_out, dcard2_out, dcard3_out;

//==================================//
//     Module Instantiations        // 
//==================================//

//****************************//
//         Deal Cards         //    
//****************************//
// Counter used with a 50MHz clock. Value captured when the slow_clock reaches a 
// posedge indicating a step forward in the algorithm.
// This block is SYNCHRONOUS with fast_clock
    dealcard deal (.clock(fast_clock), .resetb(resetb), .new_card(new_card));

//****************************//
//      4-bit Registers       //    
//****************************//
// Registers for storing the player and dealer cards. If one of the load_cards = 1, then the current
// value of new_card is loaded into the register. Then, on the the next slow_clock (next step in algorithm),
// the value in the register is written to the output.
// This block is SYNCHRONOUS with slow_clock
// player
    reg4 PCard1_reg (.new_card(new_card), .load_card(load_pcard1), .resetb(resetb), .slow_clock(slow_clock), .card_out(pcard1_out)); 
    reg4 PCard2_reg (.new_card(new_card), .load_card(load_pcard2), .resetb(resetb), .slow_clock(slow_clock), .card_out(pcard2_out));
    reg4 PCard3_reg (.new_card(new_card), .load_card(load_pcard3), .resetb(resetb), .slow_clock(slow_clock), .card_out(pcard3_out));
    // dealer
    reg4 DCard1_reg (.new_card(new_card), .load_card(load_dcard1), .resetb(resetb), .slow_clock(slow_clock), .card_out(dcard1_out));  
    reg4 DCard2_reg (.new_card(new_card), .load_card(load_dcard2), .resetb(resetb), .slow_clock(slow_clock), .card_out(dcard2_out));
    reg4 DCard3_reg (.new_card(new_card), .load_card(load_dcard3), .resetb(resetb), .slow_clock(slow_clock), .card_out(dcard3_out));

//****************************//
//          Scores            //    
//****************************//
// Computes score given the current cards in the hand. 
// This block is ASYNCHRONOUS
    scorehand pscore (.card1(pcard1_out), .card2(pcard2_out), .card3(pcard3_out), .total(pscore_out)); // player 
    scorehand dscore (.card1(dcard1_out), .card2(dcard2_out), .card3(dcard3_out), .total(dscore_out)); // dealer

//****************************//
//          HEX Display       //    
//****************************//
// Displays the cards from the dealer's and player's hand using the HEX display.
// This block is ASYNCHRONOUS
    // player
    card7seg pcard1_seg (.card(pcard1_out),.HEX(HEX0));
    card7seg pcard2_seg (.card(pcard2_out),.HEX(HEX1));
    card7seg pcard3_seg (.card(pcard3_out),.HEX(HEX2));
    // dealer
    card7seg dcard1_seg (.card(dcard1_out),.HEX(HEX3));
    card7seg dcard2_seg (.card(dcard2_out),.HEX(HEX4));
    card7seg dcard3_seg (.card(dcard3_out),.HEX(HEX5));

endmodule


// 4 bit register module
module reg4 (
    input [3:0] new_card,
    input load_card,
    input resetb,       // KEY3
    input slow_clock,   // KEY0, clocked with slow_clock
    output reg [3:0] card_out
);

    always_ff @ (negedge slow_clock or negedge resetb) begin //negedge resetb since it is active low
        if(resetb == 1'b0) 
            card_out <= 0; 
    	else if (load_card) 
            card_out <= new_card;           
    end
endmodule







