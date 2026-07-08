## GPU / OpenACC / CUDA Conventions

### Reference Skills — consult the spec, don't answer from memory
When a question turns on the **semantics of a parallel-programming standard** (directive/clause, or
library API/protocol), invoke the matching reference skill and ground the answer in it — do **not**
recall the semantics from training memory (data-movement, async-ordering, data-sharing-vs-mapping,
memory-model, send-mode/completion, and collective/RMA-synchronization rules are subtle, deadlock-prone,
and version-sensitive):
- **OpenACC** (`#pragma acc`/`!$acc`, data clauses, gang/worker/vector, async, `routine`, `acc_*`, v3.4) → **`openacc-3.4`** skill.
- **OpenMP** (`#pragma omp`/`!$omp`, data-sharing/mapping clauses, `target` offload, tasking/`depend`, `schedule`, flush memory model, `omp_*`, v6.0 + Nov-2025 errata) → **`openmp-6.0`** skill.
- **MPI** (`MPI_*`/`mpi_f08`, send modes, nonblocking/collective/RMA semantics, datatypes, communicators, MPI-IO, thread levels, Sessions, the v5.0 ABI) → **`mpi-5.0`** skill.

These conventions are *house style and hard-won project gotchas*; the skills are the *authority on the
standards*. (Fortran base-language rules → `fortran-2023-standard`; CUDA/vendor-compiler/implementation-specific
behavior → that vendor's docs, not these skills.)

### OpenACC Directives
- Always use `!$acc parallel loop` with explicit `gang`, `vector`, `seq` clauses — never bare `!$acc kernels` (compiler may silently under-parallelize)
- Specify `collapse(N)` depth explicitly on nested loops
- Use `-Minfo=accel` (nvfortran) to verify compiler parallelization decisions

### Device Variable Declaration Rules
Which variables need `!$acc declare` in a module:

| Variable type | Needs `!$acc declare`? | Directive |
|---|---|---|
| Scalar `parameter` | No | Inlined at compile time |
| Array `parameter` | Yes | `!$acc declare copyin(arr)` |
| Module `allocatable` | Yes | `!$acc declare create(arr)` |
| Module fixed-size | Yes | `!$acc declare create(arr)` |
| Local variable | No | Use `private` clause instead |
| Subroutine argument | No | Use `deviceptr` or data clauses |

- Module-level variables **cannot** use the `private` clause — this causes "No device symbol for address reference"; only local variables can be `private`
- After allocating a module `allocatable` on the host, call `!$acc update device(arr)` to populate the device copy

### Data Movement
- Minimize host↔device transfers; maximize data reuse on device
- Unstructured data regions (`enter data`/`exit data`) require explicit lifetime management — missing `exit data` leaks device memory
- Missing `update device`/`update host` causes stale data bugs that are hard to diagnose
- Use `present` clause to assert data residency; assertion failures surface bugs early

### GPU ↔ MPI Coherence

When MPI ranks own GPU-resident data, every halo/boundary exchange has a coherence
contract that the compiler will not enforce: the buffer sent must be the most recent
*host* copy, and the buffer received must be propagated back to the *device* copy.
Skipping either side produces stale-data bugs that pass smoke tests and silently
diverge under refinement.

The rule, in two lines:

- Before `MPI_Send` / `MPI_Isend` / `MPI_*_all*` from a device buffer: `!$acc update host(buf)` (or `!$omp target update from(buf)`).
- After `MPI_Recv` / `MPI_Irecv` into a device buffer: `!$acc update device(buf)` (or `!$omp target update to(buf)`).

```fortran
! Non-GPU-aware MPI — explicit host staging required
!$acc update host(send_buf)
call MPI_Sendrecv(send_buf, n, MPI_R8P, dst, tag, &
                  recv_buf, n, MPI_R8P, src, tag, comm, status, ierr)
!$acc update device(recv_buf)
```

GPU-aware MPI (CUDA-aware OpenMPI/MPICH, ROCm-aware MPI, Cray MPICH+GTL) lets the MPI
call read/write device pointers directly and removes the staging — but only if the build,
the runtime, and the device buffer registration are all aligned. Default to host staging
and only enable GPU-aware MPI behind a build-time or env-var toggle (e.g. `*_GPU_AWARE_MPI=1`)
with the staging path remaining available as fallback. The toggle exists because GPU-aware
MPI fails opaquely on misconfigured clusters and you need a working baseline to bisect against.

Forensic hint: if a multi-rank GPU run gives bit-identical results to a single-rank run
on small grids but diverges as the decomposition is refined, suspect a missing
`update host` before a send or `update device` after a receive. The halo region is
the prime suspect.

**Multi-realm: never read program-scope singletons inside a per-realm GPU object.** When a
solver supports multiple concurrent domains/realms over one `MPI_COMM_WORLD`, program-scope
"singleton" shims (grid/field/maps bound to "the last-initialized realm") silently give a GPU
object another realm's decomposition — its halo exchange indexes the wrong comm map into its
own device buffers, a silent cross-realm corruption with no abort. Pass the realm-local CPU
objects (and per-rank comm-map offset arrays) in as dummy arguments from the caller's own
`self%...`; reserve singletons for genuinely program-global state (the MPI handler — one
rank/world/device). Cache scalars (`ngc`, `ni/nj/nk`, `nv`) on the object via `self%`, not by
reaching into a `grid%`/`field%` global.

### Device Code Pitfalls
- **Never pass strided sections of shared device arrays from inside a kernel** (e.g. `call op(dxyz=dxyz_gpu(b,1:3), ...)` inside a `collapse` region): the compiler materializes the section into a temporary that is **not privatized** — threads race on it. The race is *value-invisible when all threads write equal values* (uniform grids, constant coefficients) and destructive the moment per-thread values differ (measured: ADAM #22, nvfortran 26.1 — AMR 2:1 level mixes corrupted the field nondeterministically while every uniform-grid golden stayed bit-perfect). *How to apply:* hoist into a `private` fixed-size local (`dxyz_b(3)` filled by scalar assignments) before the call, or pass the full array plus scalar indices.
- **`associate` variables in OpenACC regions**: use `copyin`, not `firstprivate` — `firstprivate` fails with some compilers
- **Assumed-shape with non-default lower bounds** in device routines: pass bounds explicitly as integers and use them for indexing
- **Private arrays inside CONTAINED OpenACC kernels are not trustworthy on nvfortran (observed on 26.1).** Two failure layers, measured in ADAM #22: (a) runtime-sized automatic private arrays (`buf(1-s:1+s)` with `s` a dummy) are mis-privatized — scheduling-dependent garbage that grows with gang count (kicked in above ~32 blocks/rank); (b) even with **compile-time-constant bounds**, private arrays of a *contained* (internal) kernel procedure can still bleed between threads — one variable's stencil fill landing in another thread's buffer (signature: two diagnostics tracking each other, e.g. `div(J) ≈ div(D)` with J identically zero). *How to apply:* in diagnostics and other simple kernels, prefer **buffer-free scalar accumulation** (e.g. pair-form `FD1_CC` sums) over private stencil arrays; where arrays are unavoidable, use module-level (non-contained) kernel subroutines with `parameter`-bounded locals, and validate with data that makes a race *visible* (next rule).
- **Zero (or uniform) planes make races invisible.** A race that mixes two threads' values is undetectable when those values coincide — zeros racing zeros, or equal per-block constants racing each other. A kernel "validated" on such data is not validated (ADAM #22: the uniform-grid exact-0.0 result was vacuous for the buffer race).

### Atomic Operations — Red Flag
- GPU atomics cause severe serialization (observed: 10–100× slowdown on vertex-based ops)
- Before using atomics, consider: graph coloring, data reordering, privatization, or `reduction` clause

### Floating-Point Reproducibility
- Non-associative MPI reductions produce different results with different process counts — document or design around it
- GPU atomics introduce non-determinism — document explicitly or eliminate

### Correctness and Debugging Tools
- Development builds: `-fbounds-check -fcheck=all` (GNU), `-check all -traceback` (Intel)
- FP exception trapping: `-ffpe-trap=invalid,zero,overflow` (GNU) — enable during development to catch NaN/Inf at source
- CPU memory: Valgrind; GPU memory: `cuda-memcheck` / `compute-sanitizer`
- OpenACC runtime diagnostics: `NV_ACC_DEBUG=1`; `ACC_SYNCHRONOUS=1` for immediate (synchronous) error reporting
- Check data residency at runtime: `acc_is_present(arr, size(arr))`
- Stack size: run `ulimit -s unlimited` before Fortran programs with deep recursion
- MPI hangs: first diagnostic — set `MPICH_ASYNC_PROGRESS=1` or `OMPI_MCA_opal_progress_threads=1`; reduce to 2 ranks to isolate
- **Optimized-build backtraces lie.** A `-fast`/`-O2+` traceback frame is often mis-resolved: if the apparent crash line *marches forward* or *vanishes* as you add prints around it, the frame is an artifact, not the fault site. Localize a crash by step-by-step `write`/`flush` instrumentation (or a debug `-O0 -g` rebuild) before theorizing a cause from the frame.
- **Uniform-grid validation cannot exonerate value-coincident races — vary the data, not just the size.** Goldens and scaling runs on uniform grids/levels leave every "wrong-source-but-equal-value" race green (wrong block's `dxyz`, wrong thread's buffer, duplicate ghost writers that agree). To actually test race-freedom: run the same case **twice and diff bit-for-bit** (nondeterminism = race, full stop); compare against the CPU backend on a case where per-thread values *differ* (multi-level AMR, spatially varying coefficients); and judge by **state dumps (restart files, field h5), never by derived diagnostics** — a racing diagnostic kernel can fabricate garbage over a bit-perfect solution, and a fixed solution can hide behind a still-lying diagnostic (both happened, stacked, in ADAM #22). `compute-sanitizer` memcheck/initcheck are blind to in-bounds private-memory races and to garbage arriving via H2D from uninitialized host memory.

### Conservation Diagnostic Normalisation
- Never normalise a CFD conservation drift by the signed integral of the field. For any conservative variable whose physical mean is zero by symmetry (momentum components of a zero-mean perturbation, anti-symmetric fields), `s0 = sum(U_init)` is structurally O(eps) — dividing absolute drift by `|s0|` then explodes by `1/eps`. Symptom: drift = 3.4e+305 (= `1/tiny`). *How to apply:* normalise by a positive norm — `sum(abs(U_init(...)))` (L1), `sqrt(sum(U_init**2))` (L2), or a problem-specific reference scale (freestream, max). Same rule for relative error of any field that can be zero-mean. When a CFD diagnostic produces huge numbers (1e+200+) early in a run, suspect denominator collapse before solver instability.

### Diagnostic Precision Floor — pairwise/Kahan sum in measurements
- When measuring FP64-quality results, the diagnostic's own rounding error must be below the threshold being measured. The intrinsic Fortran `sum()` over N elements gives O(N·eps) error in the worst case. Reading at the machine-eps floor with naive sum over 4096 elements gives 4e-13 of diagnostic noise — masking any kernel error below that. *How to apply:* use a recursive **pairwise (tree) sum** for any diagnostic that sums >32 numbers and intends to read FP64-quality results — O(log N · eps) error, cache-friendly base case of 8 elements summed naively. For very long sums or eps-exact reads, use Kahan/Neumaier-compensated sum (O(eps) regardless of N). *Symptom:* a "high-precision" baseline reports an error suspiciously close to `N · eps` rather than `eps`. Check the diagnostic before suspecting the kernel.

### GPU Benchmark Timing
- **`!$acc wait` (OpenACC) or `!$omp taskwait` (OpenMP target) immediately before every stop-time read.** Without it, async kernel launches return instantly and you measure launch latency (μs), not work completion (ms–s). Sub-millisecond "GPU speedups" are almost always this bug.
- **`system_clock` for wall time, never `cpu_time`.** `cpu_time` measures CPU thread time; the CPU thread is idle waiting on the device, so `cpu_time` reports near-zero — meaningless.
- Bracket the timed region: `wait → wall_clock(t0) → kernels → wait → wall_clock(t1)`. The starting wait ensures warmup has fully completed.
- Structured `!$acc data` regions around the whole driver eliminate per-step H↔D transfers — without them the "timed" region measures transfer cost, not device-side throughput. Always pair structured data regions with wait-bracketed timing.
- If a reported GPU speedup is >100× over CPU on a non-trivial kernel, the first hypothesis is "the timer is wrong," not "the kernel is amazing."

### Mixed Precision on Consumer GPUs — the FP64 Trap
NVIDIA consumer GPUs (RTX 30/40/50 — Ampere, Ada, consumer Blackwell) have an FP64:FP32 ALU throughput ratio of **1:64**. Datacenter GPUs (H100, B200) have **1:2**. This is deliberate market segmentation, not silicon accident.

**The consequence:** "FP32 storage + FP64 compute" — textbook or surgical — is *strictly slower than full FP64* on consumer GPU. The FP64 work is the bottleneck; cutting storage to FP32 doesn't help, and promote/demote latency adds cost on top of unchanged FP64 ALU work. *Surgical* promotion of only the cancellation-sensitive sub-expression (e.g. WENO5 β-indicators) is even worse than blanket promotion.

Measured (RTX 4070 Ada, WENO5 stencil, 208 MiB per array, 100 steps, with pairwise-sum diagnostic):

| Variant                                | speedup vs FP64 | errMax  | drMax       |
|----------------------------------------|----------------:|--------:|------------:|
| V1  FP64 throughout                    |           1.00× | 0       | 1.8e-16 (= eps_R8P) |
| V2  FP32 store + FP64 compute (blanket)|           0.99× | 6.4e-7  | 5.4e-8      |
| V3  FP32 throughout (naive)            |          14.55× | 1.1e-6  | 5.4e-8      |
| V2b FP32 + FP64 β-indicators only      |           ~1.0× | 6.4e-7  | 5.5e-8      |
| V3b FP32 + Neumaier-compensated RK1    |          13.64× | 9.0e-7  | 4.1e-9      |
| V3c FP32 + Klein 2nd-order RK1         |          12.48× | 9.0e-7  | 6.7e-9      |

Four counterintuitive empirical facts:
1. **Surgical FP64 promotion (V2b) is in the same trap regime as blanket (V2)** — any FP64 work in the inner loop engages the FP64 datapath. The "promote only the cancellation-sensitive parts" recipe fails on consumer silicon.
2. **The dominant FP32 error is per-step storage round-trip, not β cancellation** — V2 and V2b give identical errMax. The only way to fix the L2 floor would be storage-level (Dekker double-FP32 pair); selectively promoting expressions does not.
3. **Compensated FP32 (V3b: Neumaier-accumulated RK) gives 13× better conservation drift at only 9% speedup cost** vs naive FP32. For long-trajectory CFD where drift matters most, V3b strictly dominates V3.
4. **Higher-order compensation (V3c: Klein 2nd-order) is WORSE than first-order Neumaier at typical step counts.** First-level carry doesn't saturate until ≥10⁴ steps of typical dt·rhs, so second-level compensator catches nothing. V3c crosses over V3b on drift only at very long trajectories. **Default to first-order Neumaier, not higher-order cascades**, unless the trajectory genuinely exceeds 10⁴ steps.

On CPU the same kernel gives mixed ≈ FP32 ≈ 1.3× — the regime flips depending on the target's FP64:FP32 ratio. Datacenter GPUs keep CPU-like intuition; consumer GPUs invert it.

**How to apply:** For HPC code targeting consumer GPUs:
- **Three viable strategies:** all-FP64, naive all-FP32, all-FP32 with Kahan/Neumaier-compensated time integration. Default to compensated FP32 (V3b pattern) for any long-trajectory or conservation-sensitive work — the 9% speedup loss is paid back many times over in drift quality.
- **Three dead ends:** "FP32 storage + FP64 compute" (blanket V2 OR surgical V2b), and Klein second-order compensation (V3c) at typical step counts. V2/V2b fail because any FP64 work in the inner loop engages the slow datapath; V3c fails because its second-level compensator has nothing to catch in normal trajectories.
- Iterative refinement at the linear-solve level (factor in FP32, residual in FP64, correct) still works when FP32 work dominates — the FP64 residual is cheap *relative to* the FP32 factor cost. This is a different regime where FP64 work is amortised over many FP32 operations.
- Tensor Cores (FP16/BF16 + FP32 accumulate) remain valid for matmul-shaped sub-problems but require iso_c_binding to CUDA WMMA — not reachable from pure Fortran. Stencils are not matmul-shaped.
- Before recommending mixed-precision storage for a consumer-GPU workload, ask: "does this code do *any* FP64 work in the inner loop?" If yes, the recipe fails.
- nvfortran 26.1 `-fast` preserves Kahan/Neumaier compensation when an explicit branch (`if (abs(u_old) >= abs(y))`) is present — the branch blocks algebraic re-association. Verified by PTX inspection. Branchless variants (Sum2/Ogita) may behave differently — verify before assuming.

### Compiler Pitfalls

#### gfortran -O2 bug: pointer array + assumed-shape dummy with explicit lower bounds
When an actual argument is a **pointer array section** (lb=1, from Fortran section rules) passed
to a dummy with explicit lower bounds (e.g. `q(1-ngc:,...)`), gfortran -O2+ computes a wrong
C data pointer. This causes `errno=14 EFAULT` in HDF5 writes. Works at -O0/-O1 and nvfortran.

**Fix**: use separate routines for pointer-derived actuals — declare dummy as `q(:,:,:,:)` (no
explicit lb) and pass `nijk` directly. For scalar rank-3 fields use explicit-shape
`q(ijk(1,1):ijk(2,1),...)` to bypass the descriptor entirely.
Individual `-fno-*` flags do not isolate the trigger. Do not use allocatable copies as a workaround — allocation overhead is unacceptable in HPC hot paths.

