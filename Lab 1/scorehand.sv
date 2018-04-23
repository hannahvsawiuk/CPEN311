/*
Instructor comments
============================
The code describing scorehand will go here.  Remember this is a combinational
block. The function is described in the handout.  Be sure to review the section
on representing numbers in the lecture notes.
*/

module scorehand (
    input [3:0] card1, 
    input [3:0] card2, 
    input [3:0] card3, 
    output reg [3:0] total
    );

    reg [3:0] Value1, Value2, Value3; // individual card score values

    always_comb begin
        if (card1 >= 1 && card1 <= 9) begin
            Value1 = card1;
        end else begin
            Value1 = 0;
        end

        if (card2 >= 1 && card2 <= 9) begin
            Value2 = card2;
        end else begin
            Value2 = 0;
        end

        if (card3 >= 1 && card3 <= 9) begin
            Value3 = card3;
        end else begin
            Value3 = 0;
        end

        total = (Value1 + Value2 + Value3) % 10;
    end

endmodule

/*
Score Logic
============================

Card score
*********************
Card score for card == [Ace, 9] = face value (Note: score for Ace = 1)
Card score for card == [Ten, King] = 0

Hand score
*********************
- Hand can contain up to 3 cards, with a min of two (from initial deal)
- If the hand has only two cards, then cardvalue3 = 0. 
- Score is always in range [0,9]

Hand score = rightmost digit of sum (score of (card1:3)) in decimal (base 10)
--> handscore = sum(cardscore1:3) % 10

Example: 
    card1 = Ace, card2 = 2, card3 = 3
    cardscore1 = 1, cardscore2 = 2, cardscore3 = 3
    handscore = (cardscore1 + cardscore2 + cardscore3) % 10 (Note: % = modulus)
              = ( 1 + 2  + 3) % 10
              = 6 % 10
              = 6
*/

