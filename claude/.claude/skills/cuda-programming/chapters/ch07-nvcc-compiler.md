# Chapter 7: NVCC — The CUDA Compiler

## Core Idea
`nvcc` is a **driver toolchain**, not a single compiler: it splits a `.cu` file into host and device code, hands host code to a system C++ compiler, compiles device code to **PTX** (virtual ISA) per `compute_XY`, runs `ptxas` to turn PTX into **cubin** (real-ISA binary) per `sm_XY`, and packs multiple PTX + cubin targets into a **fatbin**. This is *offline* compilation (contrast `nvrtc`, the runtime JIT). What you embed — cubins for which architectures, plus PTX for forward-compatibility — is controlled by `-arch`/`-gencode`, and the rest of nvcc's flag surface tunes language standard, debugging, optimization, separate compilation, LTO, profiling, and fatbin size.

## Frameworks Introduced

- **nvcc compilation workflow**: source split → host compiler (host code) + GPU compiler (device → PTX per virtual ISA) → `ptxas` (PTX → cubin per real ISA) → fatbin container. `-v` prints the full tool invocation; `-keep` (+`--keep-dir`) preserves intermediates.
- **Architecture targeting** (`-arch`, `-gencode`, `-gpu-code`): choose virtual (`compute_XY`, emits forward-compatible PTX) vs real (`sm_XY`, emits cubin) targets; `native`/`all`/`all-major` convenience values.
- **Separate compilation** (`-rdc=true` / `-dc`): allow device functions/variables to link across compilation units (vs default whole-program). Enables modular GPU code at a possible perf cost recoverable via LTO.
- **Link-Time Optimization** (`-dlto`, `lto_<SM>`): optimize across separately compiled device objects at link time — recovers most whole-program performance while keeping modularity.
- **Host-compiler control** (`-ccbin`, `NVCC_CCBIN`, `-Xcompiler`): pick and pass flags through to the underlying host C++ compiler.

## Key Concepts
- **Source/header extensions**: `.cu` = device or mixed code; `.cuh` = CUDA header (device/mixed); `.c/.cpp/.cc/.cxx` and `.h/.hpp/...` = host-only by convention. Host-only units can be built by nvcc *or* the host compiler directly and linked later.
- **Default architecture**: nvcc targets the *earliest* supported `compute_XY`/`sm_XY` for max compatibility unless told otherwise.
- **`-arch` semantics**: `compute_80` → PTX only (forward-compatible, JIT at runtime); `sm_80` → PTX **and** cubin (forward-compatible); `native` → cubin for the detected GPU only (no PTX, no forward compat); `all`/`all-major` → cubins for all (major) archs + latest PTX.
- **Runtime linkage**: nvcc links the **static** CUDA runtime (`libcudart_static`) by default; `--cudart=shared` switches to `libcudart`.
- **CUDA 13 linkage change**: `__global__` functions and `__managed__`/`__device__`/`__constant__` variables now have **internal linkage by default** — cross-unit references need explicit `extern`.
- **Default optimization**: GPU code is built at `-O3` by default; `-G` disables optimizations (slower debug code); `-DNDEBUG` strips runtime asserts.
- **Fatbin compression**: on by default; tunable via `--compress-mode={default|size|speed|balance|none}` (default = `speed`).

## Mental Models
- Think of nvcc as a **conductor**: it doesn't play an instrument, it cues the host compiler, the GPU front-end, `ptxas`, and the fatbin packer in sequence.
- Think **PTX = forward-compatibility insurance, cubin = today's speed**: ship cubins for the GPUs you have *plus* PTX so future GPUs JIT it. `native` trades all insurance for the fastest build.
- Think of **separate compilation as a perf tax that LTO refunds**: whole-program is fastest but monolithic; `-rdc=true` modularizes; `-dlto` claws the optimization back at link time.

## Anti-patterns
- **Shipping `-arch=native` binaries for distribution**: produces cubin only for the build machine's GPU, with no PTX — it won't run on any other architecture.
- **Forgetting `extern` after the CUDA 13 internal-linkage change**: cross-unit `__device__`/`__global__` references silently fail to resolve.
- **Using separate compilation without LTO and then blaming the GPU**: device-link without `-dlto` loses cross-file optimization; measure with LTO before concluding.
- **Passing host-compiler flags directly to nvcc**: host flags must go through `-Xcompiler=...` (and ptxas args through `-Xptxas=...`); naked flags are misinterpreted.
- **Profiling without `-lineinfo`**: Nsight tools can't correlate to source lines; `-lineinfo` costs nothing at runtime.

## Reference Tables

**`-arch` value behavior**

| Value | Emits | Forward compatible? |
|---|---|---|
| `compute_XY` | PTX only | yes (JIT) |
| `sm_XY` | PTX + cubin | yes |
| `native` | cubin for current GPU | no |
| `all` | cubin for all archs + latest PTX | yes |
| `all-major` | cubin for all major archs + latest PTX | yes |

**Common option groups**

| Group | Flags |
|---|---|
| Targeting | `-arch`, `-gencode=arch=...,code=...`, `-gpu-code`, `--list-gpu-arch`, `--list-gpu-code` |
| Language | `-std={c++03..c++23}`, `-restrict`, `-extended-lambda`, `-expt-relaxed-constexpr` |
| Debug | `-g` (host), `-G` (device, sets `__CUDACC_DEBUG__`), `-lineinfo` |
| Separate comp / LTO | `-rdc=true`/`-dc`, `-dlto`, `arch=lto_<XY>` |
| Optimization | `-Xptxas=-maxrregcount=N`, `-extra-device-vectorization`, `-res-usage`, `-Xptxas=-warn-spills`, `-Xptxas=-warn-lmem-usage`, `-opt-info=inline` |
| Host compiler | `-ccbin`, `NVCC_CCBIN`, `-Xcompiler=...`, `--cudart={static|shared}` |
| Profiling | `-lineinfo`, `-src-in-ptx` |
| Fatbin | `-no-compress`, `--compress-mode=...` |
| Build speed | `-t N`, `-split-compile N`, `-split-compile-extended N`, `-Ofc N`, `-time <file>`, `-fdevice-time-trace` |

## Worked Example
Separate compilation: one unit *defines* device symbols, another *references* them via `extern`, compiled with `-dc` and device-linked:

```cpp
// ----- definition.cu -----
extern __device__ int device_variable = 5;
__device__        int device_function() { return 10; }

// ----- example.cu -----
extern __device__ int device_variable;
__device__        int device_function();

__global__ void kernel(int* ptr) {
    device_variable = 0;
    *ptr            = device_function();
}
```
```bash
nvcc -dc definition.cu -o definition.o
nvcc -dc example.cu    -o example.o
nvcc definition.o example.o -o program
```
- **What it demonstrates**: `-dc` compiles each `.cu` to a *relocatable* device object; the cross-unit `__device__` symbols are declared `extern` in the referencing unit (mandatory — and doubly so under CUDA 13's internal-linkage default); the final nvcc invocation performs the **device link** that resolves them. Add `-dlto` to all three commands (or use `-arch=lto_<XY>`) to recover whole-program performance.

## Key Takeaways
1. nvcc orchestrates host compiler + device→PTX + `ptxas`→cubin + fatbin packing; `-v` shows it, `-keep` saves intermediates.
2. `.cu`/`.cuh` carry device code; host-only units can be built by either compiler and linked at the end.
3. `-arch`: `compute_XY` = PTX (forward compat), `sm_XY` = PTX+cubin, `native` = fast build / no portability, `all[-major]` = ship everywhere.
4. Default = whole-program + static cudart + `-O3` device code. `--cudart=shared` for the shared runtime.
5. CUDA 13 made `__global__`/`__device__`/`__managed__`/`__constant__` internal-linkage by default — `extern` is required across units.
6. Separate compilation (`-rdc=true`/`-dc`) buys modularity at a perf cost; `-dlto` recovers it via link-time optimization.
7. Use `-lineinfo`/`-src-in-ptx` for profiling, `-Xptxas`/`-res-usage`/`-Xptxas=-warn-spills` for register/occupancy tuning, `-t`/`-split-compile` to parallelize builds.

## Connects To
- **Ch 1**: CC ↔ `sm_XY` ↔ PTX `compute_XY` and the cubin/fatbin compatibility rules — this chapter is how you *emit* them.
- **Ch 5**: `--default-stream per-thread` is an nvcc flag; `CUDA_LAUNCH_BLOCKING=1` complements `-G`/`-lineinfo` for debugging async errors.
- **Ch 6**: `__managed__` variables and their CUDA-13 internal-linkage behavior require `extern` in separate compilation.
- **`-Xptxas=-maxrregcount` / occupancy**: register budget directly affects warps-per-SM (SIMT performance, Ch 3).
- **FoBiS / build tooling**: for HPC Fortran+CUDA mixed builds, nvcc's `-ccbin` selects the host compiler the build system already manages.
