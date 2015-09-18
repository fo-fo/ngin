@echo off
setlocal

call %~dp0ngin-cmake.cmd --build build/release -- %*

endlocal
