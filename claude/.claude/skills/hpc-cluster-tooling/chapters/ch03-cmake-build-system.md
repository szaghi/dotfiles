# Chapter 3: CMake — The Portable Build System

## Core Idea
CMake is a **meta-build system**: from a declarative `CMakeLists.txt` it *generates* native build files (Makefiles, Ninja, IDE projects) for whatever platform you're on. It handles portability, dependency discovery, and out-of-source builds — solving the problems that hand-written Makefiles can't across the heterogeneous machines of HPC.

## Frameworks Introduced

- **The CMake workflow** (configure → generate → build): two phases.
  1. **Configure/generate**: `cmake -B build -S .` reads `CMakeLists.txt`, probes the system (compilers, libraries), and writes native build files into `build/`.
  2. **Build**: `cmake --build build -j` invokes the generated Make/Ninja.
  - **Out-of-source builds** (`-B build`) keep all generated artifacts in a separate directory — source stays clean, multiple configurations coexist, `rm -rf build` is a full clean.

- **`CMakeLists.txt` essentials** (declarative project description):
  ```cmake
  cmake_minimum_required(VERSION 3.20)
  project(MyApp CXX)
  add_executable(myapp main.cpp solver.cpp)
  target_link_libraries(myapp PRIVATE m)
  ```
  - `add_executable`/`add_library` define targets; `target_link_libraries`/`target_include_directories`/`target_compile_options` attach properties (modern "target-based" CMake).

- **Dependency discovery**: `find_package(MPI REQUIRED)`, `find_package(OpenMP)`, `find_package(BLAS)` locate installed libraries and expose imported targets (`MPI::MPI_CXX`) to link against — portable across systems where libraries live in different places.

- **Build types & toolchains**: `-DCMAKE_BUILD_TYPE=Release` (sets `-O3`) / `Debug` (sets `-g`); toolchain files cross-compile for accelerators/clusters; cache variables (`-DVAR=value`) configure options.

## Key Concepts
- **Meta-build / generator model**: CMake doesn't build — it generates the builder. The same `CMakeLists.txt` produces Makefiles on Linux, Ninja, or IDE projects, which is the portability win.
- **Out-of-source is mandatory practice**: never configure in the source tree; `-B build` isolates generated files so `git status` stays clean and configurations don't collide.
- **Target-based modern CMake**: attach include dirs, flags, and link deps to *targets* (`target_*`) with `PRIVATE`/`PUBLIC`/`INTERFACE` scope — far more robust than global variables.
- **`find_package` for portability**: it abstracts where MPI/BLAS/HDF5 are installed; combined with Spack/modules, it makes builds reproducible across clusters.

## Mental Models
- **Describe the project, let CMake generate the build** — declare targets and their dependencies; CMake handles the platform-specific build-file generation. Don't hand-write Makefiles for portable projects.
- **Always build out-of-source** (`cmake -B build`) — keeps the source tree clean, lets Release and Debug configs coexist, and makes "clean" a directory delete.
- **Use target-based commands and `find_package`** — `target_link_libraries(app PRIVATE MPI::MPI_CXX)` is portable and scoped; avoid global `include_directories`/variables.
- **Set `CMAKE_BUILD_TYPE`** — Release for `-O3` production, Debug for `-g`; don't bake optimization flags in by hand.

## Code Examples
```cmake
cmake_minimum_required(VERSION 3.20)
project(Solver CXX)

find_package(MPI REQUIRED)
find_package(OpenMP)

add_executable(solver main.cpp solver.cpp io.cpp)
target_link_libraries(solver PRIVATE MPI::MPI_CXX)
if(OpenMP_CXX_FOUND)
  target_link_libraries(solver PRIVATE OpenMP::OpenMP_CXX)
endif()
```
```bash
# Out-of-source configure + build
cmake -B build -S . -DCMAKE_BUILD_TYPE=Release
cmake --build build -j$(nproc)
```
- **What it demonstrates**: dependency discovery with `find_package`, target-based linking, and the out-of-source workflow.

## Reference Tables

| Command | Role |
|---|---|
| `cmake -B build -S .` | configure + generate (out-of-source) |
| `cmake --build build -j` | build via generated Make/Ninja |
| `project()` / `add_executable()` | declare project / target |
| `target_link_libraries(t PRIVATE …)` | scoped dependency |
| `find_package(X REQUIRED)` | locate an installed library |
| `-DCMAKE_BUILD_TYPE=Release/Debug` | optimization vs symbols |

## Key Takeaways
1. CMake is a meta-build system: a declarative `CMakeLists.txt` generates native build files (Make/Ninja) for any platform — the portability solution.
2. Always build out-of-source (`cmake -B build`) — clean source tree, coexisting configs, trivial clean.
3. Use modern target-based commands (`target_link_libraries`/`target_include_directories` with PRIVATE/PUBLIC scope), not global variables.
4. `find_package` discovers MPI/BLAS/HDF5 portably; pair with Spack/modules for reproducible cluster builds.
5. Set `CMAKE_BUILD_TYPE` (Release/Debug) rather than hardcoding optimization flags.

## Connects To
- **Ch 02 (Make)**: CMake generates Makefiles; understanding Make explains what CMake produces.
- **Ch 01 (Unix/modules)**: `find_package` works with module-loaded libraries.
- **Ch 05–06 (Debugging)**: Debug build type sets `-g` for the debugger.
