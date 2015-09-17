@echo off
setlocal

set __nginNinja=%~dp0ngin-ninja.cmd

pushd build\release
call %__nginNinja% %*
popd

endlocal
