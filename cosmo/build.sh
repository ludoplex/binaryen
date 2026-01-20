#!/bin/bash
#
# Build Binaryen with Cosmopolitan Libc
# Creates Actually Portable Executables (.com files)
#
# Usage:
#   ./cosmo/build.sh              # Build release
#   ./cosmo/build.sh debug        # Build with debug symbols
#   ./cosmo/build.sh clean        # Clean build directory
#   ./cosmo/build.sh install      # Install to /usr/local
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="${PROJECT_ROOT}/build-cosmo"

# Cosmopolitan path
COSMO_PATH="${COSMO_PATH:-/opt/cosmo}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

check_cosmocc() {
    if [[ ! -f "${COSMO_PATH}/bin/cosmocc" ]]; then
        error "cosmocc not found at ${COSMO_PATH}/bin/cosmocc

Download from: https://cosmo.zip/pub/cosmocc/

Install with:
  mkdir -p /opt/cosmo
  cd /opt/cosmo
  wget https://cosmo.zip/pub/cosmocc/cosmocc.zip
  unzip cosmocc.zip

Or set COSMO_PATH to your installation directory."
    fi
    info "Found cosmocc at ${COSMO_PATH}"
}

clean() {
    info "Cleaning build directory..."
    rm -rf "${BUILD_DIR}"
    info "Done"
}

build() {
    local build_type="${1:-Release}"

    check_cosmocc

    info "Building Binaryen with Cosmopolitan (${build_type})..."

    mkdir -p "${BUILD_DIR}"
    cd "${BUILD_DIR}"

    # Configure with CMake using Cosmopolitan toolchain
    cmake "${PROJECT_ROOT}" \
        -DCMAKE_TOOLCHAIN_FILE="${SCRIPT_DIR}/cosmo-toolchain.cmake" \
        -DCMAKE_BUILD_TYPE="${build_type}" \
        -DBUILD_STATIC_LIB=ON \
        -DBUILD_TESTS=OFF \
        -DBUILD_LLVM_DWARF=OFF \
        -DENABLE_WERROR=OFF \
        -DCOSMO_PATH="${COSMO_PATH}"

    # Build (with portable CPU count detection)
    local num_cpus
    if command -v nproc &> /dev/null; then
        num_cpus=$(nproc)
    elif command -v sysctl &> /dev/null && sysctl -n hw.ncpu &> /dev/null; then
        num_cpus=$(sysctl -n hw.ncpu)
    else
        num_cpus=4  # fallback default
    fi
    cmake --build . --parallel "${num_cpus}"

    # List built executables
    info "Built executables:"
    find bin -name "*.com" -exec ls -lh {} \; 2>/dev/null || true
    find bin -type f -executable -exec ls -lh {} \; 2>/dev/null || true

    info "Build complete!"
    info "Binaries are in: ${BUILD_DIR}/bin/"
}

install_bins() {
    local prefix="${1:-/usr/local}"

    if [[ ! -d "${BUILD_DIR}/bin" ]]; then
        error "Build directory not found. Run build first."
    fi

    info "Installing to ${prefix}/bin..."

    mkdir -p "${prefix}/bin"

    # Install all executables
    for exe in "${BUILD_DIR}/bin"/*; do
        if [[ -x "$exe" && -f "$exe" ]]; then
            install -m 755 "$exe" "${prefix}/bin/"
            info "  Installed $(basename "$exe")"
        fi
    done

    info "Installation complete!"
}

usage() {
    echo "Binaryen Cosmopolitan Build Script"
    echo ""
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  (default)   Build release version"
    echo "  debug       Build with debug symbols"
    echo "  release     Build optimized release"
    echo "  clean       Remove build directory"
    echo "  install     Install to /usr/local (or specify PREFIX)"
    echo "  help        Show this help"
    echo ""
    echo "Environment variables:"
    echo "  COSMO_PATH  Path to Cosmopolitan (default: /opt/cosmo)"
    echo "  PREFIX      Installation prefix for 'install' command"
    echo ""
    echo "Example:"
    echo "  COSMO_PATH=/path/to/cosmo $0"
    echo "  PREFIX=/opt/binaryen $0 install"
}

# Main
case "${1:-build}" in
    clean)
        clean
        ;;
    debug)
        build Debug
        ;;
    release|build|"")
        build Release
        ;;
    install)
        install_bins "${PREFIX:-/usr/local}"
        ;;
    help|--help|-h)
        usage
        ;;
    *)
        error "Unknown command: $1"
        ;;
esac
