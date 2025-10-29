#!/usr/bin/env bash
# CI script for Linux/macOS (Ninja). Runs without parameters.
set -euo pipefail

BUILD_DIR="build"

echo "1) Ensure build directory exists..."
if [ ! -d "$BUILD_DIR" ]; then
  mkdir -p "$BUILD_DIR"
fi

echo "2) Change into build directory..."
cd "$BUILD_DIR"

echo "3) Configure the project with CMake (Ninja generator)..."
# Use explicit Ninja generator and request Release build for single-config generators
cmake -G "Ninja" .. -DCMAKE_BUILD_TYPE=Release

echo "4) Build the project..."
cmake --build . --config Release

echo "5) Run all tests with CTest..."
ctest --output-on-failure --verbose

echo "CI completed successfully."