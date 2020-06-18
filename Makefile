# This is just a test for my assembler sweet

GAME_CODE = TEST
GAME_TITLE = TestRom
TARGET = test/junk.min
SOURCES = $(shell find test -name "*.s") $(shell find test -name "*.c")

include pokemini.mk
