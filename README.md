# UART2NAND
Interface for exposing raw NAND i/o over UART to enable pc-side modification.

Code is messy and lacks documentation but currently enables reading, flashing, and page-erasing of raw NAND using UART. 
See nand_example.py for a set of simple examples of how to interface software-side in a way that can be automated. 

Plan to rebase this tool from being a linear state machine Soon(tm). 

## INTERFACE
To interface with the NAND, set up a UART bridge between your PC and the FPGA, and send commands of the following format:

```
"[command byte]:[address]:[data]"
```

Where command byte is one of the following: 

 * "P" -- Program
 * "R" -- Read
 * "E" -- Erase

Address is 5 bytes, with the first 3 being row address and the last 2 being column address.

Data is 2112 bytes (2048 data bytes + 64 "spare" bytes)

Each field needs 1 byte between them. This byte will be ignored by the hardware, meaning the developer can use whatever character they choose for separation. I used ":", resulting in a command structure that looked like:

```
P:iiiii:xxxxxxxx....xxxx (dots fill in space so that there are 2112 x's)
```

In this example, we write to address 0x6969696969 ("iiiii") (not normally accessible on any SLC flash chip), and write the byte 0x78 2112 times. 

NOTE: A command will always result in the hardware spitting back out its command as a way to simplify design. In the case of read operations, the 2112 data bytes will overwrite the 2112 data bytes of the sent command. 

See nand_example.py if any of this doesn't make sense. 

## DISCLAIMER
I make no claims of stability and assume no responsibility for potential damages to devices that may be caused by this code, use at your own risk. 

## LICENSE
This project assumes an MIT License. If you need to use this in a way that works outside that license, feel free to contact me. 
