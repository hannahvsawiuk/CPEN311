module q4 (
    input STB,
    input CLK,
    output TS,
    output TL
);

logic low;

always_ff @(posedge CLK or negedge STB) begin
    if(STB == 1'b0) begin
        low = 1'b1;
    end else begin
        if (low && CLK) begin
            TS = 0;
            TL = 0;
            low = 1'b0;
            cnt = 0;
        end else if (cnt < 3) begin
            TS = 0;
            TL = 0;
            cnt = cnt + 1;
        end else if (cnt < 6) begin
            TS = 1;
            TL = 0;
            cnt = cnt + 1;
        end else begin
            TS = 0;
            TL = 0;
        end
    end      

end
    
endmodule