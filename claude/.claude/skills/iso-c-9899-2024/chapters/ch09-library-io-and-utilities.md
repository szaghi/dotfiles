# Chapter 9: Library Foundations, I/O & General Utilities (Clause 7.1, 7.23 `<stdio.h>`, 7.24 `<stdlib.h>`)

## Core Idea
The library clause defines reserved-identifier rules (what names you must not collide with), the stream-based I/O model in `<stdio.h>`, and the allocation / conversion / process-control utilities in `<stdlib.h>`. C23 adds `free_sized`, `free_aligned_sized`, `memalignment`, and tightens conversion specifiers.

## Frameworks Introduced

- **Reserved identifiers** (§7.1.3): names you may never use.
  - Identifiers beginning with `_` followed by an uppercase letter or a second `_` — reserved for any use.
  - All other file-scope identifiers beginning with `_` — reserved as file-scope identifiers.
  - Each header's defined macros/typedefs/functions are reserved when that header is included; `errno` and the future-directions names are always reserved with external linkage.
  - When to use: never name your own symbols `_Foo`, `__bar`, or shadow standard library names — UB.

- **The stream I/O model** (§7.23.2–7.23.3): a `FILE *` controls a stream (text or binary), buffered (`setbuf`/`setvbuf`: `_IOFBF`/`_IOLBF`/`_IONBF`). `stdin`/`stdout`/`stderr` are predefined. A `FILE` object's address may be significant — never copy a `FILE`.
  - `fopen`/`freopen`/`fclose`, `fread`/`fwrite`, `fgetc`/`fgets`/`fputc`/`fputs`, `fseek`/`ftell`/`fgetpos`/`fsetpos`, the `printf`/`scanf` families (incl. wide variants `fwprintf` etc.).

- **Memory management** (§7.24.3): `malloc`, `calloc`, `realloc`, `aligned_alloc`, `free`, plus C23 `free_sized`, `free_aligned_sized`. Order/contiguity of successive allocations is unspecified; returned pointer is suitably aligned for any object with a fundamental alignment.

## Key Concepts
- **Numeric conversion** (§7.24.1): prefer `strtol`/`strtoll`/`strtoul`/`strtoull`/`strtod`/`strtof`/`strtold` over `atoi`/`atof` — the `strto*` forms report errors (`endptr`, `errno == ERANGE`). `atoi(s) ≡ (int)strtol(s, nullptr, 10)`.
- **Process control** (§7.24.4): `exit` (runs `atexit` handlers, flushes streams), `quick_exit` (runs `at_quick_exit`), `_Exit` (no cleanup), `abort` (raises `SIGABRT`), `atexit`/`at_quick_exit`.
- **Search/sort** (§7.24.5): `qsort`, `bsearch` (comparison-function based).
- **`memalignment(p)`** (C23): returns the alignment the pointer `p` satisfies — the lone library function a freestanding implementation must accept from `<stdlib.h>`.
- **`EOF`**, `FILENAME_MAX`, `BUFSIZ`, `SEEK_SET/CUR/END` are `<stdio.h>` macros.

## Mental Models
- **Always use the `strto*` family, never `atoi`/`atof`** — the latter cannot signal overflow or malformed input.
- **`realloc(p, 0)` is implementation-defined in C23** (may return null or a unique pointer) — don't rely on it as a `free`.
- **`free_sized(p, n)` / `free_aligned_sized(p, a, n)`** let allocators skip size lookup — pass the exact requested size.
- **`fseek(f, 0, SEEK_END)` on a binary stream is UB** for streams where end-of-file positioning isn't meaningful.

## Code Examples
```c
/* robust integer parse — the strtol idiom */
errno = 0;
char *end;
long v = strtol(s, &end, 10);
if (end == s || *end != '\0' || errno == ERANGE)
    /* malformed or out of range */;

void *p = aligned_alloc(64, n * sizeof(double));  /* 64-byte aligned */
free_sized(p, n * sizeof(double));                /* C23 sized free */
```
- **What it demonstrates**: error-checked numeric conversion and C23 aligned/sized allocation.

## Reference Tables

| Task | Preferred (C23) | Avoid |
|---|---|---|
| string→int | `strtol`/`strtoll` | `atoi`/`atol` |
| string→double | `strtod` | `atof` |
| aligned alloc | `aligned_alloc(a, sz)` | manual over-align |
| sized free | `free_sized`, `free_aligned_sized` | — |
| normal exit | `exit` (cleanup) | — |
| immediate exit | `_Exit` (no cleanup) | — |

## Key Takeaways
1. Never define identifiers starting with `_` + uppercase/second `_` — they're reserved (UB to use).
2. Use `strto*` not `ato*` for parseable, error-reporting numeric conversion.
3. C23 adds `free_sized`, `free_aligned_sized`, `memalignment`; `realloc(p,0)` is now implementation-defined.
4. A `FILE *` controls a stream; never copy the `FILE` object — its address is significant.
5. `exit` runs `atexit` handlers and flushes; `_Exit`/`abort` do not.

## Connects To
- **Ch 10 (string/memory)**: `<string.h>` complements raw-buffer work.
- **Ch 12 (errno/math)**: `errno`/`ERANGE` reporting for `strtod`.
- **Ch 14 (Annex K)**: `_s` bounds-checked I/O and string variants.
