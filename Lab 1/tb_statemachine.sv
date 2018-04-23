// define timescale
`timescale 1ns/100ps 

module tb_statemachine;

    // inputs
    reg slow_clock, resetb; 
    reg [3:0] dscore, pscore, pcard3; 
    // outputs
    wire load_pcard1, load_pcard2, load_pcard3, load_dcard1, load_dcard2, load_dcard3;
    wire player_win_light, dealer_win_light;

    // test bench variables
    integer i, j, test, tests_passed;

    //module instantiation
statemachine sm(.slow_clock(slow_clock),
                .resetb(resetb),
                .dscore(dscore),
                .pscore(pscore),
                .pcard3(pcard3),
                .load_pcard1(load_pcard1),
                .load_pcard2(load_pcard2),
                .load_pcard3(load_pcard3),						  
                .load_dcard1(load_dcard1),
                .load_dcard2(load_dcard2),
                .load_dcard3(load_dcard3),	
                .player_win_light(player_win_light), 
                .dealer_win_light(dealer_win_light));

    // generate signal for slow_clock
    initial begin
        slow_clock = 1'b0; #50;
        forever begin
        slow_clock = 1'b1; #50;
        slow_clock = 1'b0; #50;
        end
    end


    initial begin
        // reset everything
        test = 0;
        tests_passed = 0;
        resetb = 1'b0;
        pscore = 4'b0;
        dscore = 4'b0;
        pcard3 = 4'b0;
        #10;
        // stop reset and begin
        resetb = 1'b1;
        //test scores
        for (j = 0; j <= 9; j += 3) begin
            for (i = 0; i <= 9; i += 3) begin
                pscore = i;
                dscore = j;
                test += 1;
                if (pcard3 < 13) begin
                    pcard3 += 1;
                end else begin
                    pcard3 = 1;
                end
                #10; 
                case({player_win_light,dealer_win_light})
                    2'b11:      assert (pscore == dscore) begin
                                    $display("Score test %d passed. Tie: pscore = %d  dscore = %d", test, pscore, dscore);
                                    tests_passed += 1;
                                end else begin
                                    $display("Score test %d failed. Tie: pscore = %d  dscore = %d", test, pscore, dscore); 
                                end
                    2'b10:      assert (pscore > dscore ) begin
                                    $display("Score test %d passed: Player win: pscore = %d  dscore = %d", test, pscore, dscore);
                                    tests_passed += 1;
                                end else begin
                                    $display("Score test %d failed: Player win: pscore = %d  dscore = %d", test, pscore, dscore);
                                end
                    2'b01:      assert (pscore < dscore ) begin // dealer win
                                    $display("Score test %d passed: Dealer win: pscore = %d  dscore = %d", test, pscore, dscore);
                                    tests_passed += 1;
                                end else begin
                                    $display("Score test %d failed: Dealer win: pscore = %d  dscore = %d", test, pscore, dscore);
                                end 
                    default:    $display("Score test %d failed: Both lights off. pscore = %d  dscore = %d", test, pscore, dscore);
                endcase 
            end
        end
        $display("%d / %d tests passed.", tests_passed, test);
        repeat (10) begin
            resetb = 1'b0; // reset
            #10;
            resetb = 1'b1; // start again
            #1000;
        end
        $stop;
    end
endmodule