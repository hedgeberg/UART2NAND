module uart_to_nand(uart_rx, uart_tx, 
					clk, rst, io_drive_en,
					we, ale, cle, ce, re, rb, io, io_write); //rb2
	parameter CMD_SIZE = 2120; //1 + 5 + 2 + 2112 = 2120

	input uart_rx, clk, rst, rb;
	output uart_tx;
	(* mark_debug = "true" *) output we, ale, cle, ce, re;
	input[7:0] io;
	//"R:0000000000:<payload>"

	reg nand_io_ready;
	wire [7:0] cmd_rambus;
	tri [7:0] cmd_rambus;
	wire [11:0] nand_cnt_ram_addr;
	output io_drive_en;
	output [7:0] io_write;
	wire nand_cnt_ram_w_e, nand_comm_done;
	wire [7:0] nand_cnt_ram_out; 
	nand_controller nand_io(cmd_rambus, nand_cnt_ram_addr, nand_cnt_ram_r_e, nand_cnt_ram_w_e, nand_cnt_ram_out,
	                        cle, ce, re, ale, we, rb, io, io_write,
	                        nand_io_ready, clk, rst, io_drive_en, nand_comm_done);

	wire [11:0] cmd_out;
	reg cmd_up, cmd_set;
	uds_counter #(12, 4*1024) cmd_counter(cmd_up, 1'b0, cmd_set, 12'b0, cmd_out, clk);

	wire [7:0] rx_byte;
	wire uart_rx_new_byte;
	uart_in #(866) rx(uart_rx, rx_byte, clk, rst, uart_rx_new_byte);

	reg tx_ready;
	wire [7:0] tx_byte;
	wire uart_tx_done;
	uart_out #(866, 8) tx(tx_byte, tx_ready, rst, uart_tx, uart_tx_done, clk);


	reg cmd_r_e, cmd_w_e, ram_w_e;
	wire r_e;
	assign r_e = nand_cnt_ram_r_e | cmd_r_e;
	wire [11:0] cmd_addr;
	assign cmd_addr = cmd_out;
	reg [11:0] ram_addr;
	reg [7:0] rambus_write_line;
	//ts_buf #(8) rambus_write_buffer(rambus_write_line, cmd_rambus, ram_w_e); //rx_byte -> rambus_write_line = (rx_byte else nand_cnt_ram_out) //cmd_w_e -> ram_w_e = (cmd_w_e else nand_cnt_ram_w_e)
	simple_ram #(8, 12, 4*1024) cmd_store(rambus_write_line, cmd_rambus, 
										ram_addr, r_e, ram_w_e, clk);

	reg snd_latch_set, snd_latch_reset;
	sr_latch snd_byte_latch(cmd_rambus, tx_byte, clk, 
							snd_latch_set, snd_latch_reset);

	parameter init = 0, uart_rcv_wait = 1, uart_rcv_new_byte = 2, 
			  uart_snd_wait = 3, uart_snd_new_byte = 4, 
			  init_nand_io = 5, ram_request_byte = 6;

	reg [2:0] state;

	initial begin
		state = init;
	end

	always @(posedge clk) begin
		if(rst) state <= init;
		else case(state)
			init: state <= uart_rcv_wait;
			uart_rcv_wait: begin
				if(cmd_out == CMD_SIZE) state <= init_nand_io; 
				else if(uart_rx_new_byte) state <= uart_rcv_new_byte;
				else state <= uart_rcv_wait;
			end
			uart_rcv_new_byte: begin 
				state <= uart_rcv_wait;
			end
			init_nand_io: begin 
				if(nand_comm_done == 1) state <= ram_request_byte;
				else state <= init_nand_io;
			end
			uart_snd_wait: begin 
				if(uart_tx_done) begin
					if(cmd_out == CMD_SIZE) state <= init; 
					else state <= ram_request_byte;
				end
				else state <= uart_snd_wait;
			end
			ram_request_byte: begin 
				state <= uart_snd_new_byte;
			end 
			uart_snd_new_byte: begin 
				state <= uart_snd_wait;
			end
			default: state <= init;
		endcase
	end
	
	always @* begin
		if(state == init) snd_latch_reset = 1;
		else snd_latch_reset = 0;

		if(state == uart_snd_new_byte) snd_latch_set = 1;
		else snd_latch_set = 0;

		if(state == uart_rcv_new_byte) cmd_w_e = 1;
		else cmd_w_e = 0;

		if((state == ram_request_byte) || 
			(state == uart_snd_new_byte) ||
			(state == uart_snd_wait)) cmd_r_e = 1;
		else cmd_r_e = 0;

		if((state == uart_rcv_new_byte) || 
		   (state == uart_snd_new_byte)) cmd_up = 1;
		else cmd_up = 0;

		if((state == init) || (state == init_nand_io)) cmd_set = 1;
		else cmd_set = 0;

		/*
		if((state == ram_request_byte) || 
		   (state == uart_snd_new_byte) ||
		   (state == uart_snd_wait))
			tx_byte = cmd_rambus;
		else tx_byte = 0;
		*/

		if(state == uart_snd_wait) tx_ready = ~uart_tx_done;
		else tx_ready = 0;
		
		if(state == init_nand_io) nand_io_ready = 1;
		else nand_io_ready = 0;

		if(state == init_nand_io) ram_addr = nand_cnt_ram_addr;
		else ram_addr = cmd_addr;

		if(state == init_nand_io) rambus_write_line = nand_cnt_ram_out;
		else rambus_write_line = rx_byte;

		if(state == init_nand_io) ram_w_e = nand_cnt_ram_w_e;
		else ram_w_e = cmd_w_e;

	end

endmodule 