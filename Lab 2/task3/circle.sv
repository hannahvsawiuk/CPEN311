module circle(input logic clk, input logic rstn, input logic [2:0] colour,
              input logic [7:0] centre_x, input logic [6:0] centre_y, input logic [7:0] radius,
              input logic start, output logic done,
              output logic [7:0] vga_x, output logic [6:0] vga_y,
              output logic [2:0] vga_colour, output logic vga_plot);
     // draw the circle


/*
Instructor comments
============================  
draw the circle 
*/

//==================================//
//    Unsythesizable Pseudo Code    // 
//==================================//
// Clear screen as before
// offset_y = 0 
// offset_x = radius 
// crit = 1 – radius 
// while (offset_y <= offset_x) {
//     setPixel( centre_x + offset_x, centre_y + offset_y) 
//     setPixel( centre_x + offset_y, centre_y + offset_x) 
//     setPixel( centre_x - offset_x, centre_y + offset_y) 
//     setPixel( centre_x - offset_y, centre_y + offset_x) 
//     setPixel( centre_x - offset_x, centre_y - offset_y) 
//     setPixel( centre_x - offset_y, centre_y - offset_x) 
//     setPixel( centre_x + offset_x, centre_y - offset_y) 
//     setPixel( centre_x + offset_y, centre_y - offset_x) 
    
//     offset_y := offset_y + 1 
//     if ( crit <= 0 ) { 
//         crit := crit + 2 * offset_y + 1 
//     } else { 
//         offset_x := offset_x - 1
//         crit := crit + 2 * (offset_y – offset_x) + 1 
//     }
// }

//----------------------------//
//        Parameters          // 
//----------------------------//
    // colours
    parameter black     = 3'b000;
    parameter blue      = 3'b001;
    parameter green     = 3'b010;
    parameter cyan      = 3'b011;
    parameter red       = 3'b100;
    parameter pink      = 3'b101;
    parameter yellow    = 3'b110;
    parameter white     = 3'b111;
    // octants
    parameter oct0      = 3'b000;
    parameter oct1      = 3'b001;
    parameter oct2      = 3'b010;
    parameter oct3      = 3'b011;
    parameter oct4      = 3'b100;
    parameter oct5      = 3'b101;
    parameter oct6      = 3'b110;
    parameter oct7      = 3'b111;  

//----------------------------//
//     Wires and Logic        // 
//----------------------------//
    logic [7:0] xp, offset_x;
    logic [6:0] yp, offset_y;
    logic initx, loadx, inity, loady, plot, initc, loadc, set;

//----------------------------//
//         Registers          // 
//----------------------------//
    reg pdone,finished;
    reg signed [8:0] crit;
    reg [2:0] octant; // 8 octants

//----------------------------//
//   Module Instantiations    // 
//----------------------------//
    // control module: state machine
    statemachine sm (.rstn(rstn), .clk(clk), .finished(finished), .pdone(pdone), 
                     .initx(initx), .loadx(loadx), .inity(inity), .loady(loady), 
                     .plot(plot), .initc(initc), .loadc(loadc), .set(set), .start(start));

//----------------------------//
//   Done Assertion Logic     // 
//----------------------------//           
    always_ff @ (posedge clk or negedge rstn) begin 
        if (!rstn) begin // reset the screen
            offset_y = 0;
            offset_x = radius;
            crit     = 1 - radius;
            octant   = 3'b0;
        end else if (plot) begin // if plot is high
            // set pixel given the current octant value
            case(octant)
                oct0: begin xp = centre_x + offset_x; yp = centre_y + offset_y; end
                oct1: begin xp = centre_x + offset_y; yp = centre_y + offset_x; end
                oct2: begin xp = centre_x - offset_x; yp = centre_y + offset_y; end
                oct3: begin xp = centre_x - offset_y; yp = centre_y + offset_x; end
                oct4: begin xp = centre_x - offset_x; yp = centre_y - offset_y; end
                oct5: begin xp = centre_x - offset_y; yp = centre_y - offset_x; end
                oct6: begin xp = centre_x + offset_x; yp = centre_y - offset_y; end
                oct7: begin xp = centre_x + offset_y; yp = centre_y - offset_x; end
                default: {xp,yp} = {centre_x,centre_y};
		    endcase
                 // check octant value and increment or reset accordingly
            if (octant == 7) begin
                octant = 3'b0;
                pdone  = 1;
            end else begin
                octant = octant + 1;
                pdone  = 0;
            end
        end else if (set) begin // if in the set state, set the offset values
            offset_y = offset_y + 1;
            if(crit <= 0) begin 
                crit = crit + 2*offset_y + 1;
            end else begin
                offset_x = offset_x - 1;
                crit = crit + 2*(offset_y - offset_x) + 1;
            end
        end else begin
            offset_y = 0;
            offset_x = radius;
            crit     = 1 - radius;
            octant   = 3'b0;
        end
    end

//----------------------------//
//        Assignments         // 
//----------------------------//
    assign vga_plot = plot;
    assign vga_x = xp;
    assign vga_y = yp;
    assign vga_colour = cyan; // because pretty
    assign finished = (set && (offset_y > offset_x))? 1:0;
    assign done = finished;


endmodule

//******************************************************************************************//

//==================================//
//         State Machine            // 
//==================================//
// the state machine is purely combinatorial logic
module statemachine (
    input logic rstn, 
    input logic clk,
    input logic  finished,
    input logic  pdone,
    input logic start,
    output logic initx,
    output logic loadx,
    output logic inity, 
    output logic loady,
    output logic plot,
    output logic initc,
    output logic loadc,
    output logic set
);
 
//----------------------------//
//        Registers           // 
//----------------------------//
    reg [1:0] state, next_state; 

//----------------------------//
//          Parameters        // 
//----------------------------//
    // states:    reset                                             | done drawing
    parameter state_rst = 2'b0, state_draw = 2'b01, state_set = 2'b10, state_done = 2'b11; 

//****************************//
//    Update State Logic     //    
//****************************//     
    // note that rstn is asynchronous. 
    // always_ff because syncronous with 50 MHz clock
    always_ff @(posedge clk or negedge rstn) begin
        if(rstn == 1'b0) begin      // rstn is active low  
            state <= state_rst;
    	end else begin
            state <= next_state;
        end
    end

//****************************//
//      Next State Logic      //    
//****************************//   
    always_comb begin : next_state_logic
        case(state)
            state_rst  : next_state = state_draw;
            state_draw : if (!pdone) begin // if not done plotting, stay in the draw state
                            next_state = state_draw;
                        end else begin
                            next_state = state_set; // else, set the offset values
                        end
            state_set   : if (!finished) begin // if not done plotting, then stay in draw
                            next_state = state_draw; 
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
            state_rst   : {initx,inity,loadx,loady,plot,initc,loadc,set} = 8'b11110110;
            state_draw  : {initx,inity,loadx,loady,plot,initc,loadc,set} = 8'b00111000;
            state_set   : {initx,inity,loadx,loady,plot,initc,loadc,set} = 8'b00000001;
            state_done  : {initx,inity,loadx,loady,plot,initc,loadc,set} = 8'b00000000;
            default     : {initx,inity,loadx,loady,plot,initc,loadc,set} = 8'b11110110;   
        endcase
    end

endmodule


