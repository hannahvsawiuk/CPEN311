module music(input CLOCK_50, input CLOCK2_50, input [3:0] KEY, input [9:0] SW,
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

assign clk = CLOCK_50;
assign rst_n = KEY[3];

assign reset = ~(KEY[3]);

// DO NOT alter the instance names or port names below -- we will use them to test your design

clock_generator my_clock_gen(CLOCK2_50, reset, AUD_XCK);
audio_and_video_config cfg(CLOCK_50, reset, FPGA_I2C_SDAT, FPGA_I2C_SCLK);
audio_codec codec(CLOCK_50,reset,read_s,write_s,writedata_left, writedata_right,AUD_ADCDAT,AUD_BCLK,AUD_ADCLRCK,AUD_DACLRCK,read_ready, write_ready,readdata_left, readdata_right,AUD_DACDAT);
flash flash_inst(.clk_clk(clk), .reset_reset_n(rst_n), .flash_mem_write(1'b0), .flash_mem_burstcount(1'b1),
                 .flash_mem_waitrequest(flash_mem_waitrequest), .flash_mem_read(flash_mem_read), .flash_mem_address(flash_mem_address),
                 .flash_mem_readdata(flash_mem_readdata), .flash_mem_readdatavalid(flash_mem_readdatavalid), .flash_mem_byteenable(flash_mem_byteenable), .flash_mem_writedata());

// your code for the rest of this task here


assign flash_mem_byteenable = 4'b1111;
// assign flash_mem_write = 0;
// assign flash_mem_burstcount = 1;

logic [31:0] flash_sample;
logic signed [15:0] sound_sample;
logic signed [15:0] divisor;

assign divisor = 64;
logic low;
// integer cnt;
// logic [7:0] samples_addr;

assign read_s = 1'b0;

typedef enum {WAIT_REQ, READ, WAIT_SOUND, SEND_SOUND, SOUND_ACCEPT, NEXT_ADDR} states;
states state;

always_ff@(posedge clk or negedge rst_n) begin : read_flash_fsm
    if (~rst_n)
    begin
        flash_mem_read = 1;
        flash_mem_address = 0;
        low = 1;
        state <= WAIT_REQ;
    end
    else begin
        case(state)
            
            WAIT_REQ: begin
                        // flash_mem_read = 1;
                        if (flash_mem_waitrequest == 0)
                            state <= READ;
                        else
                            state <= WAIT_REQ;
                      end
            
            READ: begin
                    if (flash_mem_readdatavalid)
                    begin
                        // flash_sample = flash_mem_readdata;
                        // flash_mem_read <= 0;
                        // low = 1;
                        state <= WAIT_SOUND;
                    end 
                    else begin
                        state <= READ;
                    end
                  end
            
            WAIT_SOUND: begin
                            flash_sample = flash_mem_readdata;
                            write_s <= 0;
                            // flash_mem_read <= 0;
                            if (write_ready == 0)
                                state <= SEND_SOUND;
                            else
                                state <= WAIT_SOUND;
                        end
            
            SEND_SOUND: begin
                            flash_mem_read <= 0;
                            if (low)
                            begin
                                sound_sample = flash_sample[15:0];
                            end
                            else begin
                                sound_sample = flash_sample[31:16];
                            end
                            writedata_right = sound_sample/divisor;
                            writedata_left = sound_sample/divisor;
                            write_s <= 1;
                            state <= SOUND_ACCEPT;
                        end
            
            SOUND_ACCEPT: begin
                              if(write_ready == 0)
                              begin
                                if(low)
                                begin
                                    low = 0;
                                    state <= WAIT_SOUND;
                                end
                                else
                                begin
                                    state <= NEXT_ADDR;
                                end
                              end
                              else begin
                                state <= SOUND_ACCEPT;
                              end
                          end

            NEXT_ADDR: begin
                         write_s <= 0;
                         flash_mem_read = 1;
                         low = 1;
                         if (flash_mem_address < 23'h100000)
                         begin
                             flash_mem_address = flash_mem_address + 1;
                         end
                         else
                         begin
                            flash_mem_address = 0;
                         end
                        state <= WAIT_REQ;
                       end

            default: state <= WAIT_REQ;
        endcase
    end
end

endmodule: music
