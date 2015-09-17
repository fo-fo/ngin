@echo off
setlocal

mkdir build\release
pushd build\release
cmake -G Ninja -DCMAKE_TOOLCHAIN_FILE="%~dp0../../cmake/toolchains/cc65-toolchain.cmake" -DCMAKE_BUILD_TYPE=Release ../..
popd

mkdir build\debug
pushd build\debug
cmake -G Ninja -DCMAKE_TOOLCHAIN_FILE="%~dp0../../cmake/toolchains/cc65-toolchain.cmake" -DCMAKE_BUILD_TYPE=Debug ../..
popd

endlocal
