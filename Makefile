#
# This makefile builds the application:
# - use perl script to convert the AES & VDI macros to assembly code
# - at the same time all sources are concatenated into a single file
#   (because VASM does not have proper suppport for linking object files)
# - assemble the sources into an executable in TOS format

all: f.prg

tmp.asm: src/*.asm src/*.s asm_macro.pl
	perl asm_macro.pl src/*.asm > tmp.asm

f.prg: tmp.asm
	vasmm68k_mot -maxerrors=10 -Ftos -Isrc -o f.prg -L f.lst tmp.asm

clean:
	rm -f tmp.asm f.prg f.lst
