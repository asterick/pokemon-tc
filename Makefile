# This is just a test for my assembler sweet

TARGET = test/junk.out
SOURCES = $(shell find test -name "*.s") $(shell find test -name "*.c")

include pokemini.mk
