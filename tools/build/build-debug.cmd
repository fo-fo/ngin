@echo off
setlocal

call %~dp0ngin-cmake.cmd --build build/debug -- %*

endlocal
