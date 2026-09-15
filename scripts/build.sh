#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT"

CONFIGURATION="${1:-Release}"
FRAMEWORK="${2:-net10.0}"
SKIP_NATIVE="${SKIP_NATIVE:-false}"

OUT_DIR="publish-${FRAMEWORK}"
MCP_OUT_DIR="publish-${FRAMEWORK}-mcp"

dotnet publish -c "$CONFIGURATION" -f "$FRAMEWORK" -o "$OUT_DIR" src/de4dot
rm -f "$OUT_DIR"/*.pdb "$OUT_DIR"/*.xml

dotnet publish -c "$CONFIGURATION" -f "$FRAMEWORK" -o "$MCP_OUT_DIR" src/de4dot.mcp
rm -f "$MCP_OUT_DIR"/*.pdb "$MCP_OUT_DIR"/*.xml

if [[ "$SKIP_NATIVE" != "true" ]]; then
    if command -v cmake >/dev/null 2>&1; then
        echo "Building native BeaEngine library..."
        build_dir="build-native"
        cmake -S native/BeaEngine -B "$build_dir" -DCMAKE_BUILD_TYPE="$CONFIGURATION"
        cmake --build "$build_dir" --config "$CONFIGURATION"

        native_lib=$(find "$build_dir/bin" -type f \( -name "libBeaEngine*.dylib" -o -name "libBeaEngine*.so" -o -name "BeaEngine*.dll" \) | head -n 1)
        if [[ -n "$native_lib" ]]; then
            cp "$native_lib" "$OUT_DIR/"
            cp "$native_lib" "$MCP_OUT_DIR/"
            echo "Copied $(basename "$native_lib") to $OUT_DIR and $MCP_OUT_DIR"
        else
            echo "Warning: BeaEngine binary not found in $build_dir/bin" >&2
        fi
    else
        echo "Warning: cmake command not found. Skipping native BeaEngine build." >&2
    fi
fi
