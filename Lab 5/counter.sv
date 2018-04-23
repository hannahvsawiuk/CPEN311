module counter(input logic clk, input logic reset_n,
               input logic [3:0] address, input logic read, output logic [31:0] readdata);

logic [63:0] counter;

always_ff @ (posedge clk or negedge reset_n) begin
    if (!reset_n) begin
        counter = 64'b0;
    end else begin
        counter = counter + 64'b1;
        if (read) begin
            readdata <= (address == 4'b0)? counter[31:0] : counter[63:32];
        end
    end
end


// - create a counter module in Verilog, this will count clock cycles
// - integrate the counter module via Avalon switch fabric by making it a slave in the NIOS system
// - counter module should be accessible from hw_counter.c; write more C code to perform 1000 multiplications and take clock measurements
// - how you measure and record is up to you I think - just report the final number




// In this task you will add a custom Avalon memory-mapped slave that 
// counts the clock cycles since the system was reset. 
// The counter will be a 64-bit-wide unsigned integer. 
// Because we will use a 32-bit Avalon interconnect,
//  we will have to split reading the value into two parts: 
//      reading address offset 0 will return bits 31..0
//      reading address offset 1 will return bits 63..32. 
// A skeleton is provided in counter.sv. Connect this module to your Nios II system.

endmodule: counter