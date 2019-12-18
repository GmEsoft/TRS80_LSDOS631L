@echo off
cls
echo ==================================
echo LD4-631.BAT: LS-DOS 6.3.1 ORIGINAL
echo ==================================
echo.
echo This config will allow to boot the original LS-DOS 6.3.1 boot disk.
echo.
echo The original boot disk is :1 (LD4-631.DSK).
echo.
pause
echo Running emulator
@start ..\simz80 /t:4 /h:..\model4 /d:LD4-631.dsk /r+1
