# Chapter 10: String & Memory Handling (Clause 7.26 `<string.h>`)

## Core Idea
`<string.h>` provides the byte- and null-terminated-string primitives. Their correctness hinges on `restrict` (no overlap) for the `cpy`/`cat` family, and on the caller guaranteeing buffer size — these functions perform **no bounds checking** (Annex K adds the `_s` checked variants).

## Frameworks Introduced

- **The copy family** (§7.26.2):
  - `memcpy(d, s, n)` — `restrict`: source/dest **must not overlap** (overlap ⇒ UB). Returns `d`.
  - `memmove(d, s, n)` — overlap-safe (no `restrict`). Use when ranges may overlap.
  - `memccpy(d, s, c, n)` (C23 standard) — copy up to and including first `c`, or `n` chars; returns pointer past the copied `c` or null.
  - `strcpy(d, s)` / `strncpy(d, s, n)` — `restrict`; `strncpy` does NOT null-terminate if `s` is ≥ `n` long (classic footgun).
  - `strdup(s)` / `strndup(s, n)` (C23 standard) — allocate a copy (caller `free`s).

- **The compare / search family**: `memcmp`, `strcmp`, `strncmp`, `strchr`, `strrchr`, `strstr`, `strspn`, `strcspn`, `strpbrk`, `memchr`, `strtok` (stateful, non-reentrant).

- **The fill / length family**: `memset(s, c, n)`, `strlen(s)`, `strerror(errno)`, `strerrorlen_s` (Annex K).

## Key Concepts
- **`restrict` contract**: `memcpy`/`strcpy`/`strcat` promise non-overlapping operands; violate it ⇒ UB. `memmove` is the overlap-safe alternative.
- **`strncpy` is not a safe `strcpy`**: it pads with `\0` up to `n` *only if* the source is shorter; if `strlen(s) >= n` the result is **not** null-terminated.
- **`memcmp` on structs** compares padding bytes too — never use it to compare structs with padding.
- **`strtok` holds static state** — not thread-safe and not reentrant.

## Mental Models
- **Reach for `memmove` whenever overlap is even possible** — `memcpy` UB on overlap is a real, optimizer-exploited hazard.
- **Treat `strncpy` as a fixed-width field filler, not a bounded string copy.** For bounded copy, use `snprintf` or Annex K `strcpy_s`.
- **Never `memcmp` two structs** to test equality — compare members.

## Code Examples
```c
char dst[8];
strncpy(dst, src, sizeof dst);   /* may NOT null-terminate */
dst[sizeof dst - 1] = '\0';      /* must force the terminator */

/* overlap-safe shift */
memmove(buf + 1, buf, n);        /* memcpy here would be UB */
```
- **What it demonstrates**: the two canonical `<string.h>` traps — `strncpy` non-termination and overlap with `memcpy`.

## Reference Tables

| Function | Overlap allowed? | Null-terminates? |
|---|---|---|
| `memcpy` | No (UB) | n/a |
| `memmove` | Yes | n/a |
| `strcpy` | No (UB) | Yes |
| `strncpy` | No (UB) | **Only if src < n** |
| `snprintf` | n/a | Yes (truncates) |

## Key Takeaways
1. `memcpy`/`strcpy`/`strcat` are `restrict` — overlapping operands are UB; use `memmove` for overlap.
2. `strncpy` does not guarantee a null terminator — always force `dst[n-1] = '\0'`.
3. `memcmp` compares padding bytes; never use it for struct equality.
4. `strtok` is stateful/non-reentrant; prefer a reentrant tokenizer in threaded code.
5. C23 standardizes `memccpy`, `strdup`, `strndup`.

## Connects To
- **Ch 06 (restrict)**: the aliasing promise these functions encode.
- **Ch 09 (allocation)**: `strdup`/`strndup` allocate; caller frees.
- **Ch 14 (Annex K)**: `_s` checked counterparts (`strcpy_s`, `memcpy_s`) with runtime-constraints.
