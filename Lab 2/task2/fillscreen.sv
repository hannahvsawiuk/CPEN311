module fillscreen(input logic clk, input logic rstn, input logic [2:0] colour,
                  input logic start, output logic done,
                  output logic [7:0] vga_x, output logic [6:0] vga_y,
                  output logic [2:0] vga_colour, output logic vga_plot);
 /*
Instructor comments
============================  
Fill the screen 
*/

// only synchronous logic should be for the synchronous load enabled xp/yp registers

//==================================//
//    Unsythesizable Pseudo Code    // 
//==================================//
// for y = 0 to 119:
//     for x = 0 to 159:
//         turn on pixel (x, y) with colour (x % 8) --> colour repeat ever 8 columns

//----------------------------//
//        Parameters          // 
//----------------------------//
    parameter x_width  = 160; 
    parameter y_height = 120; 

//----------------------------//
//     Wires and Logic        // 
//----------------------------//
    logic [7:0] xp, xp_add, xp_in;
    logic [6:0] yp, yp_add, yp_in;
    wire initx, loadx, inity, loady, plot;

//----------------------------//
//         Registers          // 
//----------------------------//
    reg xdone, ydone;

//----------------------------//
//   Module Instantiations    // 
//----------------------------//

    // adders
    adder #(8) xadder (.in(xp), .out(xp_add));
    adder #(7) yadder (.in(yp), .out(yp_add));

    // muxes
    assign xp_in = initx? 8'b0 : xp_add;
    assign yp_in = inity? 7'b0 : yp_add;

    // synchronous load enabled registers
    regn #(8) regx (.in(xp_in), .load(loadx), .rstn(rstn), .clk(clk), .out(xp));
    regn #(7) regy (.in(yp_in), .load(loady), .rstn(rstn), .clk(clk), .out(yp));

    // control module: state machine
    statemachine sm (.rstn(rstn), .clk(clk), .xdone(xdone), .ydone(ydone), 
                     .initx(initx), .loadx(loadx), .inity(inity), .loady(loady), 
                     .plot(plot));

//----------------------------//
//   Done Assertion Logic     // 
//----------------------------//
    always_comb begin : done_logic // equality comparator
        if(xp == x_width - 1) begin
            xdone = 1;
        end else begin
            xdone = 0;
        end
        if(yp == y_height - 1) begin
            ydone = 1;
        end else begin
            ydone = 0;
        end
        done = ydone & xdone; // evaluate using the values of ydone and xdone at the end of the block       
    end

//----------------------------//
//        Assignments         // 
//----------------------------//
    assign vga_plot = plot;
    assign vga_x = xp;
    assign vga_y = yp;
    assign vga_colour = xp % 4'b1000;


endmodule

//******************************************************************************************//

//==================================//
//          N-bit Adder             // 
//==================================//
module adder (in, out);
    parameter n = 7;
    input logic  [n-1:0] in;
    output logic [n-1:0] out;

    always_comb begin : adder
        out = in + 1'b1; 
    end

endmodule

//******************************************************************************************//

//==================================//
//          N-bit Register          // 
//==================================//
module regn (in, load, rstn, clk, out);
    parameter n = 7;
    input logic [n-1:0] in;
    input logic load;
    input logic rstn;     // KEY3
    input logic clk;  
    output logic [n-1:0] out;

    always_ff @ (posedge clk or negedge rstn) begin //negedge rstn since it is active low
        if(rstn == 1'b0) 
            out <= 0; 
    	else if (load) 
            out <= in;           
    end

endmodule

//******************************************************************************************//

//==================================//
//         State Machine            // 
//==================================//
// the state machine is purely combinatorial logic
module statemachine (
    input logic rstn, 
    input logic clk,
    input logic ydone,
    input logic xdone,
    output logic initx,
    output logic loadx,
    output logic inity, 
    output logic loady,
    output logic plot
);
 
//----------------------------//
//        Registers           // 
//----------------------------//
    reg [1:0] state, next_state; 

//----------------------------//
//          Parameters        // 
//----------------------------//
    // states:    reset       | incrementing y | incrementing x | done drawing
    parameter state_rst = 2'b0, state_y = 2'b01, state_x = 2'b10, state_done = 2'b11; 

//****************************//
//    Update State Logic     //    
//****************************//     
    // note that rstn is asynchronous. 
    // always_ff because syncronous with 50 MHz clock
    always_ff @(posedge clk or negedge rstn) begin
        if(rstn == 1'b0) begin      // rstn is active low  
            state = state_rst;
    	end else begin 
            state = next_state;     // update the state;
        end
    end

//****************************//
//      Next State Logic      //    
//****************************//   
    always_comb begin : next_state_logic
        case(state)
            state_rst  : next_state = state_x;
            state_y    : next_state = state_x;
            state_x    : if (!xdone) begin
                            next_state = state_x; // if ydone && xdone, then done drawing  
                        end else if (!ydone) begin
                            next_state = state_y;   
                        end else begin
                            next_state = state_done;    
                        end
            state_done : next_state = state_done;
            default: next_state = state_rst; // default to restart
        endcase
    end

//****************************//
//        Output Logic        //    
//****************************//
    always_comb begin : output_logic
        case(state)  
            state_rst:  {initx,inity,loady,loadx,plot} = 5'b11110;
            state_y:    {initx,inity,loady,loadx,plot} = 5'b10110;
            state_x:    {initx,inity,loady,loadx,plot} = 5'b00011;
            state_done: {initx,inity,loady,loadx,plot} = 5'b00000;
            default:    {initx,inity,loady,loadx,plot} = 5'b11110;   
        endcase
    end

endmodule
