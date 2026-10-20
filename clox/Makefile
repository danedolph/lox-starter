# Builds every .c file in this folder into build/clox.
#   make          optimized build (what the cracked.guide workflow tests)
#   make debug    -O0 -g with AddressSanitizer and UBSan, into build/clox-debug
#   make clean
CC      ?= cc
CFLAGS  ?= -std=c99 -Wall -Wextra -Wno-unused-parameter
LDLIBS  := -lm
SRC     := $(wildcard *.c)
OUT     := build

.PHONY: all debug clean

all: $(OUT)/clox

$(OUT)/clox: $(SRC) $(wildcard *.h) | $(OUT)
	$(CC) $(CFLAGS) -O2 -o $@ $(SRC) $(LDLIBS)

debug: $(OUT)/clox-debug

$(OUT)/clox-debug: $(SRC) $(wildcard *.h) | $(OUT)
	$(CC) $(CFLAGS) -O0 -g -fsanitize=address,undefined -fno-omit-frame-pointer -o $@ $(SRC) $(LDLIBS)

$(OUT):
	mkdir -p $@

clean:
	rm -rf $(OUT)
