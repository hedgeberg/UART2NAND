module chipinterface(tx, rx, clk, rst_bnc, we, ale, cle, ce, re, io, io_drive_en);
	input rx, clk, rst_bnc;
	output tx;

	output ale, we, cle, ce, re;
	inout [7:0] io;
	
	wire rst;

	debouncer dbnc(rst_bnc, rst, clk);
    
    output io_drive_en;
	uart_to_nand ni(rx, tx, clk, rst, we, ale, cle, ce, re, io, io_drive_en);
endmodule // chipinterface