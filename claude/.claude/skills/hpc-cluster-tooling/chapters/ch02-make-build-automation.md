# Chapter 2: Make — Build Automation

## Core Idea
`make` automates rebuilding: you declare **targets**, their **prerequisites**, and the **rules** to produce them, and `make` rebuilds only what's out of date by comparing file timestamps. This dependency-driven, incremental model is the foundation of reproducible builds — and the engine CMake generates.

## Frameworks Introduced

- **The rule model** (target : prerequisites ; recipe):
  ```makefile
  target: prerequisite1 prerequisite2
  	recipe-command            # MUST be a TAB, not spaces
  ```
  - `make` checks timestamps: if any prerequisite is newer than the target, it runs the recipe. This is **incremental builds** — only stale targets rebuild.
  - **Recipe lines must start with a TAB** — the #1 Makefile error (spaces silently break it).

- **Automatic variables** (write rules once): `$@` (the target), `$<` (first prerequisite), `$^` (all prerequisites). These let one rule serve many files.

- **Pattern rules & implicit rules**: `%.o: %.c` compiles any `.c` to `.o`; `make` has built-in implicit rules for common compilations. **Wildcards** (`$(wildcard *.c)`) gather files.

- **Variables**: `CC = gcc`, `CFLAGS = -O3`, referenced as `$(CC)`. Override on the command line (`make CFLAGS=-g`).

- **Phony targets**: `.PHONY: clean all` declares targets that aren't files (so `make clean` always runs even if a file named `clean` exists).

## Key Concepts
- **Timestamp-based incremental rebuild**: the core value — `make` rebuilds only what changed (and what depends on it), making large-project rebuilds fast.
- **Dependency graph**: targets + prerequisites form a DAG; `make` walks it bottom-up, rebuilding stale nodes. Correct dependencies are essential — a missing one means stale builds.
- **TAB vs spaces**: recipe lines are tab-indented; this is load-bearing syntax and a constant source of "missing separator" errors.
- **Parallel make**: `make -j N` builds independent targets concurrently — a free speedup proportional to the DAG's width.

## Mental Models
- **Declare dependencies, not steps** — `make` is declarative: you state what depends on what, and it figures out the build order and what to skip. Missing dependencies cause stale builds (the subtle bug).
- **Use automatic variables and pattern rules** — `$@`/`$<`/`$^` and `%.o: %.c` keep the Makefile DRY; never hardcode filenames in recipes.
- **Recipe lines are TAB-indented** — if you get "missing separator", you used spaces.
- **Build in parallel with `-j`** — `make -j$(nproc)` exploits the dependency DAG's independent branches for free.

## Code Examples
```makefile
CC      = gcc
CFLAGS  = -O3 -march=native
OBJS    = main.o solver.o io.o

.PHONY: all clean

all: program

program: $(OBJS)
	$(CC) $(CFLAGS) -o $@ $^        # $@ = program, $^ = all .o files

%.o: %.c                            # pattern rule: any .c → .o
	$(CC) $(CFLAGS) -c $< -o $@     # $< = the .c file

clean:
	rm -f $(OBJS) program
```
- **What it demonstrates**: variables, a pattern rule with automatic variables, and a phony `clean` target.

## Reference Tables

| Element | Meaning |
|---|---|
| `target: prereqs` | rebuild target if a prereq is newer |
| recipe (TAB-indented) | commands to build the target |
| `$@` / `$<` / `$^` | target / first prereq / all prereqs |
| `%.o: %.c` | pattern rule |
| `.PHONY:` | non-file targets (always run) |
| `make -j N` | parallel build |

## Key Takeaways
1. `make` rebuilds incrementally by comparing timestamps — only stale targets (and dependents) rebuild.
2. A rule is `target: prerequisites` + a TAB-indented recipe; use automatic variables (`$@`/`$<`/`$^`) and pattern rules to stay DRY.
3. Correct dependencies are essential — a missing prerequisite causes silent stale builds.
4. Recipe lines must start with a TAB ("missing separator" = you used spaces).
5. `make -j N` builds independent targets in parallel for a free speedup.

## Connects To
- **Ch 03 (CMake)**: generates Makefiles (or Ninja) for portable, large-project builds.
- **Ch 01 (Unix)**: recipes are shell commands.
- **Ch 05 (Debugging)**: build with `-g` (a CFLAGS change) for debug symbols.
