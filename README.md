# Mission Chameleon NTVDM loader

## The problem
The game [Mission Chameleon aka. Antz Attack](https://www.old-games.ru/game/download/3426.html) 
has an unusual architecture. It is in fact a DOS-Game, but for SFX, Music and 
Networking, it is using a Windows backend with which it communicates via a 
VXD-driver called VNTD.386.
The driver basically takes Window Messages to a queue and passes them on to 
the Windows application and vice versa. As the VXD driver architecture is only
supported on Win9x, this game doesn't work on Windows NT based operating 
systems.
This project injects itself into to call chain for the games parts and 
loads a VDD driver that emulates the VXD, but on Windows NT, so that the game
also loads on NTVDM. I don't claim that it is playable well there due to 
performance, but I think, this project serves as a good example on how to port 
a VXD driver to NTVDM.

## Installation
The components needed depend on the Windows Version that you are trying to
run this on. The reason for it is, that the game requires to use VESA
graphics and Microsoft's native NTVDM on 32bit-Windows only supports it 
directly via the graphics adapter BIOS in fullscreen mode, but as we know
that fullscreen mode broke starting with Windows Vista, it may need to be
emulated.
VESA mode is however partly supported on latest NTVDMx64, that's why this
is not an issue on 64bit Windows using [NTVDMx64](https://github.com/leecher1337/ntvdmx64).
On the other hand, performance is better when using direct Video Hardware
support.
For emulating VESA on NTVDM on x86 in windowed mode, [SolVBE](https://solhsa.com/solvbe.html)
has been created, so SolVBE package also gets shipped with the binary
distribution and installed, if necessary.
This leads to the following compatibility matrix for NT-based Windows 
versions:

Windows Version       | SolVBE needed 
----------------------|--------------
Windows NT 4.0 32bit  | *1)
Windows 2000   32bit  | *1)
Windows XP     32bit  | *1)
Windows Vista  32bit  | *2)
Windows 7      32bit  | *2)
Windows 8      32bit  | Yes
Windows 10     32bit  | Yes
Windows NT4-11 64bit  | No

*1) If your video card supports VESA directly, you probably won't need it, 
    otherwise yes.
*2) If you are running an XPDM display driver or standard VGA driver or 
    using [fullscrswitch](http://www.columbia.edu/~em36/wpdos/windowsseven.html), 
    then probably not, otherwise yes

Be aware that when using SolVBE, you also need to copy the modified as.pif,
as it has to contain the information that the AS.EXE DOS application should 
NOT go to fullscreen mode, as this would result in an error message.

Now that you know the basics, you can just use the install.bat, that should
take care about this, so installation is:

1) Install Mission Chameleon on the targe machine, preferably in C:\MISSION
2) Run "install.bat" from the Release package. If you installed it to 
   another directory than C:\MISSION, run install.bat from an elevated 
   command prompt (admin rights) and pass the appropriate directory to it
   as a commandline parameter
3) If you are being asked about whether to install SolVBE or not, decide 
   according to the instruction on whether you need it or not.

The installer also installs the missing library WING32.DLL to the SysWOW64
directory, as the Menu wouldn't work without it.

To remove the patch, call uninstall.bat 

## Known limitations
1) When using in a combination that is not using fullscreen VESA graphics,
   it may be very slow. Not much can be done here.
2) When using with NTVDMx64, there may be a race condition that causes 
   the sound and music to not work. So you may need to try a few times 
   until it works.
3) On NTVDMx64, you currently cannot return to the 32bit menu application 
   after quitting the DOS part, you will always be asked to insert the CD
   and the applications then stalls.
   
Problems 2) and 3) can be investigated if there is an interest in this 
topic, otherwise I won't waste more time with it.

## The architecture of Mission Chameleon 
1) Main menu NETCD.EXE

This is a 32bit Application that shows the main menu and is the target
of the link in the Start menu. It calls the MISSION.EXE (which seems to
be the same as WINNTU.EXE) with certain parameters according to the 
selection in the main menu.

2) Windows backend MISSION.EXE 

This is a 16bit application and acts as the handler that reacts to the 
calls from the called DOS application AS.EXE and offers SFX, music 
etc. via window messages that normally get delivered via the VNTD.386
driver. The application calls AS.EXE 

3) DOS GAME AS.EXE 

This is a DOS application and the real game that gets launched by 
MISSION.EXE. It only supports VESA graphics interface.
AS.PIF normally insists on executing it in fullscreen mode.
The game also gets called with parameters from MISSION.EXE 

## How this repository hooks into the game
A VXD normally consists of a 16bit realmode and a 32bit protected mode
part. [There](https://www-user.tu-chemnitz.de/~heha/vxd/vxd.htm) is a 
good description about the architecture of VXD device drivers.
Interfaceing with VXDs is usually done via the function 
[1684h of INT 2F](http://www.ctyme.com/intr/int-2f.htm).

So first, the 32bit part of the driver needs to be implemented. You
can find it in the [dll](dll/) subdirectory. It builds the VNTD.DLL
driver that implements the same interface as the original VNTD.386,
both the Realmode Part (V86_0), as well as the Protected mode Part 
(PM_0). As both parts need to access the same data/variables for
processing, they need to be put into a shared memory segment 
(see the `#pragma` statements about the `.SHARED` section of the file).
The rest of the driver is just usual VDD initialization stuff.

Now there is the 16bit Windows part that needs to be loaded in 
MISSION.EXE. This is the 16bit device driver VNTD.DRV which can 
be found in [drv](drv/) subdirectory. It installs an INT 2F handler 
that checks for 1684h call and checks, if the unique identifier of the 
VNTD.386 driver (6ED8h) has been requested. If so, it returns the 
address of the handler function `PmVntdEntryPoint` that dispatches
the call to the (PM_0) export of the DLL driver.

This Win16 driver needs to be loaded somehow, so the easiest method
is to rename MISSION.EXE to MISSION1.EXE and place a little stub 
loader as MISSION.EXE that first loads the VNTD.DRV via LoadLibrary
and then executes the original executable (now MISSION1.EXE). This 
ensures that the driver is in memory of the 16bit executable.
Source of stub is in [mission](mission/) subdirectory.

Finally, the DOS part also needs to communicate with the VDD driver.
So I wrote a little TSR that hooks 1684h function of INT 2F and
checks for the unique identifier of the VNTD.386 driver (6ED8h), just 
like the Win16 driver above. The handler dispatches the call to 
the V86_0 function of the VDD driver.
The TSR is named VNTD.COM. 
Source can be found in [TSR](tsr/) subdirectory.

This driver also needs to be loaded prior to the start of the DOS 
application but should not always be loaded when not needed, so the 
same trick as with MISSION.EXE is used here:
AS.EXE gets renamed to AS1.EXE and a stub loader from [AS](as/)
directory is being used that first loads the VNTD.COM. Then 
it loads SOLVBE.EXE, in case it is present and finally it loads the 
AS1.EXE, so the original game.
As it doesn't bail out on error, it is enough to NOT place SOLVBE.EXE 
into the MISSION directory in order to skip loading it like i.e. 
on x64 Windows.

## File placement
File        | Dest. Dir.         | Condition 
------------|--------------------|--------------------------------------------
AS.EXE      | C:\MISSION         | After renaming AS.EXE to AS1.EXE
AS.PIF      | C:\MISSION         | No fullscreen and/or SOLVBE required or x64
MISSION.EXE | C:\MISSION         | After renaming MISSION.EXE to MISSION1.EXE
SOLVBE.DLL  | WINDOWS\SYSTEM32   | Only if SOLVE is needed 
SOLVBE.EXE  | C:\MISSION         | Only if SOLVE is needed 
VNTD.COM    | C:\MISSION         |
VNTD.DLL    | WINDOWS\SYSTEM32   |
VNTD.DRV    | WINDOWS\SYSTEM32   |
WING32.DLL  | WINDOWS\SYSTEM32   | 

NB: SYSTEM32 is SYSWOW64 on x64 Windows.
The copying to the SYSTEM32 directory is necessary, as on Windows 7 or higher,
loading VDD drivers from the current application directory does not work 
anymore, but the drivers have to be in SYSTEM32 directory.

## Contact/Questions?
If you have questions, feel free to use the issue tracker.
