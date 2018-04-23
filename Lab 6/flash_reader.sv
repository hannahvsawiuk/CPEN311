module flash_reader(input logic CLOCK_50, input logic [3:0] KEY, input logic [9:0] SW,
                    output logic [6:0] HEX0, output logic [6:0] HEX1, output logic [6:0] HEX2,
                    output logic [6:0] HEX3, output logic [6:0] HEX4, output logic [6:0] HEX5,
                    output logic [9:0] LEDR);

// You may use the SW/HEX/LEDR ports for debugging. DO NOT delete or rename any ports or signals.

//==============================//
//    Module Instantiations     //
//==============================//
// flash 
flash flash_inst(.clk_clk(clk), .reset_reset_n(rst_n), .flash_mem_write(1'b0), .flash_mem_burstcount(1'b1),
                 .flash_mem_waitrequest(flash_mem_waitrequest), .flash_mem_read(flash_mem_read), .flash_mem_address(flash_mem_address),
                 .flash_mem_readdata(flash_mem_readdata), .flash_mem_readdatavalid(flash_mem_readdatavalid), .flash_mem_byteenable(flash_mem_byteenable), .flash_mem_writedata());

// on-chip RAM
s_mem samples(.address(address), .clock(clk), .data(data), .wren(wren), .q(q));


//==============================//
//  Instantiated Module params  //
//==============================//
// flash
logic flash_mem_read, flash_mem_waitrequest, flash_mem_readdatavalid;
logic [22:0] flash_mem_address;
logic [31:0] flash_mem_readdata;
logic [3:0] flash_mem_byteenable;

// s_mem 
logic [7:0] address;
logic [15:0] data, q;
logic wren;

// both
logic clk, rst_n;

//==============================//
//          Other Params        //
//==============================//
logic [31:0] sample;    // temp for flash_mem
integer cnt;            

//==============================//
//          Assignments         //
//==============================//
assign flash_mem_byteenable = 4'b1111;
assign clk = CLOCK_50;
assign rst_n = KEY[3];

assign flash_mem_write      = 1'b0;  // not writing, only reading
assign flash_mem_writedata  = 32'b0; // only reading
assign flash_mem_burstcount = 6'b1;

//==============================//
//     State Definitions        //
//==============================//
typedef enum {INIT, ADDRESS, READ_VALID, READ1, READ2, LOOP, DONE} state_def;
state_def state;

//==============================//
//        State Machine         //
//==============================//
always_ff @( posedge CLOCK_50 or negedge KEY[3]) begin : flash_state_machine
    if (!KEY[3]) begin
        state   <= INIT;
    end else begin
        case(state)
            INIT : begin
                cnt                 = 0;
                wren                = 1'b0;
                flash_mem_read      = 1'b0;
                flash_mem_address   = 23'b0;
                address             = 8'b0;
                state               <= ADDRESS;
            end // INIT

            ADDRESS : begin
                flash_mem_read = 1'b1; // read from the flash mem
                if (flash_mem_waitrequest == 1'b0) begin
                    state <= READ_VALID;
                end else begin
                    state <= ADDRESS;
                end
            end // ADDRESS

            READ_VALID : begin
                if (flash_mem_readdatavalid) begin // if the data read is valid, write to mem
                    flash_mem_read  = 1'b1;
                    state           <= READ1;       // read the first sample
                end else begin
                    state           <= READ_VALID; // wait until valid
                end
            end // READ_VALID
        
            READ1 : begin // read the lower bits first
                sample = flash_mem_readdata; // store the read data in sample
                data   = sample[15:0];       // write the first 16 bits of the read data to memory
                wren   = 1'b1;               // enable write
                state  = READ2;
            end // READ1

            READ2 : begin 
                data    = sample[31:16];    // read the higher bits
                wren    = 1'b1;             // keep writes enabled
                address = address + 8'b1;   // increment the address to store in the next slot
                state <= LOOP; 
            end // READ2

            LOOP : begin
                cnt = cnt + 1;
                wren    = 1'b0;         // disable writes to s_mem
                if (cnt < 128)  begin   // 256/2 since 256 samples of 16 bits but in 128 reads of 32 bits
                    address           = address + 8'b1;             // increment the write address for the next loop cycle
                    flash_mem_address = flash_mem_address + 23'b1;  // increment the flash read address for the next cycle
                    state <= ADDRESS;   // loop
                end else begin
                    state <= DONE;
                end
            end // LOOP

            DONE : begin
                wren = 1'b0;            // keep writes disabled
                flash_mem_read = 1'b0;
                state <= DONE;     
            end // DONE
            default: state <= DONE;
        endcase
    end
    
end
endmodule: flash_reader