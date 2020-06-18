# Use wine if installed
WINE := ${shell which wine}
TOOLCHAIN := $(dir $(lastword $(MAKEFILE_LIST)))
OBJECTS = $(patsubst %.c,%.obj,$(patsubst %.s,%.obj,$(SOURCES)))

LKFLAGS = -Ml -L$(TOOLCHAIN)LIB
CFLAGS 	= -Ml -O2 -I$(TOOLCHAIN)INCLUDE
ASFLAGS = -Ml -O -I$(TOOLCHAIN)INCLUDE

C88 = $(WINE) $(TOOLCHAIN)BIN/C88.EXE
EXPORT_FLAGS :=

ifdef GAME_CODE
EXPORT_FLAGS += -D GAME_CODE="$(GAME_CODE)"
endif

ifdef GAME_TITLE
EXPORT_FLAGS += -D GAME_TITLE="$(GAME_TITLE)"
endif

all: $(TARGET)

$(TARGET): $(OBJECTS)
	node $(TOOLCHAIN)src/ptc.js --export $@ $(LKFLAGS) $^

clean:
	rm -f $(TARGET) $(OBJECTS)

%.s: %.c
	$(C88) $(CFLAGS) -n -o $@ $<

%.obj: %.s $(TOOLCHAIN)src/table.js
	node $(TOOLCHAIN)src/ptc.js $(EXPORT_FLAGS) $(ASFLAGS) -a $< -o $@

$(TOOLCHAIN)src/table.js: $(TOOLCHAIN)tools/convert.py $(TOOLCHAIN)tools/s1c88.csv
	python3 $(TOOLCHAIN)tools/convert.py > $@

.phony: all clean
