#
# This makefile builds the application:
# - use perl script to convert the AES & VDI macros to assembly code
# - at the same time all sources are concatenated into a single file
#   (because VASM does not have proper suppport for linking object files)
# - assemble the sources into an executable in TOS format

SRC_DIR_F = src_paint
SRC_FILES_F = $(SRC_DIR_F)/fa.asm \
              $(SRC_DIR_F)/fg.asm \
              $(SRC_DIR_F)/fh.asm \
              $(SRC_DIR_F)/fm.asm \
              $(SRC_DIR_F)/fn.asm \
              $(SRC_DIR_F)/fo.asm

SRC_DIR_E = src_editor
SRC_FILES_E = $(SRC_DIR_E)/e.asm \
              $(SRC_DIR_E)/ei.asm \
              $(SRC_DIR_E)/es.asm

all: f.prg e.tos

tmp_f.asm: $(SRC_FILES_F) $(SRC_DIR_F)/*.s asm_macro.pl
	perl asm_macro.pl $(SRC_FILES_F) > tmp_f.asm

tmp_e.asm: $(SRC_FILES_E)
	cat $(SRC_FILES_E) | egrep -v '^ *END *$$' > tmp_e.asm

f.prg: tmp_f.asm
	vasmm68k_mot -pic -maxerrors=10 -Ftos -I$(SRC_DIR_F) -o f.prg -L f.lst tmp_f.asm

e.tos: tmp_e.asm
	vasmm68k_mot -Ftos -I$(SRC_DIR_E) -o e.tos -L e.lst tmp_e.asm

clean:
	rm -f tmp_f.asm f.prg f.lst
	rm -f tmp_e.asm e.tos e.lst
