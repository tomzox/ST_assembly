#
# This makefile builds the application:
# - use perl script to convert the AES & VDI macros to assembly code
# - at the same time all sources are concatenated into a single file
#   (because VASM does not have proper suppport for linking object files)
# - assemble the sources into an executable in TOS format

SRC_FILES_E = src_editor/e.asm src_editor/ei.asm src_editor/es.asm

all: f.prg e.tos

tmp_f.asm: src/*.asm src/*.s asm_macro.pl
	perl asm_macro.pl src/*.asm > tmp_f.asm

tmp_e.asm: $(SRC_FILES_E)
	cat $(SRC_FILES_E) | egrep -v '^ *END *$$' > tmp_e.asm

f.prg: tmp_f.asm
	vasmm68k_mot -pic -maxerrors=10 -Ftos -Isrc -o f.prg -L f.lst tmp_f.asm

e.tos: tmp_e.asm
	vasmm68k_mot -Ftos -Isrc_editor -o e.tos -L e.lst tmp_e.asm

clean:
	rm -f tmp_f.asm f.prg f.lst
	rm -f tmp_e.asm e.tos e.lst
