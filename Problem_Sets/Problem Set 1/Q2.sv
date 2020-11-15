module q2 (
    input clk,
    input reset,
    output outs
);
    logic [5:0] out;

    assign outs = out[5];

    always_ff @ (posedge clk or negedge reset) begin // asynch reset
        if (reset == 1'b0) begin
            out <= 0;
        end else begin
            out[0] <= out[5] ^ out[4];
            out <= {out[4:0],out[0]};
        end
    end

    
endmodule