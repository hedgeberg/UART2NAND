`define CMD_SIZE 7

module nand_controller(ram_in, ram_addr, ram_re, //ram_we, ram_out //ram signals 
						cle, ce, re, ale, we, rb, io, io_write,//r_b, //nand signals
						ready, clk, rst, io_drive_en); //control signals

	input  [7:0] ram_in;
	inout  [7:0] io;
	tri    [7:0] io;
	//output [7:0] ram_out;
	input ready;
	input clk, rst, rb;
	output [11:0] ram_addr;
	output reg ram_re; //, ram_we;
	output reg ce, cle, re, ale, we;

	reg [7:0] cmd_reg [0:6];

	reg ram_addr_up, ram_addr_set;
	reg [11:0] ram_addr_in;
	uds_counter #(12) addr_counter(ram_addr_up, 1'b0, ram_addr_set, 
							 ram_addr_in, ram_addr, clk);


	reg dly_cnt_en, dly_cnt_clr;
	wire [7:0] dly_cnt;
	up_counter delay_counter(dly_cnt_en, dly_cnt_clr, dly_cnt, clk);

	reg cmd_pos_up, cmd_pos_set;
	reg [7:0] cmd_pos_in;
	wire [7:0] cmd_pos;
	uds_counter cmd_pos_counter(cmd_pos_up, 1'b0, cmd_pos_set, 
								cmd_pos_in, cmd_pos, clk);
	
    output reg io_drive_en; 
	output reg [7:0] io_write;
	//ts_buf #(8) io_ts_buf(io_write, io, io_drive_en);

	//assign io = (io_drive_en) ? io_write : 8'bzzzzzzzz;
	
	reg [3:0] terminal_pos;
	reg [3:0] cyc_time;
	reg [4:0] state; 
	reg [4:0] num_read_cycles;
	//output logic
	//LUT for command bytes 1 & 2
	//fix cmd_pos references


	parameter init = 0, wait_for_ready = 1, ram_req_cmd_read = 2,
			  read_cmd_to_reg = 3, cmd_cyc_1_0 = 4, cmd_cyc_1_1 = 5,
			  cmd_cyc_1_2 = 6, addr_cyc_lo = 7, addr_cyc_hi = 8, 
			  cmd_cyc_2_pre = 9, cmd_cyc_2_0 = 10, cmd_cyc_2_1 = 11, 
			  cmd_cyc_2_2 = 12, rb_wait_lo = 13, rb_wait_hi = 14,
			  read_cycle_hi = 15, read_cycle_lo = 16, end_latch = 17;

	initial begin 
		state <= init;
		num_read_cycles <= 0;
		cyc_time <= 3'b0;
	end 

	always @(posedge clk) begin 
		if(rst) state <= init;
		else case(state)
			init: begin 
				state <= wait_for_ready;
				cyc_time <= 3'b0;
			end 
			wait_for_ready: begin 
				if(ready) state <= ram_req_cmd_read;
				else state <= wait_for_ready;
			end 
			ram_req_cmd_read: begin 
				if(ram_addr >= `CMD_SIZE) state <= cmd_cyc_1_0;
				else state <= read_cmd_to_reg;
			end 
			read_cmd_to_reg: begin 
				state <= ram_req_cmd_read;
				cmd_reg[ram_addr] <= ram_in; 
			end
			cmd_cyc_1_0: state <= cmd_cyc_1_1;
			cmd_cyc_1_1: begin 
				if (cyc_time >= 7) begin 
					state <= cmd_cyc_1_2;
					cyc_time <= 0;
				end 
				else cyc_time <= cyc_time + 1;
			end 
			cmd_cyc_1_2: begin 
				if(cyc_time >= 2) begin 
					state <= addr_cyc_hi;
					cyc_time <= 0;
				end 
				else cyc_time <= cyc_time + 1; 
			end 
			addr_cyc_lo: begin 
				if(dly_cnt >= 15) begin 
					if(cmd_pos >= (terminal_pos - 1)) state <= cmd_cyc_2_pre;
					else state <= addr_cyc_hi;
				end 
				else state <= addr_cyc_lo;
			end 
			addr_cyc_hi: begin
				if(cmd_pos >= terminal_pos) state <= cmd_cyc_2_pre;
				else if(dly_cnt >= 15) state <= addr_cyc_lo;
				else state <= addr_cyc_hi;
			end 
			cmd_cyc_2_pre: begin 
				if(dly_cnt >= 100) state <= cmd_cyc_2_0;
				else state <= cmd_cyc_2_pre;
			end 
			cmd_cyc_2_0: state <= cmd_cyc_2_1;
			cmd_cyc_2_1: begin 
				if(cyc_time >= 7) begin 
					state <= cmd_cyc_2_2;
					cyc_time <= 0;
				end 
				else cyc_time <= cyc_time + 1; 
			end 
			cmd_cyc_2_2: begin 
				if(cyc_time >= 2) begin 
					state <= rb_wait_lo;
					cyc_time <= 0;
				end 
				else cyc_time <= cyc_time + 1;
			end
			rb_wait_lo: begin 
				if(rb == 0) state <= rb_wait_hi;
				else state <= rb_wait_lo;
			end 
			rb_wait_hi: begin 
				if(rb == 1) state <= read_cycle_hi;
				else state <= rb_wait_hi;
			end
			read_cycle_hi: begin 
				if(cyc_time > 10) begin 
					state <= read_cycle_lo;
					cyc_time <= 0;
				end 
				else begin 
					state <= read_cycle_hi;
					cyc_time <= cyc_time + 1;
				end
			end 
			read_cycle_lo: begin 
				if(cyc_time > 10) begin 
					cyc_time <= 0;
					if(num_read_cycles > 20) state <= end_latch; 
					else begin 
						state <= read_cycle_hi;
						num_read_cycles <= num_read_cycles + 1;
					end
				end 
				else begin 
					state <= read_cycle_lo;
					cyc_time <= cyc_time + 1;
				end
			end
			end_latch: state <= end_latch;
			//control a LUT for the different commands
			//branch based off r/w vs d
			//command cycle 1
			//5 address cycles
			//command cycle 2
			default: state <= init;
		endcase // state
	end 

	wire [7:0] curr_cmd_val;
	assign curr_cmd_val = cmd_reg[cmd_pos];

	//output logic 
	always @* begin 
		if((state == ram_req_cmd_read) || 
		   (state == read_cmd_to_reg)) ram_re = 1;
		else ram_re = 0;
		
		if((cmd_cyc_1_0 <= state) && 
		   (state <= cmd_cyc_2_2)) io_drive_en = 1;
		else io_drive_en = 0;

		if((cmd_cyc_1_0 <= state) && 
		   (state <= cmd_cyc_1_2)) io_write = 8'h00;
		else if((cmd_cyc_2_0 <= state) && 
		   (state <= cmd_cyc_2_2)) io_write = 8'h30;
		else if((addr_cyc_lo <= state) && 
		   (state <= addr_cyc_hi)) io_write = 8'h00; //curr_cmd_val;
		else io_write = 8'h00;
		
		if(state == read_cmd_to_reg) ram_addr_up = 1;
		else ram_addr_up = 0;
		
		if(state == init) ram_addr_set = 1;
		else ram_addr_set = 0;

		ram_addr_in = 12'h000;

		if((addr_cyc_lo <= state) && 
		   (state <= cmd_cyc_2_pre)) dly_cnt_en = 1;
		else dly_cnt_en = 0;

		if(state == init) dly_cnt_clr = 1;
		else if((state == addr_cyc_lo) && (dly_cnt == 15)) dly_cnt_clr = 1;
		else if((state == addr_cyc_hi) && (dly_cnt == 15)) dly_cnt_clr = 1;
		else dly_cnt_clr = 0;

		if((state == addr_cyc_lo) && (dly_cnt == 15)) cmd_pos_up = 1;
		else cmd_pos_up = 0;

		if(state == init) cmd_pos_set = 1;
		else cmd_pos_set = 0;

		cmd_pos_in = 2;

		if(((cmd_cyc_1_0 <= state) && (state <= cmd_cyc_1_2)) || 
		   ((cmd_cyc_2_0 <= state) && (state <= cmd_cyc_2_2))) cle = 1;
		else cle = 0;

		if(state > read_cmd_to_reg) ce = 0;
		else ce = 1; 

		if(state == read_cycle_lo) re = 0;
		else re = 1;

		if((cmd_cyc_1_2 < state) && (state < cmd_cyc_2_pre)) ale = 1;
		else ale = 0; 

		if(state == addr_cyc_lo) we = 0;
		else if(state == cmd_cyc_1_1) we = 0;
		else if(state == cmd_cyc_2_1) we = 0;
		else we = 1;

		terminal_pos = `CMD_SIZE; 

		//ram_we


	end

endmodule