`ifndef _my_incl_vh_
`define _my_incl_vh_

//
// Data width of each x and y
//

parameter DATA_WIDTH_COORD = 16;

// fixed point parameters
parameter FRAC_BITS = 8;
parameter INT_BITS = 8;

//
// This file provides useful parameters and types for Lab 3.
// 

parameter SCREEN_WIDTH = 160;  // 8'b1010 0000
parameter SCREEN_HEIGHT = 120; // 8'b0111 1000

// Use the same precision for x and y as it simplifies life
// A new type that describes a pixel location on the screen


typedef struct {
   reg [INT_BITS-1:0] x;
   reg [INT_BITS-1:0] y;
} point;

typedef struct {
   reg [DATA_WIDTH_COORD-1:0] x;
   reg [DATA_WIDTH_COORD-1:0] y;
} point16bit;

// A new type that describes a velocity.  Each component of the
// velocity can be either + or -, so use signed type

typedef struct {
  reg signed [DATA_WIDTH_COORD-1:0] x;
  reg signed [DATA_WIDTH_COORD-1:0] y;
} velocity;
  
  //Colours.  
parameter BLACK   = 3'b000;
parameter BLUE    = 3'b001;
parameter GREEN   = 3'b010;
parameter CYAN    = 3'b011;
parameter RED     = 3'b100;
parameter PURPLE  = 3'b101;
parameter YELLOW  = 3'b110;
parameter WHITE   = 3'b111;

// We are going to write this as a state machine.  The following
// is a list of states that the state machine can be in.

typedef enum int unsigned {INIT = 1 , START = 2, 
              DRAW_TOP_ENTER = 4, DRAW_TOP_LOOP = 8, 
              DRAW_RIGHT_ENTER = 16, DRAW_RIGHT_LOOP = 32,
              DRAW_LEFT_ENTER = 64, DRAW_LEFT_LOOP = 128, IDLE = 256, 
              ERASE_PADDLE_ENTER = 512, ERASE_PADDLE_LOOP = 1024, 
              DRAW_PADDLE_ENTER = 2048, DRAW_PADDLE_LOOP = 4096,
              ERASE_PADDLE2_ENTER = 8192, ERASE_PADDLE2_LOOP = 16384, 
              DRAW_PADDLE2_ENTER = 32768, DRAW_PADDLE2_LOOP = 65536,
              ERASE_PUCK = 131072, DRAW_PUCK = 262144,
              ERASE_PUCK2 = 524288, DRAW_PUCK2 = 1048576 } draw_state_type;  

// Here are some parameters that we will use in the code. 
 
// These parameters describe the lines that are drawn around the  
// border of the screen  
parameter TOP_LINE = 4; // og 4
parameter RIGHT_LINE = SCREEN_WIDTH - 5;
parameter LEFT_LINE = 5;

// These parameters describe the starting location for the puck 

parameter FACEOFF_X = 8'd120; // int = SCREEN_WIDTH*3/4, dec = 0
parameter FACEOFF_Y = 8'd60;  // int = SCREEN_WIDTH/2, dec = 0

parameter FACEOFF_X2 = 8'd40; // start the second puck on the left quarter of the screen
parameter FACEOFF_Y2 = 8'd60;
  
// Starting Velocity
parameter VELOCITY_START_X = {8'b0,8'b11110110}; // x = 0.9609375 = ~0.96
parameter VELOCITY_START_Y = -{8'b0,8'b01000000}; // y = -0.25

parameter VELOCITY_START_X2 = {8'b0,8'b11011100}; // x = 0.859375 = ~0.86
parameter VELOCITY_START_Y2 = -{8'b0,8'b10000000}; // y = -0.5;

// These parameters contain information about the paddle 
parameter INIT_PADDLE_WIDTH = 10;  // inital width, in pixels, of the paddle
parameter PADDLE_ROW = SCREEN_HEIGHT - 2;  // row to draw the paddle
parameter PADDLE2_ROW = TOP_LINE + 1;  // row to draw the second paddle  (2)

parameter PADDLE_X_START_MID = SCREEN_WIDTH / 2;  // starting x position of the paddle
parameter PADDLE_X_START_LEFT = LEFT_LINE + 1;
parameter PADDLE_X_START_RIGHT = RIGHT_LINE - INIT_PADDLE_WIDTH - 1;
  
// This parameter indicates how many times the counter should count in the
// START state between each invocation of the main loop of the program.
// A larger value will result in a slower game.  The current setting will    
// cause the machine to wait in the start state for 1/8 of a second between 
// each invocation of the main loop.  The 50000000 is because we are
// clocking our circuit with  a 50Mhz clock. 
  
parameter LOOP_SPEED = 50000000/8;  // 8Hz
parameter TWENTYSEC = 20*50000000; // 20 seconds in Hz --> 20 seconds * 50000000 /s = 1*10^9 posedge cycles
  
`endif // _my_incl_vh_