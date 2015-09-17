@echo off
setlocal

rem // Try to find CMake from the "deps" directory. If not there, use from PATH.
set __nginCmake=%~dp0..\..\deps\cmake\bin\cmake.exe
if not exist %__nginCmake% (
    set __nginCmake=cmake
)

%__nginCmake% %*

endlocal
