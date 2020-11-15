module sound (CLOCK_50, CLOCK2_50, KEY,
         AUD_DACLRCK, AUD_ADCLRCK, AUD_BCLK,AUD_ADCDAT,
			FPGA_I2C_SDAT, FPGA_I2C_SCLK,AUD_DACDAT,AUD_XCK, SW);
			
input CLOCK_50,CLOCK2_50,AUD_DACLRCK, AUD_ADCLRCK, AUD_BCLK,AUD_ADCDAT;
input [3:0] KEY;
inout FPGA_I2C_SDAT;
output FPGA_I2C_SCLK,AUD_DACDAT,AUD_XCK;

// Define an enumerated type for our state machine

typedef enum {state_init, state_assert_address, state_readdatavalid, state_read_address_write_sample1,
				state_write_sample2, state_increment_count, state_done, state_wait_until_ready, state_send_sample, state_wait_for_accepted} state_type;

// signals that are used to communicate with the audio core

reg read_ready, write_ready, write_s;
reg [15:0] writedata_left, writedata_right;
reg [15:0] readdata_left, readdata_right;	
wire reset, read_s;

// some signals I will use in my always block

integer cnt;
state_type state;
reg signed [15:0] sample;

// instantiate the parts of the audio core. 

clock_generator my_clock_gen (CLOCK2_50, reset, AUD_XCK);
audio_and_video_config cfg (CLOCK_50, reset, FPGA_I2C_SDAT, FPGA_I2C_SCLK);
audio_codec codec (CLOCK_50,reset,read_s,write_s,writedata_left, writedata_right,AUD_ADCDAT,AUD_BCLK,AUD_ADCLRCK,AUD_DACLRCK,read_ready, write_ready,readdata_left, readdata_right,AUD_DACDAT);

// The audio core requires an active high reset signal

assign reset = ~(KEY[3]);

// we will never read from the microphone in this lab, so we might as well set read_s to 0.

assign read_s = 1'b0;

// The main state machine in the design.  The purpose of this state machien
// is to send samples to the audio core.  This machine will send 91 high samples
// followed by 91 low samples, and repeat.  It turns out that this square wave 
// will sound like a single tone when played.  In the lab, you will modify this
// to send the actual samples (which descirbe a waveform much more complex
// than just a square wave).

wire clk, resetb;

assign clk = CLOCK_50;
assign resetb = KEY[3];

wire            flash_mem_read;
wire            flash_mem_waitrequest;
wire    [22:0]  flash_mem_address;
wire    [31:0]  flash_mem_readdata;
wire            flash_mem_readdatavalid;
wire    [3:0]   flash_mem_byteenable;

flash flash_inst (
    .clk_clk                 (clk),
    .reset_reset_n           (resetb),
    .flash_mem_write         (1'b0),
    .flash_mem_burstcount    (1'b1),
    .flash_mem_waitrequest   (flash_mem_waitrequest),
    .flash_mem_read          (flash_mem_read),
    .flash_mem_address       (flash_mem_address),
    .flash_mem_writedata     (),
    .flash_mem_readdata      (flash_mem_readdata),
    .flash_mem_readdatavalid (flash_mem_readdatavalid),
    .flash_mem_byteenable    (flash_mem_byteenable)
);

assign flash_mem_byteenable = 4'b1111;


// the rest of your code goes here.  Don't forget to instantiate the on-chip memory
assign flash_mem_write = 1'b0;
assign flash_mem_writedata = 32'b0;

assign flash_mem_burstcount = 6'b000001;

reg [31:0] samplepair;

reg [7:0] address; 
reg [15:0] data, q;
reg wren;

s_memory2 u0(address, CLOCK_50, data, wren, q);

integer count;

integer samplenumber;
	
typedef enum {normal, fast, slow} playback;
playback mode;

input [9:0] SW;
	
always @(SW) begin
	case (SW) 
		10'b0000000010: mode = fast;
		10'b0000000100: mode = slow;
		default: mode = normal;
	endcase
end	
	
integer loopnumber;	
	
always_ff @(posedge CLOCK_50, posedge reset)
   if (reset == 1'b1) begin
         state <= state_init;
         write_s <= 1'b0;
   end else begin
      case (state)
		state_init: begin
			flash_mem_address = 23'b00000000000000000000000;
			flash_mem_read = 1'b0;
			address = 8'b00000000;
			wren = 1'b0;
			count = 0;
			write_s <= 1'b0;
			state <= state_assert_address;
		end // case state_init
			state_assert_address: begin
			flash_mem_read = 1'b1;
			state <= state_readdatavalid;
		end
		state_readdatavalid: begin
			if (flash_mem_readdatavalid == 1'b1) begin
				flash_mem_read = 1'b0;
				state <= state_read_address_write_sample1;
			end else begin
				state <= state_readdatavalid;
			end
		end
		state_read_address_write_sample1: begin
			samplepair = flash_mem_readdata;
			wren = 1'b1;
			data = samplepair[15:0];
			state <= state_write_sample2;
		end
		state_write_sample2: begin
			address = address + 1'b1;
			wren = 1'b1;
			data = samplepair[31:16];
			state <= state_increment_count;
		end
		state_increment_count: begin
			wren = 1'b0;
			count = count + 1;
			samplenumber = 1;
			loopnumber = 1;
			if (count < 1048576) begin
				flash_mem_address = flash_mem_address + 1'b1;
				address = address + 1'b1;
				state <= state_wait_until_ready;
			end else begin
				flash_mem_address = 23'b00000000000000000000000;
				flash_mem_read = 1'b0;
				address = 8'b00000000;
				count = 0;
				state <= state_wait_until_ready;
			end
		end
         state_wait_until_ready: begin
				 
				    // In this state, we set write_s to 0,
					 // and wait for write_ready to become 1.
					 // The write_ready signal will go 1 when the FIFOs
					 // are ready to accept new data.  We can't do anything
					 // until this signal goes to a 1.
					 
				write_s <= 1'b0;
                if (write_ready == 1'b1)  
	                 state <= state_send_sample;
				end // state_wait_until_ready				   
   
         state_send_sample: begin
				 
				    // Now that the core has indicated that it is ready to 
					 // accept a sample, send one.  In this case, our samples are
					 // calculated (rather than read from the flash memory)
					
					if (samplenumber == 1) begin
						sample = samplepair[15:0];
					end else begin
						sample = samplepair[31:16];
					end
					
					// divide sample by 64 to lower volume
					sample = sample/64;
					
					
                // send the sample to the core (it is added to the two FIFOs
                // as explained in the handout.  We need to be sure to send data
					 // to both the right and left queue.  Since we are only playing a
					 // mono sound (not stereo) we send the same sample to both FIFOs.
					 // You will do the same in your implementation in the final task.
					 
				    writedata_right <= sample;
				    writedata_left <= sample;
			       write_s <= 1'b1;  // indicate we are writing a value
                state <= state_wait_for_accepted;
				   end // state_send_sample
					
		       state_wait_for_accepted: begin

                // now we have to wait until the core has accepted
	             // the value. We will know this has happened when
	             // write_ready goes to 0.   Once it does, we can 
					 // go back to the top, set write_s to 0, and 
					 // wait until the core is ready for a new sample.
					 
				    if (write_ready == 1'b0) 
						if(samplenumber == 1) begin
							if (mode == slow) begin					// if mode == slow, samplenumber remains the same for 2 cycles, seen by loopnumber
								if (loopnumber == 1) begin
									loopnumber = 2;
									samplenumber = 1;
								end else begin
									loopnumber = 1;
									samplenumber = 2;
								end
								state <= state_wait_until_ready;
							end else begin
								samplenumber = 2;
								if (mode == normal) begin
									state <= state_wait_until_ready;
								end else if (mode == fast) begin
									state <= state_assert_address;
								end 
							end
						end else begin
							if (mode == slow) begin
								if (loopnumber == 1) begin
									loopnumber = 2;
									samplenumber = 2;
									state <= state_wait_until_ready;
								end else begin
									loopnumber = 1;
									samplenumber = 1;
									state <= state_assert_address;
								end
							end else begin
								state <= state_assert_address;
							end
						end
						
					end // state_wait_for_accepted
					
	          default: begin
				 
				    // should never happen, but good practice
					 
                state <= state_init;
					 
				 end // default
			endcase
     end  // if 

endmodule
