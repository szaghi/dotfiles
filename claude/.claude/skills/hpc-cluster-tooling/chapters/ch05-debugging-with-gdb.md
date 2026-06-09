# Chapter 5: Debugging with GDB

## Core Idea
A debugger lets you stop a program mid-execution and inspect its state — the fastest way to find why code crashes or computes wrong values. **GDB** is the standard Unix debugger; the prerequisite is compiling with **`-g`** (debug symbols) so the debugger can map machine addresses back to source lines and variable names.

## Frameworks Introduced

- **Compiling for debug** (`-g`): adds the **symbol table** to the binary — the mapping from machine code/addresses to source lines, function names, and variables. Without it, GDB shows raw addresses; with it, it shows your code. Best paired with **`-O0`** so the optimizer doesn't reorder/eliminate code and confuse line mapping.

- **The core GDB commands** (control + inspect):
  - **Run**: `run [args]` (start), `continue` (resume to next breakpoint), `step` (into calls), `next` (over calls), `finish` (run to function return).
  - **Breakpoints**: `break file:line` / `break func` (stop there), `break … if cond` (conditional), `watch var` (stop when a variable changes — invaluable for "who corrupted this?").
  - **Inspect**: `print expr` (evaluate/show), `backtrace` (the call stack at the current point), `frame N` (switch stack frame), `info locals`, `list` (show source).

- **Post-mortem debugging**: when a program segfaults, it can dump a **core** file (`ulimit -c unlimited` to enable). `gdb program core` loads the crash state — `backtrace` immediately shows where and how it died, without re-running.

## Key Concepts
- **`backtrace` is the first move on a crash**: it shows the chain of function calls that led to the failure — usually pinpointing the bug's location instantly.
- **`watch` for corruption bugs**: when a value is mysteriously wrong, set a watchpoint on it; GDB stops the instant anything modifies it, revealing the culprit.
- **Conditional breakpoints** for iteration bugs: `break solver.cpp:42 if i == 1000` stops only at the problematic iteration, not every loop pass.
- **Optimized builds confuse debugging**: `-O2`/`-O3` reorder and inline code, so line numbers and variables may not map cleanly — debug at `-O0 -g`, then verify the optimized build separately.

## Mental Models
- **Always compile with `-g` (and `-O0`) before debugging** — without symbols GDB is nearly useless; without `-O0` the line mapping lies.
- **On any crash, load the core and `backtrace` first** — it's the single most informative action; you see the call chain to the failure without reproducing it interactively.
- **Use `watch` to catch who changes a value** — for corruption/aliasing bugs, a watchpoint finds the writer that a breakpoint-and-step hunt would take ages to locate.
- **Conditional breakpoints to skip to the interesting iteration** — don't single-step a million loop iterations; break on the condition that triggers the bug.

## Code Examples
```bash
# Build for debugging
g++ -g -O0 solver.cpp -o solver

# Post-mortem: enable cores, run, then inspect the crash
ulimit -c unlimited
./solver            # segfaults, dumps core
gdb ./solver core
  (gdb) backtrace            # where did it die?
  (gdb) frame 2             # move to the relevant stack frame
  (gdb) print n            # inspect a variable
  (gdb) list               # show the source there

# Interactive: conditional breakpoint + watchpoint
gdb ./solver
  (gdb) break solver.cpp:42 if iter == 1000
  (gdb) run
  (gdb) watch residual     # stop when residual changes
  (gdb) continue
```
- **What it demonstrates**: post-mortem core analysis, conditional breakpoints, and watchpoints.

## Reference Tables

| Command | Action |
|---|---|
| `run` / `continue` | start / resume |
| `step` / `next` / `finish` | into / over / out of calls |
| `break file:line [if cond]` | (conditional) breakpoint |
| `watch var` | stop when var changes |
| `backtrace` / `frame N` | call stack / switch frame |
| `print expr` / `info locals` | inspect values |
| `gdb prog core` | post-mortem crash analysis |

## Key Takeaways
1. Compile with `-g` (symbol table) and ideally `-O0` so GDB maps addresses to source lines and variables.
2. On a crash, enable cores (`ulimit -c unlimited`) and load `gdb prog core`; `backtrace` shows the call chain to the failure.
3. Use conditional breakpoints (`break … if cond`) to skip to the failing iteration, not single-step millions.
4. Use `watch` to catch what modifies a corrupted value — the fast path for aliasing/corruption bugs.
5. Optimized builds confuse line mapping — debug at `-O0 -g`, then validate the optimized build separately.

## Connects To
- **Ch 06 (Memory/parallel debugging)**: Valgrind and parallel GDB extend this to memory errors and MPI.
- **Ch 02–03 (Build)**: `-g` is a compiler flag set via Makefile/CMake Debug build.
- **Ch 01 (Unix)**: GDB is a command-line tool driven from the shell.
