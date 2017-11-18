# UART2NAND
Interface for exposing raw NAND i/o over UART to enable pc-side modification.

Code is messy and lacks documentation but currently enables reading of raw NAND using UART. 
See nand_example.py for a very simple and bad example of reading nand data via UART in a way that can be automated. 

Improvements planned in near future. Intend to get nand_script.py cleaner, then add nand.bin writing options. 
After that, will add page deleting and page writing. 

## LICENSE
I assume a "good faith" license on this code: it's free to do whatever you want with it so long as you don't attempt to claim credit for the contents of this repo and refer back to the parent repo so people can find the source code. I make no claims of stability and assume no responsibility for potential damages to devices that may be caused by this code, use at your own risk. 
