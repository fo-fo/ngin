@echo off
setlocal

rem // Try to find Ninja from the "deps" directory. If not there, use from PATH.
set __nginNinja=%~dp0..\..\deps\ninja\ninja.exe
if not exist %__nginNinja% (
    set __nginNinja=ninja
)

%__nginNinja% %*

endlocal
