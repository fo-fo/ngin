@echo off
setlocal

pushd build\release
ninja %*
popd

endlocal
