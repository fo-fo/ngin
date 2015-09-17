@echo off
setlocal

set __nginCmake=%~dp0ngin-cmake.cmd
set __nginCl65=%~dp0ngin-cl65.cmd
set __nginAr65=%~dp0ngin-ar65.cmd

mkdir build\release
pushd build\release
call %__nginCmake% -G Ninja -DCMAKE_ASM_COMPILER="%__nginCl65%" -DCMAKE_C_COMPILER="%__nginCl65%" -DCMAKE_AR="%__nginAr65%" -DCMAKE_TOOLCHAIN_FILE="%~dp0../../cmake/toolchains/cc65-toolchain.cmake" -DCMAKE_BUILD_TYPE=Release ../..
popd

mkdir build\debug
pushd build\debug
call %__nginCmake% -G Ninja -DCMAKE_ASM_COMPILER="%__nginCl65%" -DCMAKE_C_COMPILER="%__nginCl65%" -DCMAKE_AR="%__nginAr65%" -DCMAKE_TOOLCHAIN_FILE="%~dp0../../cmake/toolchains/cc65-toolchain.cmake" -DCMAKE_BUILD_TYPE=Debug ../..
popd

endlocal
