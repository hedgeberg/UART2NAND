#!/usr/bin/python
import serial
import struct
ser = 0

def erase_page(address):
	global ser
	command_char = "E"
	dummy_payload = "0"*2112
	command = command_char + ":" + address + "00" + ":" + dummy_payload
	ser.write(command)
	return

def read_data(address):
	global ser
	command_char = "R"
	dummy_payload = "0"*2112
	command = command_char + ":" + address + ":" + dummy_payload
	ser.write(command)
	k = ""
	for i in xrange(len(command)):
		k += ser.read()

	return k


def main():
	global ser
	ser = serial.Serial('/dev/ttyUSB0')
	ser.baudrate = 115200
	addr = chr(0)*2 + chr(2)
	erase_page(addr)
	print "done"

	#with open("./nand_dump.bin", "wb") as dumpfile:
	#	for i in xrange(0x1D):
	#		print ".",
	#		if ((i % 16) == 0 ):
	#			print i
	#		addr = struct.pack("BBBBB", 0, 0, i, 0, 0) 
	#		k = read_data(addr)
	#		dumpfile.write(k[8:])
	#		dumpfile.write("\0"*(4096-len(k[8:])))
	
	return

if __name__ == "__main__":
	main()


#{dp1:dp2:dp3:dp4:sa1:sa2:sa3:sa4:padding} -- 4096-byte aligned areas

