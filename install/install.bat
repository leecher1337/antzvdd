@echo on
if "%1"=="" (
  if not exist c:\mission\as.exe goto usage
  set INDIR=c:\mission
) else (
  set INDIR=%1
)

:StartExec
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
if '%errorlevel%' NEQ '0' (
  echo Requesting administrative privileges...
  goto UACPrompt
) else ( goto gotAdmin )
:UACPrompt
echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
echo UAC.ShellExecute "%~s0", "", "", "runas", 1 >> "%temp%\getadmin.vbs"
"%temp%\getadmin.vbs"
exit /B
:gotAdmin
if exist "%temp%\getadmin.vbs" ( del "%temp%\getadmin.vbs" )
pushd "%CD%"
CD /D "%~dp0"

set ARCH=%PROCESSOR_ARCHITECTURE%
if not "%PROCESSOR_ARCHITEW6432%"=="" set ARCH=%PROCESSOR_ARCHITEW6432%

Setlocal EnableDelayedExpansion
for /f "tokens=4-5 delims=[.XP " %%i in ('ver') do set VERSION=%%i.%%j

if "%ARCH%"=="x86" (
  set SYS32DIR=%SystemRoot%\SYSTEM32
  rem On x86, we basically need SOLVBE on Windows Versions that aren't fullscreen capable
  if "%VERSION%"=="5.0" goto askvbe1
  if "%VERSION%"=="5.1" goto askvbe1
  if "%VERSION%"=="5.2" goto askvbe1
  if "%VERSION%"=="6.0" goto askvbe2
  if "%VERSION%"=="6.1" goto askvbe2
  set SOLVBE=1
  goto novbe 
:askvbe1
  echo Your Windows version may be capable of displaying VESA graphics in Full Screen
  echo mode by directly accessing the video card. Most Video cards support this, but 
  echo i.e. VMWare doesn't. 
  echo If your video graphics board driver or hardware is not capable of VESA support,
  echo you need to install SOLVBE. As this is slow, SOLVBE is not recommended.
  echo You can always install it afterwards by copying solvbe.exe, as.pif to the 
  echo MISSION directory and solvbe.dll to the System32 directory.
  CHOICE /C YN /M "echo Do you want to install SOLVBE anyway?"
  if not errorlevel 2 set SOLVBE=1
  goto novbe
:askvbe2
  echo Your Windows version doesn't support Fullscreen graphics, and therefore 
  echo possibly VESA support, out of the box. It may however be possible in case you 
  echo are either using a XPDM display driver like Standard VGA driver or you are 
  echo deactivating the driver temporarily while using the DOS program. This can
  echo be done automatically via the fullscrswitch package, for example.
  echo However, be aware that some video drivers don't like de- and reactivating on 
  echo the fly and tend to crash on restart, so you have to try this out.
  echo If you don't have any facilities like that, you need to install SOLVBE, even 
  echo though it may be slow. If unsure, say Y.
  echo You can always deactivate it by deleting the file solvbe.exe from the MISSION
  echo DIR.
  CHOICE /C YN /M "echo Do you want to install SOLVBE?"
  if not errorlevel 2 set SOLVBE=1
  goto novbe
) else (
  set SYS32DIR=%SystemRoot%\SYSWOW64
  set ASPIF=1
)
:novbe
rem NEVER EVER install solvbe on NTVDMx64!

for %%I in (as.exe mission.exe vntd.com vntd.drv vntd.dll wing32.dll) do if not exist %%I goto incomplete
if "%SOLVBE%"=="1" (
  for %%I in (solvbe.dll solvbe.exe) do if not exist %%I goto incomplete
  copy /y solvbe.exe %INDIR%\solvbe.exe
  copy /y solvbe.dll %SYS32DIR%\solvbe.dll
  set ASPIF=1
)
if "%ASPIF%"=="1" (
  if not exist %INDIR%\as.pif.bak (
    move /y %INDIR%\as.pif as.pif.bak
    copy /y as.pif %INDIR%\as.pif 
  )
)
copy /y vntd.com %INDIR%\vntd.com
for %%I in (vntd.drv vntd.dll wing32.dll) do copy /y %%I %SYS32DIR%\%%I
for %%I in (as mission) do (
  if not exist %INDIR%\%%I.exe goto wrongdir
  if not exist %INDIR%\%%I1.exe (
    move /y %INDIR%\%%I.exe %INDIR%\%%I1.exe
    copy /y %%I.exe %INDIR%\%%I.exe
  )
)
pause
exit /B


:incomplete
echo Your installation directory is incomplete, files are missing.
pause
exit /B
:wrongdir
echo %INDIR% is not a valid installation directory, please check
echo.
:usage
echo Usage: %0 [Directory of installation]
pause
exit /B