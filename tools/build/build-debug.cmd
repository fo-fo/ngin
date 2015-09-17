@echo off
setlocal

set __nginNinja=%~dp0ngin-ninja.cmd

pushd build\debug
call %__nginNinja% %*
popd

endlocal
