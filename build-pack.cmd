@echo off
REM Build the .nup + pack.zip on the PC, inside WSL2 (see BUILD-PACK.md).
REM Usage: build-pack.cmd smash "C:\path\Smash.xci" "C:\path\update.nsp" C:\path\dlc\*.nsp
REM        build-pack.cmd darksiders "C:\path\DarksidersII.nsp" C:\path\dlc\*.nsp
setlocal
wsl --cd "%~dp0" bash ./build-pack.sh %*
if errorlevel 1 pause
