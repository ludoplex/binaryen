# Binaryen Portable Builds

This directory contains build configurations for creating portable Binaryen binaries:

1. **binaryen.com** - Actually Portable Executable (APE) using Cosmopolitan Libc
2. **binaryen.wasm** - Standalone WebAssembly module

## binaryen.com - Cosmopolitan Build

Creates a single executable that runs natively on Linux, macOS, Windows, FreeBSD, OpenBSD, and NetBSD.

### Prerequisites

Download and install cosmocc:

```bash
mkdir -p /opt/cosmo
cd /opt/cosmo
wget https://cosmo.zip/pub/cosmocc/cosmocc.zip
unzip cosmocc.zip
```

Or set `COSMO_PATH` to your installation directory.

### Building

**Using the build script (recommended):**

```bash
./cosmo/build.sh          # Release build
./cosmo/build.sh debug    # Debug build
./cosmo/build.sh clean    # Clean build directory
```

**Using CMake directly:**

```bash
mkdir build-cosmo && cd build-cosmo
cmake .. \
    -DCMAKE_TOOLCHAIN_FILE=../cosmo/cosmo-toolchain.cmake \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_STATIC_LIB=ON \
    -DBUILD_TESTS=OFF \
    -DBUILD_LLVM_DWARF=OFF
cmake --build . --parallel
```

### Output

Executables are created in `build-cosmo/bin/`:
- `wasm-opt.com` - WebAssembly optimizer
- `wasm-merge.com` - Module merger
- `wasm-as.com` - Text to binary assembler
- `wasm-dis.com` - Binary to text disassembler
- `wasm-ctor-eval.com` - Compile-time constructor evaluation
- `wasm-metadce.com` - Dead code elimination
- `wasm2js.com` - WebAssembly to JavaScript converter

### Usage

The `.com` files run directly on any supported OS:

```bash
# Linux/macOS/BSD
./wasm-opt.com -O3 input.wasm -o output.wasm

# Windows (works in cmd.exe, PowerShell, or WSL)
wasm-opt.com -O3 input.wasm -o output.wasm
```

---

## binaryen.wasm - Standalone WebAssembly Module

Creates a `.wasm` file exposing Binaryen's C API, suitable for use with:
- WAMR (WebAssembly Micro Runtime)
- wasmtime
- wasmer
- Any WASI-compatible runtime

### Prerequisites

Install Emscripten SDK:

```bash
git clone https://github.com/emscripten-core/emsdk.git
cd emsdk
./emsdk install latest
./emsdk activate latest
source ./emsdk_env.sh
```

### Building

```bash
mkdir build-wasm && cd build-wasm
emcmake cmake .. \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_STANDALONE_WASM=ON
emmake make binaryen_wasm_standalone
```

### Output

- `lib/binaryen.wasm` - Standalone WASM module (~5-10 MB)

### Exported Functions

The module exports the complete Binaryen C API. Key functions:

```c
// Module operations
BinaryenModuleRef BinaryenModuleCreate(void);
void BinaryenModuleDispose(BinaryenModuleRef module);
BinaryenModuleRef BinaryenModuleRead(char* input, size_t inputSize);
size_t BinaryenModuleWrite(BinaryenModuleRef module, char* output, size_t outputSize);

// Optimization
void BinaryenModuleOptimize(BinaryenModuleRef module);
void BinaryenSetOptimizeLevel(int level);
void BinaryenSetShrinkLevel(int level);

// Validation
bool BinaryenModuleValidate(BinaryenModuleRef module);

// Memory management
void* _malloc(size_t size);
void _free(void* ptr);
```

### Example: Using with WAMR

```c
#include "wasm_export.h"

// Load binaryen.wasm
wasm_module_t module = wasm_runtime_load(wasm_file, wasm_file_size, error_buf, sizeof(error_buf));
wasm_module_inst_t inst = wasm_runtime_instantiate(module, stack_size, heap_size, error_buf, sizeof(error_buf));

// Call BinaryenModuleCreate
wasm_function_inst_t func = wasm_runtime_lookup_function(inst, "BinaryenModuleCreate");
wasm_runtime_call_wasm(exec_env, func, 0, NULL);
```

---

## Configuration Options

### CMake Options

| Option | Default | Description |
|--------|---------|-------------|
| `BUILD_STATIC_LIB` | OFF | Build static library (required for Cosmopolitan) |
| `BUILD_TESTS` | ON | Build test suite |
| `BUILD_LLVM_DWARF` | ON | Include DWARF debug info support |
| `BUILD_STANDALONE_WASM` | OFF | Build standalone WASM module |
| `COSMO_PATH` | /opt/cosmo | Path to Cosmopolitan installation |

### Environment Variables

| Variable | Description |
|----------|-------------|
| `COSMO_PATH` | Override Cosmopolitan installation path |
| `PREFIX` | Installation prefix for `make install` |

---

## Troubleshooting

### Cosmopolitan Build

**"cosmocc not found"**
- Ensure cosmocc is installed at `/opt/cosmo` or set `COSMO_PATH`

**Linker errors about missing symbols**
- Ensure `BUILD_STATIC_LIB=ON` is set
- Try building without DWARF: `-DBUILD_LLVM_DWARF=OFF`

**Binary doesn't run on Windows**
- The APE loader may need to be installed: https://cosmo.zip/pub/cosmos/bin/ape-loader.exe

### WASM Build

**"emcmake not found"**
- Ensure Emscripten is installed and `emsdk_env.sh` is sourced

**Out of memory during build**
- Increase Node.js memory: `export NODE_OPTIONS="--max-old-space-size=8192"`

**Module too large**
- Enable LTO: `-DCMAKE_BUILD_TYPE=Release` enables `-flto`
- Disable unused features in binaryen-c.cpp

---

## License

Binaryen is licensed under the Apache License, Version 2.0.
Cosmopolitan Libc is licensed under the ISC License.
