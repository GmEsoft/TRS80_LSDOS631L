@echo off
cls
echo =========================
echo GET.BAT: LS-DOS 6.3.1 GET
echo =========================
echo.
echo This config will allow to generate an LS-DOS 6.3.1 boot disk from new binary files.
echo.
echo When emulator started, enter the command:
echo   DO GET
echo to start the generation of LS-DOS 6.3.1 boot disk.
echo.
echo JCL files are on disk :1 (L631UTL.DSK).
echo New LS-DOS 6.3.1 disk is :2 (L631NEW.DSK).
echo Output files form BUILD are on disk :3 (L631BIN.DSK).
echo.
echo When job is complete, type
echo   EXIT
echo and then proceed with TEST.BAT.
echo.
pause
copy LD4-631.DSK L631NEW.DSK
echo Running emulator
start /wait ..\simz80 /t:4 /h:..\model4 /d:L631BOOT.dsk /d:L631UTL.dsk /d:L631NEW.dsk /d:L631BIN.dsk /k:1000 /q:+ /e:+1
