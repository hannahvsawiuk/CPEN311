module flash_reader_task5( 
 CLOCK_50, 
 KEY);

input CLOCK_50;
input [3:0] KEY;

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

typedef enum {state_init, state_assert_address, state_readdatavalid, state_read_address_write_sample1,
				state_write_sample2, state_increment_count, state_done} state_type;
state_type state;

reg [31:0] sample;

reg [7:0] address; 
reg [15:0] data, q;
reg wren;

s_memory2 u0(address, CLOCK_50, data, wren, q);

integer count;

always_ff @(posedge CLOCK_50, negedge KEY[3])
	if (KEY[3] == 0) begin
		state <= state_init;
	end else
	case (state)
		state_init: begin
			flash_mem_address = 23'b00000000000000000000000;
			flash_mem_read = 1'b0;
			address = 8'b00000000;
			wren = 1'b0;
			count = 0;
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
			sample = flash_mem_readdata;
			wren = 1'b1;
			data = sample[15:0];
			state <= state_write_sample2;
		end
		state_write_sample2: begin
			address = address + 1'b1;
			wren = 1'b1;
			data = sample[31:16];
			state <= state_increment_count;
		end
		state_increment_count: begin
			wren = 1'b0;
			count = count + 1;
			if (count < 1048576) begin
				flash_mem_address = flash_mem_address + 1'b1;
				address = address + 1'b1;
				state <= state_assert_address;
			end else begin
				flash_mem_address = 23'b00000000000000000000000;
				flash_mem_read = 1'b0;
				address = 8'b00000000;
				wren = 1'b0;
				count = 0;
				state <= state_assert_address;
			end
		end
	endcase // case
	
endmodule