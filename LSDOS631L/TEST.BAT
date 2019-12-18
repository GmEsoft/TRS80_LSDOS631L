@echo off
cls
echo ===========================
echo TEST.BAT: LS-DOS 6.3.1 TEST
echo ===========================
echo.
echo This config will allow to test the new LS-DOS 6.3.1 boot disk.
echo.
echo The new boot disk is :1 (L631NEW.DSK).
echo.
pause
echo Running emulator
@start ..\simz80 /t:4 /h:..\model4 /d:L631NEW.dsk /r+1
