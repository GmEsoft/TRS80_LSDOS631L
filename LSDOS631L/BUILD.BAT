@echo off
cls
echo =============================
echo BUILD.BAT: LS-DOS 6.3.1 BUILD
echo =============================
echo.
echo This config will allow to build LS-DOS 6.3.1 binaries.
echo.
echo When emulator started, enter the command:
echo   DO BUILD
echo to start the building of binaries.
echo.
echo Source files are on disks :1 (L631UTL.DSK) and :2 (L631SYS.DSK).
echo Output files are on disk :3 (L631BIN.DSK).
echo.
echo Language customization and version selection are now done in 
echo DOSDEFS/ASM:1 ; logo customization is done in SYSRES/ASM:2.
echo.
echo When job is complete, type
echo   EXIT
echo and then proceed with COMPARE.BAT.
echo.
pause
echo Running emulator
@start /wait ..\simz80 /t:4 /h:..\model4 /d:L631BOOT.dsk /d:L631UTL.dsk /d:L631SYS.dsk /d:L631BIN.dsk /k:1000 /q:20000 /e:+1
echo Job done.
