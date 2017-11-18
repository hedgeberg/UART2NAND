#!/usr/bin/python
import serial
ser = 0

def read_data(address):
	global ser
	command_char = "R"
	dummy_payload = "0"*2112
	command = command_char + ":" + address + ":" + dummy_payload
	ser.write(command)
	k = []
	for i in xrange(len(command)):
		k.append(ser.read())
	return k


def main():
	global ser
	ser = serial.Serial('/dev/ttyUSB0')
	ser.baudrate = 115200
	print read_data(chr(0)*4 + chr(0))
	print read_data(chr(0)*2 + chr(1) + chr(0)*2)


main()