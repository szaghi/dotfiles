---
title: HPC modules (Lmod)
---

# HPC modules (Lmod)

The `modules/` package holds Lmod modulefiles for the hand-installed HPC toolchains: GCC, the NVIDIA HPC SDK, Intel
oneAPI, an AMD SDK and Open MPI builds. The toolchains live under `/opt` and no distro package manages them, so each
modulefile records where one is installed and what loading it changes. Stow deploys `modules/.modules/` to
`~/.modules/`.

```bash
bash ~/dotfiles/dotify.sh modules
sudo apt install lmod     # adam (Ubuntu/WSL2)
yay -S lmod               # Arch / CachyOS (AUR)
```

## Usage

```bash
module avail                          # list the modulefiles
module load nvhpc/26.9                # NVIDIA HPC SDK 26.9
module load openmpi/5.0.11-gnu16.2.0  # Open MPI 5.0.11, pulls in gcc/16.2.0
module list
module purge
```

`bash/.bash/exports` initialises Lmod and sets the search path:

```bash
if [ -f /usr/share/lmod/lmod/init/bash ]; then
  source /usr/share/lmod/lmod/init/bash
fi
export MODULEPATH="$HOME/.modules"
```

`MODULEPATH` is set, not prepended: only these modulefiles are visible. `~/.modules` is a single stow link to the
directory in the repository, so a new modulefile is visible at once, with no re-stow.

The prompt shows the loaded modules: `prompt_lmod` in `bash/.bash/prompt` prints `LOADEDMODULES` with spaces, after
`env`, as in `env {gcc/16.2.0 openmpi/5.0.11-gnu16.2.0}`. With nothing loaded it prints nothing.

## Modulefiles

Every modulefile in `modules/.modules/`. "Current" is the toolchain in use since 2026-10-16. "Default" is the version
Lmod picks for a bare `module load <name>`, as reported by `module --default avail`; no `.version` or `default` file
pins it, so it is the highest version.

| Module | Install root | Status |
|---|---|---|
| `nvhpc/26.9` | `/opt/nvidia/hpc_sdk/Linux_x86_64/26.9` | Current, default |
| `nvhpc/26.5` | `/opt/nvidia/hpc_sdk/Linux_x86_64/26.5` | Stale, installed |
| `nvhpc/26.1` | `/opt/nvidia/hpc_sdk/Linux_x86_64/26.1` | Stale, installed |
| `nvhpc/26` | `/opt/nvidia/hpc_sdk/Linux_x86_64/2026` | Stale, installed |
| `nvhpc/25` | `/opt/nvidia/hpc_sdk/Linux_x86_64/2025` | Stale, installed |
| `gcc/16.2.0` | `/opt/gcc/bin/16.2.0` | Current, default |
| `gcc/15.2.0` | `/opt/gcc/bin/15.2.0` | Stale, installed |
| `gcc/15.1.0` | `/opt/gcc/bin/15.1.0` | Stale, installed |
| `openmpi/5.0.11-gnu16.2.0` | `/opt/openmpi/bin/5.0.11/gnu/16.2.0` | Current, default; depends on `gcc/16.2.0` |
| `openmpi/5.0.10-gnu15.2.0` | `/opt/openmpi/bin/5.0.10/gnu/15.2.0` | Stale, installed; depends on `gcc/15.2.0` |
| `openmpi/5.0.7-gnu14.2.0` | `/opt/openmpi/bin/5.0.7/gnu/14.2.0`, HDF5 1.14.6 in `/opt/HDF5/bin/1.14.6/gnu/14.2.0` | Stale, installed; depends on `gcc/15.1.0` |
| `openmpi/5.0.10-gnu16.1.1` | `/opt/openmpi/5.0.10/gnu/16.1.1` | quark only: built with the system GCC, refuses to load on any other host |
| `intel/oneapi` | `/opt/intel/oneapi/setvars.sh` | Installed on adam |
| `amd/5.1.0` | `/opt/amd/rocm-afar-6711-drop-5.1.0` | Not installed on adam; loading fails |

"Installed" was checked on adam (2026-11-05) against each modulefile's root.

| Family | Sets |
|---|---|
| `gcc/*` | `PATH`, `LD_LIBRARY_PATH` and `LD_RUN_PATH` (`lib64`, `lib`), `MANPATH`, `INFOPATH`, `PKG_CONFIG_PATH`; `GCC_HOME`; `CC=gcc`, `CXX=g++`, `FC`/`F77`/`F90=gfortran` |
| `nvhpc/*` | `PATH` (`compilers/bin`, `comm_libs/mpi/bin`), `LD_LIBRARY_PATH` (`compilers/lib`, `/usr/lib/wsl/lib`), `MANPATH`; `NVHPC_ROOT`; `CC=nvc`, `CXX=nvc++`, `FC`/`F77`/`F90=nvfortran`; the WSL2 MPI/UCX workarounds below; an `mpirun` alias |
| `openmpi/*` | `PATH`, `LD_LIBRARY_PATH`, `LD_RUN_PATH`, `MANPATH`; `MPICC=mpicc`, `MPICXX=mpicxx`, `MPIFC`/`MPIF77`/`MPIF90=mpifort` |
| `intel/oneapi` | Sources `setvars.sh --force` on load; `CC=icx`, `CXX=icpx`, `FC`/`F77`/`F90=ifx` |
| `amd/5.1.0` | `PATH`, `LD_LIBRARY_PATH`, `MANPATH` only; no compiler variables |

### WSL2 workarounds in nvhpc

The `nvhpc` modules from 26 onward set these, and explain each in their `help()`:

| Setting | Reason |
|---|---|
| `/usr/lib/wsl/lib` on `LD_LIBRARY_PATH` | WSL GPU driver shim |
| `UCX_MEMTYPE_CACHE=n` | WSL memory-type detection is unreliable |
| `UCX_RNDV_THRESH=inf` | Device-memory rendezvous aborts through `/dev/dxg`; forces eager |
| `UCX_TLS=^cma` | CMA same-node shared memory is broken on WSL |
| `OMPI_MCA_pml=ucx` | Selects the UCX point-to-point layer |
| `OMPI_MCA_coll_hcoll_enable=0` | hcoll offload needs InfiniBand hardware that is absent |

`nvhpc/25` sets only the first two, plus an `mpirun` alias carrying the UCX and hcoll flags.

::: warning Never copy these into a cluster job
Each setting is right on the WSL2 box and a performance regression, or meaningless, on InfiniBand with GPUDirect
RDMA. Cluster jobs use the cluster's own environment scripts.
:::

## Adding a modulefile

Create `modules/.modules/<name>/<version>.lua`; Lmod sees it at once. Template for a compiler:

```lua
whatis("Toolchain name and version")
help([[Longer description: install path, what is included, WSL2 notes.]])

local root = "/path/to/install"
family("compiler")

if not isDir(root) then
  LmodError(root .. " not found")
end

prepend_path("PATH",            pathJoin(root, "bin"))
prepend_path("LD_LIBRARY_PATH", pathJoin(root, "lib"))
prepend_path("MANPATH",         pathJoin(root, "share/man"))

setenv("CC",  "gcc")
setenv("CXX", "g++")
setenv("FC",  "gfortran")
setenv("F77", "gfortran")
setenv("F90", "gfortran")
```

Conventions:

- Guard the install path with `isDir(root)` (or `isFile` for a script, as `intel/oneapi` does) and `LmodError`, so a
  missing toolchain fails at load time with its path in the message.
- `family("compiler")` on every compiler module: Lmod then keeps one compiler loaded at a time and swaps on load.
- Set `CC`, `CXX`, `FC`, `F77` and `F90`.
- Build paths with `pathJoin(root, "subdir")`, not string concatenation.
- NVHPC on WSL2: prepend `/usr/lib/wsl/lib` to `LD_LIBRARY_PATH` and set `UCX_MEMTYPE_CACHE=n`.
- An MPI module names its compiler with `depends_on("gcc/<version>")`, which loads it when it is not already loaded.
- A build that exists on one host only checks `hostname -s` with `capture()` and calls `LmodError` elsewhere, as
  `openmpi/5.0.10-gnu16.1.1` does.

Check with `module avail` and `module load <name>/<version>`.

## Things to know

- **`module load` does nothing useful in a non-interactive shell.** `~/.bashrc` returns at its PS1 guard before it
  sources `~/.bash/exports`, so `ssh host cmd`, `bash -c` and scripts get neither the `module` function nor
  `MODULEPATH`. Export the paths of the current toolchain directly instead:

  ```bash
  export PATH=/opt/gcc/bin/16.2.0/bin:/opt/openmpi/bin/5.0.11/gnu/16.2.0/bin:$PATH
  export LD_LIBRARY_PATH=/opt/gcc/bin/16.2.0/lib64:/opt/gcc/bin/16.2.0/lib:/opt/openmpi/bin/5.0.11/gnu/16.2.0/lib:$LD_LIBRARY_PATH
  ```

  For NVHPC the root is `/opt/nvidia/hpc_sdk/Linux_x86_64/26.9`; the subdirectories are in the table above.
- **Fortran `.mod` files work only with the compiler that wrote them.** After switching toolchain, build clean.
- **`openmpi/5.0.7-gnu14.2.0` depends on `gcc/15.1.0`**, not on the GCC 14.2.0 it was built with: no `gcc/14.2.0`
  modulefile exists.
- The `openmpi` modules declare no `family`: two of them can be loaded together.
- `intel/oneapi` cannot be unloaded cleanly, because `setvars.sh` is sourced on load. Run `module purge` and open a
  fresh shell.
