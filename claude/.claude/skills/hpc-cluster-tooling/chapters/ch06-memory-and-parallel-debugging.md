# Chapter 6: Memory & Parallel Debugging

## Core Idea
Two error classes dominate HPC debugging and resist ordinary GDB: **memory errors** (leaks, out-of-bounds, uninitialized reads — invisible because C/C++ don't bounds-check) and **parallel bugs** (deadlocks, races across MPI ranks/threads — timing-dependent and multiplied across processes). Each needs dedicated tooling: **Valgrind/sanitizers** for memory, **parallel debuggers** for distributed runs.

## Frameworks Introduced

- **Memory error detection**:
  - The hazards: **out-of-bounds** access (reading/writing past an array — undetected because there's no bounds checking), **uninitialized memory** use (reading a variable before assignment — like reading out of bounds, silently wrong), and **memory leaks** (allocating memory then losing the pointer).
  - **Valgrind/Memcheck**: runs the binary on a synthetic CPU, tracking every allocation and access — detects leaks, OOB, use-after-free, and uninitialized reads with no recompile. Thorough but slow (~10–50× slowdown). Other tools: DMALLOC, Electric Fence.
  - **Sanitizers** (compile-time, faster): `-fsanitize=address` (AddressSanitizer — OOB, use-after-free, leaks), `-fsanitize=undefined` (UBSan), `-fsanitize=thread` (data races). Far faster than Valgrind — run them routinely.

- **Parallel debugging** (across ranks/threads):
  - **MPI debugging with GDB**: attach a separate GDB to each rank, or launch one GDB-per-rank in separate terminals (`mpirun ... xterm -e gdb ...`). Practical for a few ranks; unwieldy at scale.
  - **Full-screen parallel debuggers** (DDT, TotalView): GUIs that control thousands of ranks at once — set breakpoints across all ranks, compare state, find which rank diverged. They integrate with the **batch system**: the GUI submits a job and attaches when it starts (or runs offline, emitting an HTML report).
  - The hard bugs: **deadlock** (ranks waiting on each other — mismatched blocking send/recv), **data races** (threads on shared memory), and bugs that only appear at scale or with specific rank counts.

## Key Concepts
- **Memory errors are silent in C/C++**: no bounds checking means OOB and uninitialized reads produce wrong results or sporadic crashes, not immediate errors — you need tools to surface them.
- **Sanitizers first, Valgrind for thoroughness**: ASan/TSan are fast enough to run on every test; Valgrind is the slow, exhaustive fallback.
- **Parallel bugs are timing- and scale-dependent**: a race or deadlock may appear only at certain rank counts or under certain interleavings — reproduce with the *minimal* rank count that triggers it.
- **Batch integration**: parallel debuggers must work through the scheduler — launch the job from the GUI, or run offline and read the report, since you can't interactively attach to a queued job.

## Mental Models
- **Run sanitizers on every parallel bug and crash** — ASan for memory errors, TSan for data races; they turn silent corruption and heisenbugs into deterministic, located reports. Valgrind when you need exhaustive coverage.
- **Reproduce parallel bugs at the smallest scale that triggers them** — a deadlock at 1024 ranks is far easier to debug at 2–4; shrink first.
- **For a few ranks, GDB-per-rank; for many, a parallel debugger** — manual per-rank GDB doesn't scale past a handful; DDT/TotalView control thousands at once.
- **Deadlocks and races are the signature parallel bugs** — a hang is usually a mismatched blocking exchange; wrong-but-not-crashing parallel results are usually a data race (run TSan).

## Code Examples
```bash
# Memory errors: sanitizers (fast) then Valgrind (thorough)
g++ -g -fsanitize=address solver.cpp -o solver && ./solver    # OOB, leaks, use-after-free
g++ -g -fsanitize=undefined solver.cpp -o solver && ./solver  # UB
valgrind --leak-check=full --track-origins=yes ./solver       # exhaustive

# Data races in threaded code
g++ -g -fsanitize=thread -fopenmp solver.cpp -o solver && ./solver

# Parallel MPI debugging: one GDB per rank (small scale)
mpirun -np 4 xterm -e gdb ./solver
# At scale: parallel debugger submits/attaches through the batch system
#   ddt --submit ./solver        (or run offline → HTML report)
```
- **What it demonstrates**: the sanitizer-then-Valgrind memory workflow, ThreadSanitizer for races, and GDB-per-rank vs a parallel debugger.

## Reference Tables

| Bug class | Tool | Cost |
|---|---|---|
| OOB / use-after-free / leak | AddressSanitizer | low |
| undefined behavior | UBSan | low |
| data race | ThreadSanitizer | medium |
| memory errors (exhaustive) | Valgrind/Memcheck | high (~10–50×) |
| MPI bug, few ranks | GDB per rank | manual |
| MPI bug, many ranks | DDT / TotalView | scales |

## Key Takeaways
1. Memory errors (OOB, uninitialized reads, leaks) are silent in C/C++ — surface them with AddressSanitizer (fast) or Valgrind (thorough).
2. Data races need ThreadSanitizer; UBSan catches undefined behavior — run sanitizers routinely on parallel bugs and crashes.
3. Parallel bugs are timing/scale-dependent — reproduce at the smallest rank count that triggers them.
4. Debug a few ranks with GDB-per-rank; use a parallel debugger (DDT/TotalView) for many ranks, integrated with the batch system.
5. Deadlock (hang) usually means a mismatched blocking exchange; wrong-but-running parallel results usually mean a data race.

## Connects To
- **Ch 05 (GDB)**: the single-process debugger these extend.
- **Ch 07 (Profiling)**: performance vs correctness — the other half of diagnosis.
- **Ch 08 (SLURM)**: parallel debuggers submit through the scheduler.
