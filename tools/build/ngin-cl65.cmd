@echo off
setlocal

rem // Try to find cl65 from the "deps" directory. If not there, use from PATH.
set __nginCl65=%~dp0..\..\deps\cc65\bin\cl65.exe
if not exist %__nginCl65% (
    set __nginCl65=cl65
)

%__nginCl65% %*

endlocal
