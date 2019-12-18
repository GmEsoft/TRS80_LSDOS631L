@echo off
setlocal enabledelayedexpansion
set DISASM="%~DP0DASM80"
set BIN2HEX="%~DP0BIN2HEX"
cd LSDOS631\CMDFILES
%BIN2HEX% LOWCORE.CIM LOWCORE.HEX
%DISASM% -h:LOWCORE.HEX -o:LOWCORE.dasm
set ECHO=
for %%c in (*.cmd) do (
	set NAME=%%c
	set NAME=!NAME:.cmd=!
	set SCR=
	if exist !NAME!.scr set SCR=-S:!NAME!.scr
	if /I not "!NAME!" == "SYS6" if /I not "!NAME!" == "SYS7" if /I not "!NAME!" == "SYS8" %ECHO% %DISASM% -c:!NAME! -o:!NAME!.dasm !SCR!
	if /I not "!NAME!" == "SYS6" if /I not "!NAME!" == "SYS7" if /I not "!NAME!" == "SYS8" %ECHO% %DISASM% -c:!NAME! -p:!NAME! !SCR!
)
