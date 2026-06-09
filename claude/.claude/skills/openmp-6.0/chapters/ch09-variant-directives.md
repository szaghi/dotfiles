# Chapter 9: Variant Directives

## Core Idea
Compile-time and run-time **specialization**: select a directive or function implementation based on the **OpenMP context** (active constructs, device/ISA traits, available implementation features). The mechanism for writing one source that adapts to host/GPU/ISA.

## Frameworks Introduced
- **OpenMP context** (§9.1): the set of **traits** active at a point — `construct` traits (enclosing constructs, ordered by nesting), `device` traits (kind/ISA/arch), `implementation` traits (vendor, extensions), `target_device` traits. A **context selector** specifies trait-sets to match.
- **`metadirective`**: choose among candidate directives by `when(context-selector : directive)` clauses, with a `default(directive)` (originally `otherwise`). Resolved at compile time (static traits) or runtime (dynamic traits like `user={condition(...)}`).
- **`declare variant`**: register an alternate function implementation, selected when the call site's context matches a `match(context-selector)` clause. Optional `adjust_args`/`append_args` to transform the call.
- **`dispatch`**: control variant substitution at a specific call site (the `dispatch` construct adds a construct trait for the target-call); enables device-side variant dispatch and `nocontext`/`novariants` control.
- **`declare simd`**: generate SIMD versions of a function callable from `simd` loops (the `simd` trait).

## Key Concepts
- **static vs dynamic context**: most selectors (construct/device/ISA) resolve at compile time; `user={condition(expr)}` is dynamic (runtime branch).
- **scoring/best-match**: when multiple variants match, the one matching the most-specific/highest-scored context wins.
- **`declare variant` + `dispatch`** is OpenMP's answer to "call the GPU kernel here, the CPU version there" without `#ifdef` forests.
- Context selectors may reference base-function arguments and `this` (C++) in their expressions.

## Code Examples
```c
// metadirective: GPU gets teams-distribute, host gets a plain parallel-for
#pragma omp metadirective \
  when(target_device={kind(nohost)}: teams distribute parallel for) \
  default(parallel for)
for (int i = 0; i < n; ++i) c[i] = a[i] + b[i];

// declare variant: substitute an AVX-512 implementation when the ISA matches
#pragma omp declare variant(dot_avx512) match(device={isa("avx512f")})
double dot(const double *x, const double *y, int n);
```
- **Demonstrates**: `metadirective` picking a device-appropriate construct, and `declare variant` selecting an ISA-specialized function by context.

## Anti-patterns
- **`#ifdef`-based host/device specialization**: brittle and language-specific — prefer `metadirective`/`declare variant`, which the compiler resolves against the real context.
- **Over-specific context selectors that match nothing**: falls through to `default`/base — verify the selector matches the intended target.
- **Forgetting `dispatch`/`nocontext` control**: variant substitution at a call may not happen where you assume; use `dispatch` to be explicit.
- **Dynamic `user={condition}` selectors expecting compile-time elision**: those become runtime branches.

## Key Takeaways
1. `metadirective` selects a *directive* by context; `declare variant` selects a *function implementation*; both keyed on the OpenMP context.
2. Context = construct + device + implementation + target_device traits; selectors match trait-sets.
3. Most selectors resolve at compile time; `user={condition(...)}` is the runtime escape hatch.
4. `dispatch` controls variant substitution at a call site (and adds a construct trait).
5. This is the standards-based alternative to `#ifdef` host/GPU/ISA branching.

## Connects To
- **Ch 5**: directive/clause syntax underpinning these.
- **Ch 15**: device traits for `target` specialization.
- **Ch 13**: the constructs metadirective chooses among.
- **openacc-3.4 ch2**: OpenACC's `device_type` is the analogous (simpler) per-device tuning mechanism.
