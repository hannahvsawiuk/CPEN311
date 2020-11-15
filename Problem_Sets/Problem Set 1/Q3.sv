module q3 (
    input [15:0] data,
    input valid,
    input clk,
    input reset, // active high synchronous reset
    output [15:0] sum
);

    // no overflow
    // unsigned summation

    always_ff @ (posedge clk) begin
        if(reset) begin
            sum <= 16'b0;
        end else begin
            if(valid) begin
                sum = sum + data;
            end
        end
    end
    
endmodule