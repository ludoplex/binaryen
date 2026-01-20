# Binaryen Cosmopolitan Build
# Creates binaryen.com - Actually Portable Executable
#
# Usage:
#   make -f cosmo/Makefile
#   make -f cosmo/Makefile release
#   make -f cosmo/Makefile clean
#
# Prerequisites:
#   Download cosmocc from https://cosmo.zip/pub/cosmocc/
#   Extract to /opt/cosmo or set COSMO_PATH

.PHONY: all release debug clean install help

# Configuration
COSMO_PATH ?= /opt/cosmo
PREFIX ?= /usr/local
BUILD_DIR ?= build/cosmo

# Compilers
CC = $(COSMO_PATH)/bin/cosmocc
CXX = $(COSMO_PATH)/bin/cosmoc++
AR = $(COSMO_PATH)/bin/cosmoar

# Check cosmocc exists
ifeq ($(wildcard $(CC)),)
$(error cosmocc not found at $(CC). Download from https://cosmo.zip/pub/cosmocc/)
endif

# Flags
CFLAGS_COMMON = -fno-pie -no-pie -D__COSMOPOLITAN__ -DBINARYEN_COSMO
CXXFLAGS_COMMON = $(CFLAGS_COMMON) -std=c++17 -fno-rtti -fno-exceptions
LDFLAGS_COMMON = -fno-pie -no-pie

# Include paths
INCLUDES = -I../src -I$(BUILD_DIR)

# Release flags (default)
CFLAGS_RELEASE = -O2 -DNDEBUG
CXXFLAGS_RELEASE = -O2 -DNDEBUG

# Debug flags
CFLAGS_DEBUG = -g -O0
CXXFLAGS_DEBUG = -g -O0

# Size-optimized flags
CFLAGS_SMALL = -Os -DNDEBUG
CXXFLAGS_SMALL = -Os -DNDEBUG

# Default to release
CFLAGS = $(CFLAGS_COMMON) $(CFLAGS_RELEASE) $(INCLUDES)
CXXFLAGS = $(CXXFLAGS_COMMON) $(CXXFLAGS_RELEASE) $(INCLUDES)
LDFLAGS = $(LDFLAGS_COMMON)

# Source directories (relative to repo root)
SRC_ROOT = ..
SRC_DIRS = \
	$(SRC_ROOT)/src/asmjs \
	$(SRC_ROOT)/src/cfg \
	$(SRC_ROOT)/src/emscripten-optimizer \
	$(SRC_ROOT)/src/ir \
	$(SRC_ROOT)/src/passes \
	$(SRC_ROOT)/src/support \
	$(SRC_ROOT)/src/wasm \
	$(SRC_ROOT)/src/analysis

# Find all source files
SUPPORT_SRCS = $(wildcard $(SRC_ROOT)/src/support/*.cpp)
WASM_SRCS = $(wildcard $(SRC_ROOT)/src/wasm/*.cpp)
ASMJS_SRCS = $(wildcard $(SRC_ROOT)/src/asmjs/*.cpp)
CFG_SRCS = $(wildcard $(SRC_ROOT)/src/cfg/*.cpp)
IR_SRCS = $(wildcard $(SRC_ROOT)/src/ir/*.cpp)
PASSES_SRCS = $(wildcard $(SRC_ROOT)/src/passes/*.cpp)
EMOPT_SRCS = $(wildcard $(SRC_ROOT)/src/emscripten-optimizer/*.cpp)
ANALYSIS_SRCS = $(wildcard $(SRC_ROOT)/src/analysis/*.cpp)

# C API
CAPI_SRCS = $(SRC_ROOT)/src/binaryen-c.cpp

# All library sources
LIB_SRCS = $(SUPPORT_SRCS) $(WASM_SRCS) $(ASMJS_SRCS) $(CFG_SRCS) \
           $(IR_SRCS) $(PASSES_SRCS) $(EMOPT_SRCS) $(ANALYSIS_SRCS) $(CAPI_SRCS)

# Object files
LIB_OBJS = $(patsubst $(SRC_ROOT)/%.cpp,$(BUILD_DIR)/%.o,$(LIB_SRCS))

# Tools
TOOLS = wasm-opt wasm-as wasm-dis wasm-merge wasm-metadce wasm-ctor-eval wasm2js
TOOL_BINS = $(addprefix $(BUILD_DIR)/bin/,$(addsuffix .com,$(TOOLS)))

# Library
LIBBINARYEN = $(BUILD_DIR)/lib/libbinaryen.a

# Default target
all: $(BUILD_DIR)/bin/binaryen.com

# Release build
release: CFLAGS = $(CFLAGS_COMMON) $(CFLAGS_RELEASE) $(INCLUDES)
release: CXXFLAGS = $(CXXFLAGS_COMMON) $(CXXFLAGS_RELEASE) $(INCLUDES)
release: all

# Debug build
debug: CFLAGS = $(CFLAGS_COMMON) $(CFLAGS_DEBUG) $(INCLUDES)
debug: CXXFLAGS = $(CXXFLAGS_COMMON) $(CXXFLAGS_DEBUG) $(INCLUDES)
debug: all

# Size-optimized build
small: CFLAGS = $(CFLAGS_COMMON) $(CFLAGS_SMALL) $(INCLUDES)
small: CXXFLAGS = $(CXXFLAGS_COMMON) $(CXXFLAGS_SMALL) $(INCLUDES)
small: all

# Generate config.h
$(BUILD_DIR)/config.h:
	@mkdir -p $(BUILD_DIR)
	@echo "// Auto-generated config.h for Cosmopolitan build" > $@
	@echo "#ifndef BINARYEN_CONFIG_H" >> $@
	@echo "#define BINARYEN_CONFIG_H" >> $@
	@echo "#define PROJECT_VERSION \"114\"" >> $@
	@echo "#endif" >> $@

# Compile C++ sources
$(BUILD_DIR)/%.o: $(SRC_ROOT)/%.cpp $(BUILD_DIR)/config.h
	@mkdir -p $(dir $@)
	$(CXX) $(CXXFLAGS) -c $< -o $@

# Build static library
$(LIBBINARYEN): $(LIB_OBJS)
	@mkdir -p $(dir $@)
	$(AR) rcs $@ $^

# Multicall binary entry point
$(BUILD_DIR)/multicall.o: multicall.cpp $(BUILD_DIR)/config.h
	@mkdir -p $(dir $@)
	$(CXX) $(CXXFLAGS) -c $< -o $@

# Individual tool objects
$(BUILD_DIR)/tools/%.o: $(SRC_ROOT)/src/tools/%.cpp $(BUILD_DIR)/config.h
	@mkdir -p $(dir $@)
	$(CXX) $(CXXFLAGS) -c $< -o $@

# Main binaryen.com multicall binary
$(BUILD_DIR)/bin/binaryen.com: $(BUILD_DIR)/multicall.o $(LIBBINARYEN) \
		$(BUILD_DIR)/tools/wasm-opt.o \
		$(BUILD_DIR)/tools/wasm-as.o \
		$(BUILD_DIR)/tools/wasm-dis.o \
		$(BUILD_DIR)/tools/wasm-merge.o \
		$(BUILD_DIR)/tools/wasm-metadce.o \
		$(BUILD_DIR)/tools/wasm-ctor-eval.o \
		$(BUILD_DIR)/tools/wasm2js.o
	@mkdir -p $(dir $@)
	$(CXX) $(LDFLAGS) -o $@ $^ -lpthread
	@echo "Built: $@"
	@ls -lh $@

# Create symlinks for individual tools
symlinks: $(BUILD_DIR)/bin/binaryen.com
	@cd $(BUILD_DIR)/bin && \
	for tool in $(TOOLS); do \
		ln -sf binaryen.com $$tool.com; \
	done
	@echo "Created tool symlinks"

# Install
install: $(BUILD_DIR)/bin/binaryen.com
	install -d $(PREFIX)/bin
	install -m 755 $(BUILD_DIR)/bin/binaryen.com $(PREFIX)/bin/
	@cd $(PREFIX)/bin && \
	for tool in $(TOOLS); do \
		ln -sf binaryen.com $$tool.com; \
	done
	@echo "Installed to $(PREFIX)/bin"

# Clean
clean:
	rm -rf $(BUILD_DIR)

# Help
help:
	@echo "Binaryen Cosmopolitan Build"
	@echo ""
	@echo "Targets:"
	@echo "  all       - Build binaryen.com (default)"
	@echo "  release   - Build optimized (-O2)"
	@echo "  debug     - Build with debug symbols"
	@echo "  small     - Build size-optimized (-Os)"
	@echo "  symlinks  - Create tool symlinks"
	@echo "  install   - Install to PREFIX (default: /usr/local)"
	@echo "  clean     - Remove build artifacts"
	@echo ""
	@echo "Variables:"
	@echo "  COSMO_PATH - Path to cosmocc (default: /opt/cosmo)"
	@echo "  PREFIX     - Install prefix (default: /usr/local)"
	@echo "  BUILD_DIR  - Build output directory (default: build/cosmo)"
	@echo ""
	@echo "Output:"
	@echo "  binaryen.com - Actually Portable Executable"
	@echo "  Runs on: Linux, macOS, Windows, FreeBSD, OpenBSD, NetBSD"
