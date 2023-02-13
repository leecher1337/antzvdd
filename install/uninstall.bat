@echo off
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
if "%ARCH%"=="x86" (
set SYS32DIR="%SystemRoot%\SYSTEM32"
) else (
set SYS32DIR="%SystemRoot%\SYSWOW64"
)
for %%I in (vntd.drv vntd.dll solvbe.dll) do del %SYS32DIR%\%%I
for %%I in (solvbe.exe vntd.com) do del %INDIR%\%%I
for %%I in (as mission) do (
  if not exist %INDIR%\%%I1.exe goto wrongdir
  del %INDIR%\%%I.exe 
  move /y %INDIR%\%%I1.exe %INDIR%\%%I.exe
)
if exist %INDIR%\as.pif.bak (
  del /y %INDIR%\as.pif
  move /y %INDIR%\as.pif.bak %INDIR%\as.pif
)
pause
exit /B


:wrongdir
echo %INDIR% is not a valid installation directory, please check
echo.
:usage
echo Usage: %0 [Directory of installation]
pause
exit /B