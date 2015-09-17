@echo off
setlocal

rem // Try to find ar65 from the "deps" directory. If not there, use from PATH.
set __nginAr65=%~dp0..\..\deps\cc65\bin\ar65.exe
if not exist %__nginAr65% (
    set __nginAr65=ar65
)

%__nginAr65% %*

endlocal
