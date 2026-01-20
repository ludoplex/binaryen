/*
 * Binaryen Multicall Binary Entry Point
 *
 * This provides a single entry point for all Binaryen tools.
 * The tool to run is determined by:
 *   1. The executable name (argv[0]) - e.g., "wasm-opt.com" runs wasm-opt
 *   2. The --tool=NAME argument - e.g., "binaryen.com --tool=opt"
 *   3. The first argument if it matches a tool name
 *
 * Supported tools:
 *   - wasm-opt       WebAssembly optimizer
 *   - wasm-as        WebAssembly assembler (text to binary)
 *   - wasm-dis       WebAssembly disassembler (binary to text)
 *   - wasm-merge     WebAssembly module merger
 *   - wasm-metadce   WebAssembly meta dead code elimination
 *   - wasm-ctor-eval WebAssembly constructor evaluator
 *   - wasm2js        WebAssembly to JavaScript converter
 */

#include <cstring>
#include <string>
#include <iostream>

// External main functions (actual tool entry points)
// Note: Binaryen tools use "const char* argv[]" signature
extern int wasm_opt_main(int argc, const char* argv[]);
extern int wasm_as_main(int argc, const char* argv[]);
extern int wasm_dis_main(int argc, const char* argv[]);
extern int wasm_merge_main(int argc, const char* argv[]);
extern int wasm_metadce_main(int argc, const char* argv[]);
extern int wasm_ctor_eval_main(int argc, const char* argv[]);
extern int wasm2js_main(int argc, const char* argv[]);

struct Tool {
    const char* name;
    const char* aliases[4];
    int (*main_func)(int, const char**);
    const char* description;
};

static const Tool tools[] = {
    {"wasm-opt", {"opt", "wasm-opt.com", "wasm_opt", nullptr},
     wasm_opt_main, "WebAssembly optimizer"},
    {"wasm-as", {"as", "wasm-as.com", "wasm_as", nullptr},
     wasm_as_main, "Assemble WebAssembly text to binary"},
    {"wasm-dis", {"dis", "wasm-dis.com", "wasm_dis", nullptr},
     wasm_dis_main, "Disassemble WebAssembly binary to text"},
    {"wasm-merge", {"merge", "wasm-merge.com", "wasm_merge", nullptr},
     wasm_merge_main, "Merge WebAssembly modules"},
    {"wasm-metadce", {"metadce", "wasm-metadce.com", "wasm_metadce", nullptr},
     wasm_metadce_main, "Meta dead code elimination"},
    {"wasm-ctor-eval", {"ctor-eval", "wasm-ctor-eval.com", "wasm_ctor_eval", nullptr},
     wasm_ctor_eval_main, "Evaluate constructors at compile time"},
    {"wasm2js", {"2js", "wasm2js.com", nullptr, nullptr},
     wasm2js_main, "Convert WebAssembly to JavaScript"},
    {nullptr, {nullptr}, nullptr, nullptr}
};

static const Tool* find_tool(const char* name) {
    // Extract basename from path
    const char* basename = strrchr(name, '/');
    if (basename) {
        basename++;
    } else {
        basename = name;
    }

    // Also handle Windows paths
    const char* winbase = strrchr(basename, '\\');
    if (winbase) {
        basename = winbase + 1;
    }

    // Remove .com extension if present
    std::string tool_name(basename);
    if (tool_name.size() > 4 && tool_name.substr(tool_name.size() - 4) == ".com") {
        tool_name = tool_name.substr(0, tool_name.size() - 4);
    }

    for (const Tool* t = tools; t->name; t++) {
        if (tool_name == t->name) {
            return t;
        }
        for (int i = 0; t->aliases[i]; i++) {
            std::string alias(t->aliases[i]);
            // Remove .com from alias too
            if (alias.size() > 4 && alias.substr(alias.size() - 4) == ".com") {
                alias = alias.substr(0, alias.size() - 4);
            }
            if (tool_name == alias) {
                return t;
            }
        }
    }
    return nullptr;
}

static void print_usage() {
    std::cerr << "Binaryen - WebAssembly toolchain\n";
    std::cerr << "Actually Portable Executable (APE) build\n\n";
    std::cerr << "Usage:\n";
    std::cerr << "  binaryen.com <tool> [options...]\n";
    std::cerr << "  binaryen.com --tool=<name> [options...]\n";
    std::cerr << "  <tool>.com [options...]  (via symlink)\n\n";
    std::cerr << "Available tools:\n";
    for (const Tool* t = tools; t->name; t++) {
        std::cerr << "  " << t->name << " - " << t->description << "\n";
    }
    std::cerr << "\nExamples:\n";
    std::cerr << "  binaryen.com opt -O3 input.wasm -o output.wasm\n";
    std::cerr << "  binaryen.com merge a.wasm b.wasm -o merged.wasm\n";
    std::cerr << "  binaryen.com --tool=wasm-opt --help\n";
}

int main(int argc, const char* argv[]) {
    if (argc < 1) {
        print_usage();
        return 1;
    }

    // First, check if invoked via a tool-specific name (symlink)
    const Tool* tool = find_tool(argv[0]);

    if (tool) {
        // Invoked as tool-specific binary
        return tool->main_func(argc, argv);
    }

    // Check for --tool= argument
    for (int i = 1; i < argc; i++) {
        if (strncmp(argv[i], "--tool=", 7) == 0) {
            tool = find_tool(argv[i] + 7);
            if (tool) {
                // Remove --tool= from arguments
                const char** new_argv = new const char*[argc];
                new_argv[0] = argv[0];
                int new_argc = 1;
                for (int j = 1; j < argc; j++) {
                    if (j != i) {
                        new_argv[new_argc++] = argv[j];
                    }
                }
                int result = tool->main_func(new_argc, new_argv);
                delete[] new_argv;
                return result;
            } else {
                std::cerr << "Unknown tool: " << (argv[i] + 7) << "\n\n";
                print_usage();
                return 1;
            }
        }
    }

    // Check if first argument is a tool name
    if (argc >= 2) {
        tool = find_tool(argv[1]);
        if (tool) {
            // Shift arguments: remove tool name from args
            return tool->main_func(argc - 1, argv + 1);
        }
    }

    // No tool specified
    if (argc == 1) {
        print_usage();
        return 0;
    }

    // Unknown command
    std::cerr << "Unknown command: " << argv[1] << "\n\n";
    print_usage();
    return 1;
}
