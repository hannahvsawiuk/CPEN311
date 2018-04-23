module chipmunks(input CLOCK_50, input CLOCK2_50, input [3:0] KEY, input [9:0] SW,
                 input AUD_DACLRCK, input AUD_ADCLRCK, input AUD_BCLK, input AUD_ADCDAT,
                 inout FPGA_I2C_SDAT, output FPGA_I2C_SCLK, output AUD_DACDAT, output AUD_XCK,
                 output [6:0] HEX0, output [6:0] HEX1, output [6:0] HEX2,
                 output [6:0] HEX3, output [6:0] HEX4, output [6:0] HEX5,
                 output [9:0] LEDR);
			
// signals that are used to communicate with the audio core
// DO NOT alter these -- we will use them to test your design

reg read_ready, write_ready, write_s;
reg [15:0] writedata_left, writedata_right;
reg [15:0] readdata_left, readdata_right;	
wire reset, read_s;

// signals that are used to communicate with the flash core
// DO NOT alter these -- we will use them to test your design

reg flash_mem_read;
reg flash_mem_waitrequest;
reg [22:0] flash_mem_address;
reg [31:0] flash_mem_readdata;
reg flash_mem_readdatavalid;
reg [3:0] flash_mem_byteenable;
reg rst_n, clk;

// DO NOT alter the instance names or port names below -- we will use them to test your design

clock_generator my_clock_gen(CLOCK2_50, reset, AUD_XCK);
audio_and_video_config cfg(CLOCK_50, reset, FPGA_I2C_SDAT, FPGA_I2C_SCLK);
audio_codec codec(CLOCK_50,reset,read_s,write_s,writedata_left, writedata_right,AUD_ADCDAT,AUD_BCLK,AUD_ADCLRCK,AUD_DACLRCK,read_ready, write_ready,readdata_left, readdata_right,AUD_DACDAT);
flash flash_inst(.clk_clk(clk), .reset_reset_n(rst_n), .flash_mem_write(1'b0), .flash_mem_burstcount(1'b1),
                 .flash_mem_waitrequest(flash_mem_waitrequest), .flash_mem_read(flash_mem_read), .flash_mem_address(flash_mem_address),
                 .flash_mem_readdata(flash_mem_readdata), .flash_mem_readdatavalid(flash_mem_readdatavalid), .flash_mem_byteenable(flash_mem_byteenable), .flash_mem_writedata());

// your code for the rest of this task here
//==============================//
//          Other Params        //
//==============================//
logic hl;               // indicates if high or low bits
logic [31:0] sample;    // temp for flash_mem
logic signed [15:0] subsample;
logic signed [15:0] divisor;
logic [1:0] speed;
integer cnt;


//==============================//
//          Assignments         //
//==============================//
assign flash_mem_byteenable = 4'b1111;
assign clk                  = CLOCK_50;
assign rst_n                = KEY[3];
assign reset                = ~(KEY[3]);
assign read_s               = 1'b0;
assign divisor              = 16'd64;
assign speed                = SW[1:0];

//==============================//
//     State Definitions        //
//==============================//
typedef enum {ADDRESS, READ_VALID, WAIT_READY, SEND_SAMPLE, WAIT_ACCEPT, LOOP} state_def;
state_def state;

//==============================//
//        State Machine         //
//==============================//
always_ff @( posedge CLOCK_50 or negedge rst_n) begin : flash_state_machine
    if (!rst_n) begin
        flash_mem_read      = 1'b1;
        flash_mem_address   = 23'b0;
        hl                  = 1'b0;
        cnt                 = 0;
        state               <= ADDRESS;
    end else begin
        case(state)
            ADDRESS : begin
                if (flash_mem_waitrequest == 1'b0) begin
                    state <= READ_VALID;
                end else begin
                    state <= ADDRESS;
                end
            end // ADDRESS

            READ_VALID : begin
                if (flash_mem_readdatavalid) begin // if the data read is valid, write to mem
                    state           <= WAIT_READY;       // read the first sample
                end else begin
                    state           <= READ_VALID; // wait until valid
                end
            end // READ_VALID

            WAIT_READY : begin // read the lower bits first
                sample          = flash_mem_readdata; // store the read data in sample
                write_s         <= 1'b0;
                if (write_ready) begin
                    state <= SEND_SAMPLE;
                end else begin
                    state <= WAIT_READY;
                end
            end // WAIT_READY

            SEND_SAMPLE: begin 
                flash_mem_read  = 1'b0;                 // disables reads once the temp variable 'sample' stores flash_mem_readdata
                if (hl) begin                           
                    subsample          = sample[31:16]; // read high bits
                end else begin                          
                    subsample          = sample[15:0];  // read the low bits
                end
                writedata_right    = subsample/divisor;   
                writedata_left     = subsample/divisor;
                write_s            <= 1'b1;
                cnt                = cnt + 1;
                state              <= WAIT_ACCEPT; 
            end // SEND_SAMPLE

            WAIT_ACCEPT: begin
                if (write_ready == 1'b0) begin
                    if (!hl) begin // low
                        if (speed == 2'b01) begin
                            hl     = 1'b0;
                            state <= LOOP;
                        end else if (speed == 2'b0 || speed == 2'b11) begin
                            hl = 1'b1;
                            state <= WAIT_READY;
                        end else begin
                            if (cnt < 2) begin
                                state <= WAIT_READY;
                            end else begin
                                hl = 1'b1;
                                cnt = 0;
                                state <= WAIT_READY;
                            end
                        end
                    end else begin // high
                        if (speed == 2'b10) begin
                            if (cnt < 2) begin
                                state <= WAIT_READY;
                            end else begin
                                state <= LOOP;
                            end
                        end else begin
                            state <= LOOP;
                        end
                    end
			    end else begin
                    state <= WAIT_ACCEPT;
                end
            end // WAIT_ACCEPT

            LOOP : begin
                flash_mem_read = 1'b1;
                cnt            = 0;
                hl             = 1'b0;
                if (flash_mem_address < 23'h100000)  begin              // 0x200000 samples
                    write_s             <= 1'b0;
                    flash_mem_address   = flash_mem_address + 23'b1;    // increment the flash read address for the next cycle
                end else begin
                    flash_mem_address   = 23'b0;
                end
                state <= ADDRESS;   // loop
            end // LOOP
            default: state <= ADDRESS;
        endcase
    end
end

endmodule: chipmunks
