#!/usr/bin/python
import serial
import struct
ser = 0

def prog_page(address, data):
	global ser
	command_char = "P"
	dummy_payload = "x"*2112
	command = bytes((command_char + ":" + address + ":"), 'ascii') + data
	ser.write(command)
	for i in range(len(command)): 
		ser.read()
	return 1

def erase_page(address):
	global ser
	command_char = "E"
	dummy_payload = "0"*2112
	command = command_char + ":" + address + ":" + dummy_payload
	ser.write(bytes(command, 'ascii'))
	k = bytes([])
	for i in range(len(command)):
		k += ser.read()
	return 1

def read_data(address):
	global ser
	command_char = "R"
	dummy_payload = "0"*2112
	command = command_char + ":" + address + ":" + dummy_payload
	ser.write(bytes(command, 'ascii'))
	k = bytes([])
	for i in range(len(command)):
		k += ser.read()
	return k[8:]


def main():
	global ser
	ser = serial.Serial('/dev/ttyUSB0')
	ser.baudrate = 115200
	addr = chr(0)*2 + chr(2) + chr(0)*2
	data = read_data(addr)
	erase_page(addr)
	prog_page(addr, data)
	#now do whatever you want here. 
	print("done")
	return

if __name__ == "__main__":
	main()


#{dp1:dp2:dp3:dp4:sa1:sa2:sa3:sa4:padding} -- 4096-byte aligned areas

