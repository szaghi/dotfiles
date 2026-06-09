# Chapter 7: Statements & External Definitions (Clause 6.8–6.9)

## Core Idea
Statements are the executable backbone: blocks, selection (`if`/`switch`), iteration (`while`/`do`/`for`), and jumps (`goto`/`continue`/`break`/`return`). External definitions tie translation units together via linkage. C23 lets attributes appertain to statements and labels.

## Frameworks Introduced

- **Statement categories** (§6.8): each statement may carry an `attribute-specifier-sequence`.
  - **Labeled** (§6.8.2): `id:`, `case CE:`, `default:` — `case`/`default` only inside `switch`; labels now accept `[[…]]` attributes; a label may precede a declaration in C23 (no longer requires a statement).
  - **Compound** (§6.8.3): `{ … }` introduces a block scope.
  - **Selection** (§6.8.5): `if`/`else`, `switch` — the controlling expression is a full expression with a sequence point after it.
  - **Iteration** (§6.8.6): `while`, `do…while`, `for` — `for`'s declaration is scoped to the loop.
  - **Jump** (§6.8.7): `goto` (within the function), `continue`, `break`, `return`.

- **External definitions** (§6.9): a translation unit is a sequence of external declarations; **function definitions** and **object definitions** with external linkage are how TUs communicate.
  - **One-definition-per-entity** across the program for external-linkage objects/functions.
  - **Tentative definitions** (§6.9.3): a file-scope object declaration with no initializer and no `extern` is tentative; if no actual definition appears, it becomes a definition initialized to zero.

## Key Concepts
- **Block scope**: each `{}` (and `for`/`while`/`if` substatement) introduces a scope; objects with automatic duration are created/destroyed on block entry/exit.
- **`switch` fall-through**: control falls through to the next `case` unless `break`; mark intentional fall-through with `[[fallthrough]]`.
- **`return` in `main`**: equivalent to `exit()` (see Ch 02).
- **Tentative definition**: `int x;` at file scope → zero-initialized if no other definition exists.
- **Function definition** (§6.9.2): provides the body; modern C requires a prototype-form parameter list (K&R-style identifier lists are removed in C23 — `f()` now means `f(void)`).

## Mental Models
- **`f()` now means `f(void)` in C23** — empty parameter lists no longer mean "unspecified arguments." This is a breaking change from C17.
- **Use `[[fallthrough]];` as a statement** between cases to document deliberate fall-through and silence `-Wimplicit-fallthrough`.
- **`goto` cannot jump into the scope of a VLA** — jumping past a VLA declaration is UB.

## Code Examples
```c
switch (c) {
    case 'a':
        do_a();
        [[fallthrough]];   /* intentional — no diagnostic */
    case 'b':
        do_b();
        break;
    default:
        break;
}
```
- **What it demonstrates**: `[[fallthrough]]` as an attribute statement marking deliberate switch fall-through.

## Key Takeaways
1. **C23: `int f()` is identical to `int f(void)`** — K&R unprototyped functions are gone.
2. Tentative definitions (`int x;` at file scope) zero-initialize if no full definition appears.
3. Attributes may appertain to statements and labels (`[[fallthrough]]`, `[[maybe_unused]]`).
4. A label may now precede a declaration; `for`-loop declarations are loop-scoped.
5. `goto` is function-local and may not jump into a VLA's scope.

## Connects To
- **Ch 06 (Declarations)**: attribute syntax, `constexpr`, VLA scoping rules.
- **Ch 03 (Linkage)**: external/internal linkage governs how 6.9 definitions resolve.
- **Ch 02 (main)**: `return` from `main` ≡ `exit`.
