@echo off
cls
echo ===============================
echo TEST_FR.BAT: LS-DOS 6.3.1F TEST
echo ===============================
echo.
echo This config will allow to test the new LS-DOS 6.3.1F boot disk.
echo.
echo The new boot disk is :1 (L631NEW.DSK).
echo.
pause
echo Running emulator
@start ..\simz80 /t:4 /h:..\model4 /d:L631NEW.dsk /k:fr /i:50 /r:+1 /g
