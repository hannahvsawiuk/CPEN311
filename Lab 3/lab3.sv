`include "lab3_inc.sv"

////////////////////////////////////////////////////////////////
//
//  This file is the starting point for Lab 3.  This design implements
//  a simple pong game, with a paddle at the bottom and one ball that
//  bounces around the screen.  When downloaded to an FPGA board,
//  KEY(0) will move the paddle to right, and KEY(1) will move the
//  paddle to the left.  KEY(3) will reset the game.  If the ball drops
//  below the bottom of the screen without hitting the paddle, the game
//  will reset.
//
//  This is written in a combined datapath/state machine style as
//  discussed in the second half of Slide Set 7. It looks like a
//  state machine, but the datapath operations that will be performed
//  in each state are described within the corresponding WHEN clause
//  of the state machine.  From this style, Quartus II will be able to
//  extract the state machine from the design.
//
//  In Lab 3, you will modify this file as described in the handout.
//
//  This file makes extensive use of types and constants described in
//  lab3_inc.v   Be sure to read and understand that file before
//  trying to understand this one.
//
////////////////////////////////////////////////////////////////////////

// Entity part of the description.  Describes inputs and outputs

module lab3(input logic CLOCK_50, input logic [3:0] KEY, input logic [7:0] SW,
            output logic [6:0] HEX0, output logic [6:0] HEX1, output logic [6:0] HEX2,
            output logic [6:0] HEX3, output logic [6:0] HEX4, output logic [6:0] HEX5,
            output logic [9:0] LEDR,
            output logic [9:0] VGA_R, output logic [9:0] VGA_G, output logic [9:0] VGA_B,
            output logic VGA_HS, output logic VGA_VS,
            output logic VGA_BLANK, output logic VGA_SYNC, output logic VGA_CLK);

// These are signals that will be connected to the VGA adapater.
// The VGA adapater was described in the Lab 2 handout.

reg resetn; // asynchronous reset
wire [7:0] x;
wire [6:0] y;
reg [2:0] colour;
reg plot;
point draw; // point is a defined struct in lab3_inc

// The state of our state machine

draw_state_type state; //typedef in include file

// This variable will store the x position of the paddle (left-most pixel of the paddle
reg [INT_BITS-1:0] paddle_x;
reg [INT_BITS-1:0] paddle2_x;
reg [INT_BITS-1:0] paddle_temp; // temp variable to simplify gameplay mode

// These variables will store the puck and the puck velocity.
// In this implementation, the puck velocity has two components: an x component
// and a y component.  Each component is always +1 or -1.

// puck 1
point puck; // defined structure
point16bit puck_acc; // fractional puck accumulator
velocity puck_velocity; // defined struture

// puck2
point puck2; // second puck point
point16bit puck2_acc;
velocity puck2_velocity;

// This will be used as a counter variable in the IDLE state
integer clock_counter = 0;

// shrinking paddle parameters
integer twenty_counter = 0;   // 20 second counter
reg [INT_BITS-1:0] PADDLE_WIDTH;   // removed paddle width as a parameter from header file, use data_width so no changes to existing FSM need to be made
reg [INT_BITS-1:0] PADDLE_X_START;
reg paddle_shrink;        // shrink flag
reg right, left, paddle, stop, puck_sel;
// Be sure to see all the constants, types, etc. defined in lab3_inc.h

// include the VGA controller structurally.  The VGA controller
// was decribed in Lab 2.  You probably know it in great detail now, but
// if you have forgotten, please go back and review the description of the
// VGA controller in Lab 2 before trying to do this lab.

vga_adapter #( .RESOLUTION("160x120")) vga_u0(.resetn(KEY[3]), .clock(CLOCK_50), .*);

// the x and y lines of the VGA controller will be always
// driven by draw.x and draw.y.   The process below will update
// signals draw.x and draw.y.

// x and y inputs to the vga adapter
assign x = draw.x[INT_BITS-1:0];
assign y = draw.y[INT_BITS-2:0]; 


// if SW[4], then pick gameplay vars, else use KEYS and switches
// assign the signal within the gameplay block
// replace SW[3] with paddle
// replace KEY[0] with right
// replace KEY[1] with left

// ============================================================
//                Gameplay logic
// ============================================================
always_ff @(posedge CLOCK_50 or negedge KEY[3]) begin
  if (KEY[3] == 1'b0) begin // reset all the parameters
    left   <= 1'b0;
    right  <= 1'b0;
    paddle <= 1'b0;
  end else begin // if reset not asserted, continue
    if (SW[4] == 1'b1) begin // if in gameplay mode 
      if (SW[0] == 1'b0) begin // if only one puck
          // step 1: select paddle
        stop = 1'b0;
        puck_sel = 1'b0;
        if ((puck.y > SCREEN_HEIGHT/2 - 1) & (puck_velocity.y[DATA_WIDTH_COORD-1] == 1'b0 )) begin // in the lower half and if y velocity is positive
          paddle <= 1'b0; // choose bottom paddle
          paddle_temp = paddle_x; // use non-blocking
        end else if ((puck.y < SCREEN_HEIGHT/2 - 1) & (puck_velocity.y[DATA_WIDTH_COORD-1] == 1'b1)) begin // in the upper half and if y velocity is negative
          paddle <= 1'b1; // top paddle
          paddle_temp = paddle2_x; // use non-blocking
        end else begin
          stop = 1'b1;
        end
      // multiple 2 puck cases:
      // 1: both pucks are in the lower half and both puck velocities are negative, bottom paddle
      // 2: both pucks are in the lower hald and one puck's velocity is negative, bottom paddle
      // 3: both pucks are in the upper half and both puck velocities are positive, top paddle
      // 4: both pucks are in the upper half and one puck's velocity is positive, top paddle
      // 5: pucks are in different halfs, then check velocities
      end else begin
        stop = 1'b0;
        if ((puck.y > SCREEN_HEIGHT/2 - 1) & (puck2.y > SCREEN_HEIGHT/2 - 1)) begin // case 1 or 2
          paddle <= 1'b0; // bottom paddle
          paddle_temp = paddle_x; // use non-blocking
          if ((puck_velocity.y[DATA_WIDTH_COORD-1] == 1'b0 ) & (puck2_velocity.y[DATA_WIDTH_COORD-1] == 1'b0 )) begin // case 1
            if (puck.y > puck2.y) begin // choose which puck will be followed by the paddle
              puck_sel = 1'b0; // puck 1
            end else begin
              puck_sel = 1'b1; // puck 2
            end
          end else begin // case 2
            if (puck_velocity.y[DATA_WIDTH_COORD-1] == 1'b0) begin
              puck_sel = 1'b0;
            end else begin
              puck_sel = 1'b1;
            end
          end
        end else if ((puck.y < SCREEN_HEIGHT/2 - 1) & (puck2.y < SCREEN_HEIGHT/2 - 1)) begin // case 3 or 4
          paddle <= 1'b1; // bottom paddle
          paddle_temp = paddle2_x; // use non-blocking
          if ((puck_velocity.y[DATA_WIDTH_COORD-1] == 1'b1 ) & (puck2_velocity.y[DATA_WIDTH_COORD-1] == 1'b1 )) begin // case 3
            if (puck.y < puck2.y) begin // choose which puck will be followed by the paddle
              puck_sel = 1'b0; // puck 1
            end else begin
              puck_sel = 1'b1; // puck 2
            end
          end else begin // case 4
            if (puck_velocity.y[DATA_WIDTH_COORD-1] == 1'b1) begin
              puck_sel = 1'b0;
            end else begin
              puck_sel = 1'b1;
            end
          end
        end else begin
          if ((puck.y > SCREEN_HEIGHT/2 - 1) & (puck2.y < SCREEN_HEIGHT/2 - 1)) begin
            if ((puck_velocity.y[DATA_WIDTH_COORD-1] == 1'b0) & (puck2_velocity.y[DATA_WIDTH_COORD-1] == 1'b0)) begin
              puck_sel = 1'b0; 
              paddle_temp = paddle_x;
            end else if ((puck_velocity.y[DATA_WIDTH_COORD-1] == 1'b1) & (puck2_velocity.y[DATA_WIDTH_COORD-1] == 1'b1)) begin
              puck_sel = 1'b1;
              paddle_temp = paddle2_x;
            end else if ((puck_velocity.y[DATA_WIDTH_COORD-1] == 1'b0) & (puck2_velocity.y[DATA_WIDTH_COORD-1] == 1'b1)) begin
              if (SCREEN_HEIGHT - puck.y < puck2.y) begin
                puck_sel = 1'b0;
                paddle_temp = paddle_x;
              end else begin
                puck_sel = 1'b1;
                paddle_temp = paddle2_x;
              end
            end else begin
              stop = 1'b1;
            end
          end else begin
            if ((puck_velocity.y[DATA_WIDTH_COORD-1] == 1'b0) & (puck2_velocity.y[DATA_WIDTH_COORD-1] == 1'b0)) begin
              puck_sel = 1'b1;
              paddle_temp = paddle_x;
            end else if ((puck_velocity.y[DATA_WIDTH_COORD-1] == 1'b1) & (puck2_velocity.y[DATA_WIDTH_COORD-1] == 1'b1)) begin
              puck_sel = 1'b0;
              paddle_temp = paddle2_x;
            end else if ((puck_velocity.y[DATA_WIDTH_COORD-1] == 1'b1) & (puck2_velocity.y[DATA_WIDTH_COORD-1] == 1'b0)) begin
              if ( SCREEN_HEIGHT - puck2.y < puck.y) begin
                puck_sel = 1'b1;
                paddle_temp = paddle_x;
              end else begin
                puck_sel = 1'b0;
                paddle_temp = paddle2_x;
              end
            end else begin
              stop = 1'b1;
            end    
          end 
        end
      end
      // step 2: choose direction to move the selected paddle in
      if (stop) begin
        {right, left} <= 2'b0;
      end else begin
        if (puck_sel == 1'b0) begin
          if(puck.x < paddle_temp + PADDLE_WIDTH/2) begin // if puck.x is further right then the center of the paddle
            {right, left} <= 2'b10;
          end else if (puck.x > paddle_temp + PADDLE_WIDTH/2) begin // of puck.x is further left then the center of the paddle
            {right, left} <= 2'b01;
          end else begin
            {right, left} <= 2'b0;
          end
        end else begin
          if(puck2.x < paddle_temp + PADDLE_WIDTH/2) begin // if puck.x is further right then the center of the paddle
            {right, left} <= 2'b10;
          end else if (puck2.x > paddle_temp + PADDLE_WIDTH/2) begin // of puck.x is further left then the center of the paddle
            {right, left} <= 2'b01;
          end else begin
            {right, left} <= 2'b0;
          end
        end
      end                 
    end else begin // if switch off, go to user mode
      right   <= KEY[0];
      left    <= KEY[1];
      paddle  <= SW[3];
    end
  end 
end // always



// paddle shrink logic
always_ff @(posedge CLOCK_50 or negedge KEY[3]) begin
  if (KEY[3] == 1'b0) begin // reset all the parameters
		twenty_counter  <= 0;
    paddle_shrink   <= 1'b0;
		PADDLE_WIDTH    <= INIT_PADDLE_WIDTH[INT_BITS-1:0]; 
	end else begin    
    if (twenty_counter < TWENTYSEC) begin
      twenty_counter <= twenty_counter + 1; // increment the counter if it is less than the max
    end else if (state == INIT) begin // reset the params if the game is lost, only happens in INIT
      twenty_counter   <= 0;
      paddle_shrink    <= 1'b0;
      PADDLE_WIDTH     <= INIT_PADDLE_WIDTH[INT_BITS-1:0];
    end else begin  // if not, reset the counter, and set the shrink flag high
        twenty_counter <= 0;
        paddle_shrink  <= 1'b1;
    end 
    // only decreases if in the draw state
    if ((state == DRAW_PADDLE_ENTER) && (PADDLE_WIDTH > 4) && paddle_shrink) begin // if drawing the paddle and flag high and greater than 4px, decrement
      PADDLE_WIDTH    <= PADDLE_WIDTH - 1'b1;
      paddle_shrink   <= 1'b0;
    end
  end
end

// =============================================================================
// This is the main loop.  As described above, it is written in a combined
// state machine / datapath style.  It looks like a state machine, but rather
// than simply driving control signals in each state, the description describes
// the datapath operations that happen in each state.  From this Quartus II
// will figure out a suitable datapath for you.

// Notice that this is written as a pattern-3 process (sequential with an
// asynchronous reset)

always_ff @(posedge CLOCK_50, negedge KEY[3])

   // first see if the reset button has been pressed.  If so, we need to
   // reset to state INIT

   if (KEY[3] == 1'b0) begin // if reset
      draw.x <= 0;
      draw.y <= 0;

      if(SW[1]) begin
        if(SW[2]) begin
          PADDLE_X_START = PADDLE_X_START_RIGHT;
        end else begin
          PADDLE_X_START = PADDLE_X_START_LEFT;
        end
      end else begin
        PADDLE_X_START = PADDLE_X_START_MID;
      end

      // make the paddles start in the same x-position
      paddle_x <= PADDLE_X_START[INT_BITS-1:0]; // PADDLE_X_START = SCREEN_WIDTH / 2;
      paddle2_x <= PADDLE_X_START[INT_BITS-1:0]; // PADDLE_X_START = SCREEN_WIDTH / 2;   

      // puck 1, start in the right quarter of the screen
      puck.x <= FACEOFF_X[INT_BITS-1:0];
      puck.y <= FACEOFF_Y[INT_BITS-1:0];
      puck_acc.x <= {FACEOFF_X[INT_BITS-1:0],8'b0};
      puck_acc.y <= {FACEOFF_Y[INT_BITS-1:0],8'b0};
      puck_velocity.x <= VELOCITY_START_X[DATA_WIDTH_COORD-1:0];
      puck_velocity.y <= VELOCITY_START_Y[DATA_WIDTH_COORD-1:0]; 

      puck2.x <= FACEOFF_X2[INT_BITS-1:0];
      puck2.y <= FACEOFF_Y2[INT_BITS-1:0];
      puck2_acc.x <= {FACEOFF_X2[INT_BITS-1:0],8'b0};
      puck2_acc.y <= {FACEOFF_Y2[INT_BITS-1:0],8'b0}; 
      puck2_velocity.x <= VELOCITY_START_X2[DATA_WIDTH_COORD-1:0]; 
      puck2_velocity.y <= VELOCITY_START_Y2[DATA_WIDTH_COORD-1:0];

      colour <= BLACK; //erases the puck
      plot   <= 1'b1;
      state  <= INIT; // state transition logic

    // Otherwise, we are here because of a rising clock edge.  This follows
    // the standard pattern for a type-3 process we saw in the lecture slides.

    end else begin

      case (state)

         // ============================================================
         // The INIT state sets the variables to their default values
         // ============================================================

         INIT : begin
            draw.x <= 0;
            draw.y <= 0;

            if(SW[1]) begin
              if(SW[2]) begin
                PADDLE_X_START = PADDLE_X_START_RIGHT;
              end else begin
                PADDLE_X_START = PADDLE_X_START_LEFT;
              end
            end else begin
              PADDLE_X_START = PADDLE_X_START_MID;
            end

            paddle_x <= PADDLE_X_START[INT_BITS-1:0];
            paddle2_x <= PADDLE_X_START[INT_BITS-1:0]; // PADDLE_X_START = SCREEN_WIDTH / 2; 
            // puck1
            // puck 1, start in the right quarter of the screen
            puck.x <= FACEOFF_X[INT_BITS-1:0];
            puck.y <= FACEOFF_Y[INT_BITS-1:0];
            puck_acc.x <= {FACEOFF_X[INT_BITS-1:0],8'b0};
            puck_acc.y <= {FACEOFF_Y[INT_BITS-1:0],8'b0}; 
            puck_velocity.x <= VELOCITY_START_X[DATA_WIDTH_COORD-1:0];
            puck_velocity.y <= VELOCITY_START_Y[DATA_WIDTH_COORD-1:0]; 

            // puck 2
            puck2.x <= FACEOFF_X2[INT_BITS-1:0];
            puck2.y <= FACEOFF_Y2[INT_BITS-1:0]; 
            puck2_acc.x <= {FACEOFF_X2[INT_BITS-1:0],8'b0};
            puck2_acc.y <= {FACEOFF_Y2[INT_BITS-1:0],8'b0}; 
            puck2_velocity.x <= VELOCITY_START_X2[DATA_WIDTH_COORD-1:0]; 
            puck2_velocity.y <= VELOCITY_START_Y2[DATA_WIDTH_COORD-1:0];
                
            colour <= BLACK; // erase puck
            plot   <= 1'b1;
            state  <= START;
           end	 // case INIT

       // ============================================================
         // the START state is used to clear the screen.  We will spend many cycles
       // in this state, because only one pixel can be updated each cycle.  The
       // counters in draw.x and draw.y will be used to keep track of which pixel
       // we are erasing.
       // ============================================================

         START: begin

           // See if we are done erasing the screen
           // DATA_WIDTH_COORD = INT_BITS + FRAC_BITS, so just easier to write
            if (draw.x == SCREEN_WIDTH - 1) begin
              if (draw.y == SCREEN_HEIGHT - 1) begin
                 state <= DRAW_RIGHT_ENTER;
                 colour <= CYAN; // colour of side lines
               end else begin
                // In this cycle we will be erasing a pixel.  Update
                // draw.y so that next time it will erase the next pixel
                // increment the integer part
                  draw.y <= draw.y + 1'b1;
      			      draw.x <= 1'b0;
               end  // else
             end else begin
                // Update draw.x so next time it will erase the next pixel
                draw.x <= draw.x + 1'b1;
            end // if
          end // case START

      // ============================================================
        // The DRAW_RIGHT_ENTER state draws the first pixel of the bar on
      // the right-side of the screen.  The machine only stays here for
      // one cycle; the next cycle it is in DRAW_RIGHT_LOOP to draw the
      // rest of the bar.
      // ============================================================

      DRAW_RIGHT_ENTER: begin
        draw.x <= RIGHT_LINE[INT_BITS-1:0];
        draw.y <= TOP_LINE[INT_BITS-1:0];
        state  <= DRAW_RIGHT_LOOP;
      end // case DRAW_RIGHT_ENTER

      // ============================================================
      // The DRAW_RIGHT_LOOP state is used to draw the rest of the bar on
      // the right side of the screen.
      // Since we can only update one pixel per cycle,
      // this will take multiple cycles
      // ============================================================

      DRAW_RIGHT_LOOP: begin
        // See if we have been in this state long enough to have completed the line
        if (draw.y == SCREEN_HEIGHT-1) begin
        // We are done, so the next state is DRAW_LEFT_ENTER
          state <= DRAW_LEFT_ENTER;	// next state is DRAW_LEFT
        end else begin

        // Otherwise, update draw.y to point to the next pixel
          draw.x <= RIGHT_LINE[INT_BITS-1:0];
          draw.y <= draw.y + 1'b1;
        end
      end //case DRAW_RIGHT_LOOP
      // ============================================================
      // The DRAW_LEFT_ENTER state draws the first pixel of the bar on
      // the left-side of the screen.  The machine only stays here for
      // one cycle; the next cycle it is in DRAW_LEFT_LOOP to draw the
      // rest of the bar.
      // ============================================================

      DRAW_LEFT_ENTER: begin
        draw.x <= LEFT_LINE[INT_BITS-1:0];
        draw.y <= TOP_LINE[INT_BITS-1:0];
        state  <= DRAW_LEFT_LOOP;
      end // case DRAW_LEFT_ENTER

      // ============================================================
      // The DRAW_LEFT_LOOP state is used to draw the rest of the bar on
      // the left side of the screen.
      // Since we can only update one pixel per cycle,
      // this will take multiple cycles
      // ============================================================

      DRAW_LEFT_LOOP: begin

      // See if we have been in this state long enough to have completed the line
        if (draw.y == SCREEN_HEIGHT-1) begin 

      // We are done, so get things set up for the IDLE state, which
      // comes next.

          state <= IDLE;  // next state is IDLE
          clock_counter <= 0;  // initialize counter we will use in IDLE

        end else begin

      // Otherwise, update draw.y to point to the next pixel
          draw.x <= LEFT_LINE[INT_BITS-1:0];
          draw.y <= draw.y + 1'b1;
        end
      end //case DRAW_LEFT_LOOP


      // ============================================================
      // The IDLE state is basically a delay state.  If we didn't have this,
      // we'd be updating the puck location and paddle far too quickly for the
      // the user.  So, this state delays for 1/8 of a second.  Once the delay is
      // done, we can go to state ERASE_PADDLE.  Note that we do not try to
      // delay using any sort of wait statement: that won't work (not synthesziable).
      // We have to build a counter to count a certain number of clock cycles.
      // ============================================================

        IDLE: begin

        // See if we are still counting.  LOOP_SPEED indicates the maximum
        // value of the counter

          plot <= 1'b0;  // nothing to draw while we are in this state

          if (clock_counter < LOOP_SPEED) begin // process happens at 8 Hz
            clock_counter <= clock_counter + 1'b1;
          end else begin

          // otherwise, we are done counting.  So get ready for the
          // next state which is ERASE_PADDLE_ENTER

            clock_counter <= 0;
            state <= ERASE_PADDLE_ENTER;	

          end  // if
        end // case IDLE

      // ============================================================
      // In the ERASE_PADDLE_ENTER state, we will erase the first pixel of
      // the paddle. We will only stay here one cycle; the next cycle we will
      // be in ERASE_PADDLE_LOOP which will erase the rest of the pixels
      // ============================================================
      
      ERASE_PADDLE_ENTER: begin
           draw.y <= PADDLE_ROW[INT_BITS-1:0];
           draw.x <= paddle_x; 
           colour <= BLACK; // erases the paddle
           plot   <= 1'b1;
           state  <= ERASE_PADDLE_LOOP;
     end // case ERASE_PADDLE_ENTER

      // ============================================================
      // In the ERASE_PADDLE_LOOP state, we will erase the rest of the paddle.
      // Since the paddle consists of multiple pixels, we will stay in this state for
      // multiple cycles.  draw.x will be used as the counter variable that
      // cycles through the pixels that make up the paddle.
      // ============================================================

      ERASE_PADDLE_LOOP: begin

          // See if we are done erasing the paddle (done with this state)
        if (draw.x == paddle_x + PADDLE_WIDTH[INT_BITS-1:0]) begin
          // If so, the next state is DRAW_PADDLE_ENTER.
          state <= DRAW_PADDLE_ENTER;  // next state is DRAW_PADDLE
        end else begin
          // we are not done erasing the paddle.  Erase the pixel and update
          // draw.x by increasing it by 1
   		    draw.y <= PADDLE_ROW[INT_BITS-1:0];
          draw.x <= draw.x + 1'b1;
          // state stays the same, since we want to come back to this state
          // next time through the process (next rising clock edge) until
          // the paddle has been erased
        end // if
      end //case ERASE_PADDLE_LOOP

      // ============================================================
      // The DRAW_PADDLE_ENTER state will start drawing the paddle.  In
      // this state, the paddle position is updated based on the keys, and
      // then the first pixel of the paddle is drawn.  We then immediately
      // go to DRAW_PADDLE_LOOP to draw the rest of the pixels of the paddle.
      // ============================================================

      DRAW_PADDLE_ENTER: begin

      // We need to figure out the x lcoation of the paddle before the
      // start of DRAW_PADDLE_LOOP.  The x location does not change, unless
      // the user has pressed one of the buttons.  
        if(paddle == 1'b0) begin
          if (right == 1'b0) begin
          // If the user has pressed the right button check to make sure we
          // are not already at the rightmost position of the screen
            if (paddle_x < RIGHT_LINE - PADDLE_WIDTH - 2) begin 
              // add 2 to the paddle position
              paddle_x = paddle_x + 2'b10;
            end 
            // If the user has pressed the right button check to make sure we
            // are not already at the rightmost position of the screen
          end else begin
            if (left == 1'b0) begin
            // If the user has pressed the left button check to make sure we
            // are not already at the leftmost position of the screen
              if (paddle_x > LEFT_LINE + 2) begin
              // subtract 2 from the paddle position
                paddle_x = paddle_x - 2'b10;
              end 
            end // if
          end //else
        end // if

        // In this state, draw the first element of the paddle
   		    draw.y <= PADDLE_ROW[INT_BITS-1:0];
          draw.x <= paddle_x;  // get ready for next state
          colour <= PURPLE; // when we draw the paddle, the colour will be WHITE
          state  <= DRAW_PADDLE_LOOP;
      end // case DRAW_PADDLE_ENTER

      // ============================================================
      // The DRAW_PADDLE_LOOP state will draw the rest of the paddle.
      // Again, because we can only update one pixel per cycle, we will
      // spend multiple cycles in this state.
      // ============================================================

      DRAW_PADDLE_LOOP: begin

      // See if we are done drawing the paddle

        if (draw.x == paddle_x + PADDLE_WIDTH) begin

        // If we are done drawing the paddle, set up for the next state
          plot  <= 1'b0;
          state <= ERASE_PADDLE2_ENTER;	// next state is ERASE_PUCK
        end else begin
          // Otherwise, update the x counter to the next location in the paddle
          draw.y <= PADDLE_ROW[INT_BITS-1:0];
          draw.x <= draw.x + 1'b1;
          // state stays the same so we come back to this state until we
          // are done drawing the paddle
        end // if
      end // case DRAW_PADDLE_LOOP

    //----------------------------------------------------
    // PADDLE 2
    //----------------------------------------------------
    ERASE_PADDLE2_ENTER: begin
        draw.y <= PADDLE2_ROW[INT_BITS-1:0];
        draw.x <= paddle2_x; 
        colour <= BLACK; 
        plot   <= 1'b1;
        state  <= ERASE_PADDLE2_LOOP;
    end 
    
    ERASE_PADDLE2_LOOP: begin
        if (draw.x == paddle2_x + PADDLE_WIDTH[INT_BITS-1:0]) begin
          state  <= DRAW_PADDLE2_ENTER;  
        end else begin
          draw.y <= PADDLE2_ROW[INT_BITS-1:0];
          draw.x <= draw.x + 1'b1;
        end 
    end

    DRAW_PADDLE2_ENTER: begin
        if(paddle == 1'b1) begin
          if (right == 1'b0) begin
            if (paddle2_x < RIGHT_LINE - PADDLE_WIDTH - 2) begin 
              paddle2_x = paddle2_x + 2'b10;
            end 
          end else begin
            if (left == 1'b0) begin
              if (paddle2_x > LEFT_LINE + 2) begin
                paddle2_x = paddle2_x - 2'b10;
              end 
            end
          end 
        end
          draw.y <= PADDLE2_ROW[INT_BITS-1:0];
          draw.x <= paddle2_x;  
          colour <= PURPLE;
          state  <= DRAW_PADDLE2_LOOP;
    end 

    DRAW_PADDLE2_LOOP: begin
      if (draw.x == paddle2_x + PADDLE_WIDTH) begin
        plot  <= 1'b0;
        state <= ERASE_PUCK;
      end else begin
        draw.y <= PADDLE2_ROW[INT_BITS-1:0];
        draw.x <= draw.x + 1'b1;
      end 
    end 
      

      // ============================================================
      // The ERASE_PUCK state erases the puck from its old location
      // At also calculates the new location of the puck. Note that since
      // the puck is only one pixel, we only need to be here for one cycle.
      // ============================================================
    ERASE_PUCK:  begin
        colour  <= BLACK;  // erase by setting colour to black
        plot    <= 1'b1;
        draw    <= puck;  // the x and y lines are driven by "puck" which holds the location of the puck.
        state   <=  DRAW_PUCK;  // next state is DRAW_PUCK.
        
        // update the location of the puck
        puck_acc.x = puck_acc.x + puck_velocity.x; // position = position + velocity (from slides)
        puck_acc.y = puck_acc.y + puck_velocity.y;

        // round to the nearest integer: since puck only 8 bits, check the intermediate variable puck_acc (fractional accumulator) to see if rounding is required
        if(puck_acc.x[INT_BITS-1:0] >= 8'd125) begin
          puck.x = puck_acc.x[DATA_WIDTH_COORD-1:FRAC_BITS] + 1'b1; 
        end else begin
          puck.x = puck_acc.x[DATA_WIDTH_COORD-1:FRAC_BITS];
        end

        if(puck_acc.y[INT_BITS-1:0] >= 8'd125) begin
          puck.y = puck_acc.y[DATA_WIDTH_COORD-1:FRAC_BITS] + 1'b1; 
        end else begin
          puck.y = puck_acc.y[DATA_WIDTH_COORD-1:FRAC_BITS];
        end
 
        // See if we have bounced off the right or left of the screen
        if ((puck.x == LEFT_LINE + 1) | (puck.x == RIGHT_LINE - 1)) begin
          puck_velocity.x = 0-puck_velocity.x;
        end // if
        // See if we have bounced off the paddle on the bottom row of the screen
        if ((puck.y == PADDLE_ROW - 1) | (puck.y == PADDLE2_ROW + 1)) begin
          if ( ((puck.x >= paddle_x) & (puck.x <= paddle_x + PADDLE_WIDTH)) | 
               ((puck.x >= paddle2_x) & (puck.x <= paddle2_x + PADDLE_WIDTH)) ) begin
            // we have bounced off the paddle
   				  puck_velocity.y = 0-puck_velocity.y;
          end else begin
          // we are at the bottom row, but missed the paddle.  Reset game!
            state <= INIT;
          end // else
        end // if
    end // ERASE_PUCK
      // ============================================================
      // The DRAW_PUCK draws the puck.  Note that since
      // the puck is only one pixel, we only need to be here for one cycle.
      // ============================================================

      DRAW_PUCK: begin
        colour <= GREEN;
        plot   <= 1'b1;
        draw   <= puck;
        if (SW[0]) begin 
            state <= ERASE_PUCK2;
        end else begin
            state <= IDLE;	// next state is IDLE (which is the delay state)
        end
      end // case DRAW_PUCK

    // ============================================================
    // ERASE_PUCK2
    // ============================================================
      ERASE_PUCK2:  begin
        colour  <= BLACK;  
        plot    <= 1'b1;
        draw    <= puck2;  // the x and y lines are driven by "puck2"

        state   <= DRAW_PUCK2;  

        puck2_acc.x = puck2_acc.x + puck2_velocity.x; // position = position + velocity (from slides)
        puck2_acc.y = puck2_acc.y + puck2_velocity.y;

        // round to the nearest integer
        if(puck2_acc.x[INT_BITS-1:0] >= 8'd125) begin
          puck2.x = puck2_acc.x[DATA_WIDTH_COORD-1:FRAC_BITS] + 1'b1; 
        end else begin
          puck2.x = puck2_acc.x[DATA_WIDTH_COORD-1:FRAC_BITS];
        end

        if(puck2_acc.y[INT_BITS-1:0] >= 8'd125) begin
          puck2.y = puck2_acc.y[DATA_WIDTH_COORD-1:FRAC_BITS] + 1'b1; 
        end else begin
          puck2.y = puck2_acc.y[DATA_WIDTH_COORD-1:FRAC_BITS];
        end

        // See if we have bounced off the right or left of the screen
        if ((puck2.x == LEFT_LINE + 1) | (puck2.x == RIGHT_LINE - 1)) begin
          puck2_velocity.x = 0-puck2_velocity.x;
        end // if
        // See if we have bounced off the paddle on the bottom row of the screen
        if ((puck2.y == PADDLE_ROW - 1) | (puck2.y == PADDLE2_ROW + 1)) begin
          if ( ((puck2.x >= paddle_x) & (puck2.x <= paddle_x + PADDLE_WIDTH)) | 
               ((puck2.x >= paddle2_x) & (puck2.x <= paddle2_x + PADDLE_WIDTH)) ) begin
            // we have bounced off the paddle
   				  puck2_velocity.y = 0-puck2_velocity.y;
          end else begin
          // we are at the bottom row, but missed the paddle.  Reset game!
            state <= INIT;
          end // else
        end // if


      end // ERASE_PUCK2

    // ============================================================
    // DRAW_PUCK2
    // ============================================================
      DRAW_PUCK2: begin
        plot   <= 1'b1;
        draw   <= puck2;
        state  <= IDLE;	// next state is IDLE (which is the delay state)
        colour <= BLUE;
      end // case DRAW_PUCK2

 	// ============================================================
  // We'll never get here, but good practice to include it anyway
  // ============================================================

      default: state <= START;
    endcase
  end // if
endmodule
