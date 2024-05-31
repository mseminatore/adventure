TARGET = adv.bin
SRC = adventure.asm
DEPS = stddefs.inc gamedefs.inc io.inc print.inc string.inc
ASM = as09
ASMFLAGS = -b
DSKFILE = ADV.DSK

all: $(TARGET)

$(TARGET): $(SRC) $(DEPS)
	as09 $(ASMFLAGS) -o $@ $(SRC)
	dsk_del $@ $(DSKFILE)
	dsk_add $@ $(DSKFILE)

new:
	dsk_new $(DSKFILE)
	
package: loader.bas
	dsk_add $^ $(DSKFILE) ascii basic

clean:
	rm $(TARGET) $(DSKFILE)
