# vntd.drv makefile
#
# Copyright (c) 2022 leecher@dose.0wnz.at
#

!IFDEF USEBUILD

# If using BUILD.EXE, edit .\sources. if you want to add a new source
# file to this component.  This file merely indirects to the real make file
# that is shared by all the components of NT OS/2.

!INCLUDE $(NTMAKEENV)\makefile.def

!ELSE

.SUFFIXES:
.SUFFIXES: .c   .asm .h   .inc .obj .lst .sys .exe .com .map .sym .def .lib .dll .res .rc

SDK_INC_PATH=$(NTROOT)\public\sdk\inc

!ifdef INCLUDE
INCS    =
!else
INCS    = -I. -I..\inc -I..\..\inc -I$(SDK_INC_PATH)
!endif

# DEFINES = -DWOW -DDEBUG $(MVDMFLAGS)
DEFINES = -DWOW $(MVDMFLAGS) -DBUILDDLL

AOBJ    = -Ml -t $(DEFINES) $(INCS)

CW16    = -AS -G2sw -Os -W3 -Zp $(DEFINES) $(INCS)
CW16B   = $(CW16) -B1 c1l.exe -B2 c2l.exe -B3 c3l.exe

LINK    = /map /align:16

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

W16LIBS = ..\lib\snocrtd.lib

!IF "$(QFE_BUILD)" != "1"
CL16=cl16
!ELSE
CL16=cl
!ENDIF


.asm.obj:
    masm $(AOBJ) $*;

.asm.lst:
    masm $(AOBJ) -l $*,nul,$*.lst;


.c.obj:
    $(CL16) -c -nologo $(CW16) $*.c

.c.lst:
    $(CL16) -c -nologo $(CW16) -Fonul -Fc$*.lst $*.c


.def.lib:
    implib $*.lib $*.def

.map.sym:
    mapsym $*

.rc.res:
    rc16 $(INCS) -r $*.rc


all: vntd.drv vntd.sym
    -binplace vntd.drv vntd.sym vntd.map

clean: cleanup all

cleanup:
    if exist *.lrf del *.lrf
    if exist *.obj del *.obj
    if exist *.exe del *.exe
    if exist *.dll del *.dll
    if exist *.map del *.map
    if exist *.sym del *.sym
    if exist *.drv del *.drv
    if exist *.res del *.res

vntd.lrf: makefile
    echo libentry.obj+ >>vntd.lrf
    echo ints.obj >>vntd.lrf
    echo vntd.drv>>vntd.lrf
    echo vntd $(LINK)>>vntd.lrf
    echo ..\lib\libw.lib /nod>>vntd.lrf
    echo vntd;>>vntd.lrf

vntd.drv: ints.obj libentry.obj vntd.lrf vntd.def
    link16 @vntd.lrf;

!ENDIF
