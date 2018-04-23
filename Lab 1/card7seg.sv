
module card7seg(
    input reg [3:0] card, 
    output reg [6:0] HEX
    );

// card codes (input)
  `define card      4
  `define c_blank   4'b0000 //blank
  `define c_a       4'b0001 //Ace
  `define c_2       4'b0010 //2
  `define c_3       4'b0011 //3
  `define c_4       4'b0100 //4
  `define c_5       4'b0101 //5
  `define c_6       4'b0110 //6
  `define c_7       4'b0111 //7
  `define c_8       4'b1000 //8
  `define c_9       4'b1001 //9
  `define c_0       4'b1010 //0
  `define c_j       4'b1011 //Jack
  `define c_q       4'b1100 //Queen
  `define c_k       4'b1101 //King

/* 
7 seg diagram

||=== 0 ===||
||         ||
5           1
||         ||
||=== 6 ===||          
||         ||
4           2
||         ||
||=== 3 ===||


*/

// Recall that 0 turns the segment on and a 1 turns the segment off (active low)

always_comb begin
    case (card)                     //        Segments low (on)
        `c_blank: HEX = {7{1'b1}};  //blank     none
        `c_a    : HEX = 7'b0001000; //Ace       1,2,4,5,0      
        `c_2    : HEX = 7'b0100100; //2         0,1,3,4,6      
        `c_3    : HEX = 7'b0110000; //3         0,1,2,3,6       
        `c_4    : HEX = 7'b0011001; //4         1,2,5,6       
        `c_5    : HEX = 7'b0010010; //5         0,2,3,5,6       
        `c_6    : HEX = 7'b0000010; //6         0,2,3,4,5,6       
        `c_7    : HEX = 7'b1111000; //7         0,1,2;       
        `c_8    : HEX = {7{1'b0}};  //8         all      
        `c_9    : HEX = 7'b0010000; //9         0,1,2,3,5,6       
        `c_0    : HEX = 7'b1000000; //0         0,1,2,3,4,5
        `c_j    : HEX = 7'b1100001; //Jack      1,2,3,4      
        `c_q    : HEX = 7'b0011000; //Queen     0,1,2,5,6       
        `c_k    : HEX = 7'b0001001; //King      1,2,4,5,6      
        default : HEX = {7{1'b1}};  //blank     all
    endcase
  end
	
endmodule

