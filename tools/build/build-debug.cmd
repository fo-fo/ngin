@echo off
setlocal

pushd build\debug
ninja %*
popd

endlocal
