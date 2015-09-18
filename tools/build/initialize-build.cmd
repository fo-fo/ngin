@echo off
setlocal

set __nginCmake=%~dp0ngin-cmake.cmd

mkdir build\release
pushd build\release
call %__nginCmake% -G Ninja -DCMAKE_PROGRAM_PATH="%~dp0../../deps/ninja;%~dp0../../deps/cc65/bin" -DCMAKE_TOOLCHAIN_FILE="%~dp0../../cmake/toolchains/cc65-toolchain.cmake" -DCMAKE_BUILD_TYPE=Release ../..
popd

mkdir build\debug
pushd build\debug
call %__nginCmake% -G Ninja -DCMAKE_PROGRAM_PATH="%~dp0../../deps/ninja;%~dp0../../deps/cc65/bin" -DCMAKE_TOOLCHAIN_FILE="%~dp0../../cmake/toolchains/cc65-toolchain.cmake" -DCMAKE_BUILD_TYPE=Debug ../..
popd

endlocal
