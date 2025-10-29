@echo off
rem CI script for Windows (Ninja). Runs without parameters.

setlocal enabledelayedexpansion

rem 1) Create build directory if it does not exist
if not exist "build" (
  mkdir "build"
)

rem 2) Change into the build directory
pushd "build" || (
  echo Failed to enter build directory.
  exit /b 1
)

rem 3) Configure the project using CMake (Ninja generator)
cmake -G "Ninja" .. || (
  echo CMake configuration failed.
  popd
  exit /b 1
)

rem 4) Build the project using CMake
cmake --build . --config Release || (
  echo Build failed.
  popd
  exit /b 1
)

rem 5) Run all tests using CTest
ctest --output-on-failure --verbose || (
  echo Some tests failed.
  popd
  exit /b %ERRORLEVEL%
)

popd
endlocal
exit /b 0