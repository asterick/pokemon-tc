#!/usr/bin/env python3
from mufom import Decoder
from struct import unpack

import argparse
parser = argparse.ArgumentParser()

parser.add_argument("input", help="IEEE-695 Object file to export")
parser.add_argument("-c", "--code", default="PMHB", help="4-letter game code")
parser.add_argument("-t", "--title", default="HomebrewPM", help="Game title")
parser.add_argument("-o", "--output", help="File to export to")

args = parser.parse_args()

def evaluate(exp):
	# We don't actually process anything here
	size, = list(filter(lambda x: isinstance(x, int), exp))
	return size

output = bytearray(b'\x00' * 0x21D0)
variables = {}
vectors = {}
section = None

with open(args.input, "rb") as fi:
	decoder = Decoder(fi)

	for command in decoder.commands():
		if command[0] == "AS":
			command, target, expression = command
			variables[target] = evaluate(expression)

			if target[0] == "P":
				section = target
			if target == "G":
				if 0 in vectors:
					raise Exception("Duplicate entry point specified")
				vectors[0] = evaluate(expression)
		elif command[0] in ["LD", "LR"]:
			command, sets = command[0], command[1:]

			for data in sets:
				data = data[::-1]
				
				if variables[section] == None:
					raise Exception("No section specified for load")
			
				address = variables[section]
			
				if address < 0x100:
					if address & 1:
						raise Exception("Misaligned interrupt vector (must be multiple of 2)")
					index = int(address / 2)
					
					for offset, vector in enumerate(unpack("<%iH" % (len(data) / 2), data)):
						if (index + offset) in vectors:
							raise Exception("IRQ %i already defined" % (index + offset))
						
						vectors[index + offset] = vector
				elif address >= 0x21D0:
					while len(output) < address:
						output += b'\x00'
			
					output[address:address+len(data)] = data
				else:
					raise Exception("Data mapped to reserved space")
			
				variables[section] += len(data)
		else:
			#print (command)
			pass

if not 0 in vectors:
	raise Exception("No entrypoint supplied")

# Put in all the header marks
output = bytearray(output)
output[0x2100:0x2102] = b'MN'
output[0x21BC:0x21BE] = b'2P'
output[0x21A4:0x21AC] = b'NINTENDO'
output[0x21AC:0x21B0] = bytearray("%-4s" % args.code[:4], "utf-8")
output[0x21B0:0x21BC] = bytearray("%-12s" % args.title[:12], "utf-8")

for irq in range(27):
	target = 0x2102 + (irq * 6)
	branch = b'\x9D\xC0\xF1\xFF'
	output[target:target+len(branch)] = branch

for irq, address in vectors.items():
	target = 0x2102 + (irq * 6)

	if target < 0x2102 or target >= 0x21A4:
		raise Exception('Illegal IRQ %02x' % irq)

	if (address & 0xFF8000) != 0: # Lower page
		# LD NB, bank(target)
		print("%04X" % address)
		branch = b'\xCE\xC4' + (address >> 15).to_bytes(1)
	else:
		branch = b''
	
	delta = (address - target + len(branch) - 2) & 0xFFFF
	branch += b'\xF3' + delta.to_bytes(2, byteorder='little')

	output[target:target+len(branch)] = branch

with open(args.output, "wb") as fo:
	fo.write(output)
