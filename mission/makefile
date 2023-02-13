# mission makefile

.SUFFIXES:
.SUFFIXES: .c   .asm .h   .inc .obj .lst .sys .exe .com .map .sym .def .lib .rc .res


!ifdef INCLUDE
INCS    =
!else
INCS    = -I..\inc -I..\..\inc
!endif

AOBJ    = -W2 -DSEGNAME=COMMAND $(INCS)

!if "$(NTDEBUG)"!="" && "$(NTDEBUG)"!="retail" && "$(NTDEBUG)" != "ntsdnodbg"
CW16    = -AS -G2sw -Os -W2 -Zp -DDEBUG $(INCS)
!else
CW16    = -AS -G2sw -Os -W2 -Zp $(INCS)
!endif

CW16L   = $(CW16) -B1 c1l.exe -B2 c2l.exe -B3 c3l.exe

LINK    = /map /stack:5120 /align:16

########## Path definition so we find 16 bit tools ##########
# Also works around stupid bug in RC 3.1 that doesn't allow rcpp.err to be
# in a directory that is greater than 128 chars down the path, even if
# rc 3.1 is running as an OS/2 app.

PATH    = $(_NTBINDIR)\private\mvdm\tools16;$(PATH)

!if "$(NTDEBUG)"!="" && "$(NTDEBUG)"!="retail" && "$(NTDEBUG)" != "ntsdnodbg"
AOBJ    = $(AOBJ) -Zd
CW16    = $(CW16) /Od /Oi /Zd
LINK    = $(LINK) /LI
!endif

W16LIBS = ..\lib\snocrt.lib ..\lib\libw.lib


.h.inc:
    h2inc -t $*.h -o $*.inc


.asm.obj:
    masm $(AOBJ) $*;

.asm.lst:
    masm $(AOBJ) -l $*,nul,$*.lst;


.c.obj:
    cl16 -c -nologo $(CW16) $*.c

.c.lst:
    cl16 -c -nologo $(CW16) -Fonul -Fc$*.lst $*.c


.def.lib:
    implib $*.lib $*.def

.map.sym:
    mapsym $*

.rc.res:
    rc16 -r -fo $@ $(INCS) $*.rc


all: mission.exe

clean: cleanup all

cleanup:
    if exist *.lrf del *.lrf
    if exist *.def del *.def
    if exist *.obj del *.obj
    if exist *.exe del *.exe
    if exist *.map del *.map
    if exist *.sym del *.sym
    if exist *.res del *.res

mission.lrf: makefile
    echo mission.obj          >mission.lrf
    echo mission $(LINK)      >>mission.lrf
    echo mission              >>mission.lrf
    echo $(W16LIBS) /nod     >>mission.lrf
    echo mission;        >>mission.lrf

mission.def: makefile
    echo name mission                        >mission.def
    echo exetype windows                   >>mission.def
    echo stub '..\bin\winstub.exe'         >>mission.def
    echo code preload moveable discardable >>mission.def
    echo data preload moveable multiple    >>mission.def
    echo heapsize 512                      >>mission.def


mission.exe: mission.obj mission.lrf mission.def 
    link16 @mission.lrf;

