module q1 (
    input s,
    output done
);
    
    reg[1:0] state, next_state;
    parameter state1 = 2'b0, state2 = 2'b01, state3 = 2'b10;

    always_comb begin : next_state_logic
        case(state)
            state1: next_state = (s == 1'b1)? state2 : state1;
            state2: next_state = (p == 1'b0)? state3 : state2;
            state3: next_state = (s == 1'b0)? state1 : state3;
            default:
        endcase
    end

endmodule