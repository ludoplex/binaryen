# Cosmopolitan Libc CMake Toolchain File
# For building Actually Portable Executables (APE)
#
# Usage:
#   cmake -DCMAKE_TOOLCHAIN_FILE=cosmo/cosmo-toolchain.cmake -B build-cosmo
#   cmake --build build-cosmo
#
# Prerequisites:
#   Download cosmocc from https://cosmo.zip/pub/cosmocc/
#   Extract to /opt/cosmo or set COSMO_PATH environment variable

cmake_minimum_required(VERSION 3.10)

# Cosmopolitan path - can be overridden via environment or cmake variable
if(NOT DEFINED COSMO_PATH)
    if(DEFINED ENV{COSMO_PATH})
        set(COSMO_PATH "$ENV{COSMO_PATH}")
    else()
        set(COSMO_PATH "/opt/cosmo")
    endif()
endif()

# Verify cosmocc exists
if(NOT EXISTS "${COSMO_PATH}/bin/cosmocc")
    message(FATAL_ERROR
        "cosmocc not found at ${COSMO_PATH}/bin/cosmocc\n"
        "Download from https://cosmo.zip/pub/cosmocc/ and extract to ${COSMO_PATH}\n"
        "Or set COSMO_PATH to your installation directory")
endif()

# System identification
set(CMAKE_SYSTEM_NAME Generic)
set(CMAKE_SYSTEM_PROCESSOR x86_64)
set(CMAKE_CROSSCOMPILING TRUE)

# Compilers
set(CMAKE_C_COMPILER "${COSMO_PATH}/bin/cosmocc")
set(CMAKE_CXX_COMPILER "${COSMO_PATH}/bin/cosmoc++")
set(CMAKE_AR "${COSMO_PATH}/bin/cosmoar")
set(CMAKE_RANLIB "${COSMO_PATH}/bin/cosmoar" s)

# Don't try to test compilers (cross-compiling)
set(CMAKE_C_COMPILER_WORKS TRUE)
set(CMAKE_CXX_COMPILER_WORKS TRUE)

# Cosmopolitan-specific definitions
add_compile_definitions(__COSMOPOLITAN__)
add_compile_definitions(BINARYEN_COSMO)

# Compiler flags
set(CMAKE_C_FLAGS_INIT "-fno-pie -no-pie")
set(CMAKE_CXX_FLAGS_INIT "-fno-pie -no-pie")

# Release flags - optimize for size and speed
set(CMAKE_C_FLAGS_RELEASE_INIT "-O2 -DNDEBUG")
set(CMAKE_CXX_FLAGS_RELEASE_INIT "-O2 -DNDEBUG")

# Debug flags
set(CMAKE_C_FLAGS_DEBUG_INIT "-g -O0")
set(CMAKE_CXX_FLAGS_DEBUG_INIT "-g -O0")

# MinSizeRel - optimize for smallest binary
set(CMAKE_C_FLAGS_MINSIZEREL_INIT "-Os -DNDEBUG")
set(CMAKE_CXX_FLAGS_MINSIZEREL_INIT "-Os -DNDEBUG")

# Linker flags for APE output
set(CMAKE_EXE_LINKER_FLAGS_INIT "-fno-pie -no-pie")

# Static linking (required for APE)
set(CMAKE_FIND_LIBRARY_SUFFIXES ".a")
set(BUILD_SHARED_LIBS OFF CACHE BOOL "Build shared libraries" FORCE)

# Output file extension
set(CMAKE_EXECUTABLE_SUFFIX ".com")

# Disable features not compatible with Cosmopolitan
set(CMAKE_THREAD_LIBS_INIT "-lpthread")
set(CMAKE_HAVE_THREADS_LIBRARY 1)
set(CMAKE_USE_PTHREADS_INIT 1)
set(THREADS_PREFER_PTHREAD_FLAG ON)

# Search paths
set(CMAKE_FIND_ROOT_PATH "${COSMO_PATH}")
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)

# Print configuration
message(STATUS "Cosmopolitan toolchain loaded")
message(STATUS "  COSMO_PATH: ${COSMO_PATH}")
message(STATUS "  CC: ${CMAKE_C_COMPILER}")
message(STATUS "  CXX: ${CMAKE_CXX_COMPILER}")
