# Chapter 2: Environment — Translation Phases, the Abstract Machine & Sequencing (Clause 5)

## Core Idea
A C program's meaning is defined by an **abstract machine** that produces **observable behavior**; the compiler may do anything internally as long as observable behavior (volatile accesses, file output, interactive I/O) matches. The **8 translation phases** and the **sequenced-before** relation are the two operational pillars.

## Frameworks Introduced

- **The 8 translation phases** (§5.1.1.2): the conceptual pipeline every translation unit passes through. Implementations need only behave *as if* these are distinct.
  1. Map physical multibyte chars → source character set; introduce new-lines.
  2. Splice lines: delete each `\` immediately followed by new-line. File must end in a non-spliced new-line.
  3. Decompose into **preprocessing tokens** + white-space; replace each comment with one space.
  4. Execute preprocessing directives, expand macros, run `_Pragma`; `#include` recursively re-runs phases 1–4. (UB if token concatenation forms a UCN syntax.) Directives are then deleted.
  5. Convert source chars / escape sequences in char constants & string literals to the **execution character set**.
  6. Concatenate adjacent string-literal tokens.
  7. White-space no longer significant; preprocessing tokens → tokens; syntactic/semantic analysis + translate.
  8. Resolve external references; link library components; produce the program image.
  - When to use: to reason about *why* macros can't see comments, why `\`-continuation works anywhere, and why adjacent `"a" "b"` literals merge.

- **The abstract machine & observable behavior** (§5.1.2.4): the "as-if" rule.
  - The **least requirements** on a conforming implementation:
    - Volatile accesses are evaluated strictly per the abstract machine.
    - At termination, file output is identical to abstract-semantics output.
    - Interactive I/O dynamics occur as in 7.23.3 (prompts appear before input waits).
  - Anything not affecting these three is fair game for optimization (dead-code elimination, reassociation limits, register width).

- **Sequenced-before / unsequenced / indeterminately sequenced** (§5.1.2.4 p3): the ordering relation that defines when side effects collide.
  - **A sequenced before B** ⇒ A's value computations + side effects precede B's.
  - **Unsequenced** ⇒ may interleave; two unsequenced side effects on the same object (or a side effect + a value read) ⇒ **UB**.
  - **Indeterminately sequenced** ⇒ one before the other but unspecified which; cannot interleave (e.g. function-call argument evaluations relative to the body).
  - **Sequence points** (Annex C) are where everything before is sequenced before everything after.

## Key Concepts
- **Translation unit** (§5.1.1.1): a source file + all `#include`d content, after preprocessing.
- **Side effect** (§5.1.2.4): volatile access, modifying an object/file, or calling a function doing any of those.
- **Observable behavior**: volatile accesses + final file contents + interactive I/O dynamics.
- **Freestanding vs hosted** (§5.1.2.1–.3): freestanding = no OS, startup function impl-defined; hosted provides full library and `main`.
- **`sig_atomic_t` / lock-free atomic**: the only object types whose values survive a signal interruption unspecified-free.

## Mental Models
- **Think of `volatile` as the one thing the optimizer must never touch.** If an implementation made abstract = actual at every sequence point, `volatile` would be redundant (§5.1.2.4 EXAMPLE 1).
- **Float rearrangement is generally forbidden** (§5.1.2.4 EXAMPLE 5): `(x*y)*z ≠ x*(y*z)`, `(x-y)+y ≠ x`, `x/5.0 ≠ x*0.2` — roundoff makes associative/distributive rules invalid. This is the standard's basis for `-ffast-math` being non-conforming.
- **Wide registers must round to storage precision** (EXAMPLE 4): an explicit store/load must round to the storage type; casts/assignments perform their conversion.

## Code Examples
```c
/* §5.1.2.3.2 — the two standard forms of main in a hosted environment */
int main(void) { /* ... */ }
int main(int argc, char *argv[]) { /* ... */ }
```
- **What it demonstrates**: `main` returns `int`; `argv[argc]` is a null pointer; `argc ≥ 0`; reaching `}` returns 0 if return type is compatible with `int`.

## Reference Tables

| Ordering relation | Can interleave? | Same-object conflict ⇒ |
|---|---|---|
| Sequenced before | No | safe |
| Indeterminately sequenced | No (one then other) | safe |
| Unsequenced | Yes | **UB** (write+write or write+read) |

## Worked Example
`i = i++ + 1;` is **undefined**: the write from `i++` and the write from `=` to the same object `i` are *unsequenced*. By contrast `i = (i, i++);` is fine because the comma operator and `=` introduce sequencing. The fix for ambiguous mutation is to introduce a sequence point (`;`, `&&`, `||`, `?:`, comma, or a function call boundary).

## Key Takeaways
1. Two unsequenced side effects on the same scalar (or a side effect + read of it) ⇒ **undefined behavior** — the classic `i++ + i++` trap.
2. The "as-if" rule lets the compiler do anything that preserves observable behavior; `volatile`, final file state, and interactive I/O are the contract.
3. Floating-point reassociation is generally non-conforming — don't assume `-ffast-math` semantics.
4. Backslash-newline splicing (phase 2) happens before tokenization — it works mid-token, even mid-string-prefix.
5. `main` returning from its initial call ≡ calling `exit()` with that value; falling off `}` returns 0.

## Connects To
- **Ch 04 (Expressions)**: full-expression sequence points and evaluation-order UB.
- **Ch 09/10 (stdio)**: the interactive-device buffering requirements live in 7.23.3.
- **Ch 11 (Atomics)**: `sig_atomic_t` and lock-free atomics are the signal-safe types.
- **Annex C**: complete list of sequence points.
