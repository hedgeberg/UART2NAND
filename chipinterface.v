module chipinterface(tx, rx, 
					rst_bnc, 
					we, ale, cle, ce, re, io, wp, io_drive_en);
	input rx, rst_bnc;
	output tx, wp;

	output ale, we, cle, ce, re;
	inout [7:0] io;
	tri [7:0] io;
	
	assign wp = 0; 
	
	wire rst;
    wire clk;
    design_1_wrapper clk_source(clk);
    
    
	debouncer dbnc(rst_bnc, rst, clk);
    output io_drive_en;
    wire [7:0] io_write;
    ts_buf #(8) nand_io_buffer(io_write, io, io_drive_en);
    
    
    
	uart_to_nand ni(rx, tx, 
					clk, rst, io_drive_en,
					we, ale, cle, ce, re, io, io_write);
endmodule // chipinterface