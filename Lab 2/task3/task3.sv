module task3(input logic CLOCK_50, input logic KEY[3:0], // KEY[3] is async active-low reset
             output logic [9:0] VGA_R, output logic [9:0] VGA_G, output logic [9:0] VGA_B,
             output logic VGA_HS, output logic VGA_VS,
             output logic VGA_BLANK, output logic VGA_SYNC, output logic VGA_CLK);
  
/*
Instructor comments
============================  
Instantiate and connect the VGA adapter and your module 
*/
//----------------------------//
//         Wires              // 
//----------------------------//
    wire [2:0] vga_colour;
    wire [7:0] vga_x;
    wire [6:0] vga_y;
    wire vga_plot;

//----------------------------//
//         Logic              // 
//----------------------------//
    logic start;
    logic done;
    logic [2:0] colour;
    logic [7:0] centre_x, radius;
    logic [6:0] centre_y;

//----------------------------//
//   Module Instantiations    // 
//----------------------------//
    // instantiate circle
    circle circ (.clk(CLOCK_50), .rstn(KEY[3]), .colour(colour),
              .centre_x(centre_x), .centre_y(centre_y), .radius(radius),
              .start(start), .done(done), .vga_x(vga_x), .vga_y(vga_y),
              .vga_colour(vga_colour),.vga_plot(vga_plot));

    // instantiate vga_adapter
    vga_adapter #(.RESOLUTION("160x120")) vga_u0(.resetn(KEY[3]), .clock(CLOCK_50), .colour(vga_colour),
                                                .x(vga_x), .y(vga_y), .plot(vga_plot), .*);
//****************************//
//      Start Logic           //    
//****************************//  
    // circle params
    assign radius   = 40; // 160/2 / 2
    assign centre_x = 80; // 160/2
    assign centre_y = 60; // 120/2

    always_ff @ (posedge CLOCK_50 or negedge KEY[3]) begin 
        if(KEY[3] == 1'b0) begin
            start = 0;
        end else if (!done) begin // if not done, then keep start high
            start = 1;
        end else begin // if done, then de-assert start
            start = 0;
        end
    end

endmodule

