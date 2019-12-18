@echo off
cls
echo =================================
echo COMPARE.BAT: LS-DOS 6.3.1 COMPARE
echo =================================
echo.
echo This config will allow to compare LS-DOS 6.3.1 binaries with original ones.
echo.
echo When emulator started, enter the command:
echo   DO COMPARE
echo to start the comparison of binaries.
echo.
echo JCL files are on disk :1 (L631UTL.DSK).
echo Original LS-DOS 6.3.1 disk is :2 (LD4-631F.DSK).
echo Output files form BUILD are on disk :3 (L631BIN.DSK).
echo.
echo When job is complete, type
echo   EXIT
echo and then proceed with GET.BAT.
echo.
pause
echo Running emulator
@start ..\simz80 /t:4 /h:..\model4 /d:L631BOOT.dsk /d:L631UTL.dsk /d:LD4-631F.dsk /d:L631BIN.dsk /k:1000 /q:10000 /e+1
