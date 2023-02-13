PATH    = $(_NTBINDIR)\private\mvdm\tools16;$(PATH)

.SUFFIXES:
.SUFFIXES: .asm .inc .obj .lst .exe .com .map .sym

SDK_INC_PATH=$(NTROOT)\public\sdk\inc

MASM = ml
AINC = -I. -I..\inc -I..\..\inc -I$(SDK_INC_PATH)
AFLAGS = /omf /AT /Zm /c


LFLAGS = /TINY
LIB = 

RELOC = reloc

# dependencies

all: vntd.com

vntd.com : 
        $(MASM) $(AFLAGS) $(AINC) $*.asm
        link16 $(LFLAGS) $*,,,$(LIB);
        del $*.obj
        del $*.map
