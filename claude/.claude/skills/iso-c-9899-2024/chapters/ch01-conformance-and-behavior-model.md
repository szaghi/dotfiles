# Chapter 1: Scope, Conformance & the Behavior Model (Clauses 1–4)

## Core Idea
C's entire semantics hinge on one taxonomy: **undefined / unspecified / implementation-defined / locale-specific** behavior. Mastering exactly what each means — and that "shall" violations outside a constraint are *undefined behavior* — is the foundation for reasoning about every other rule in the standard.

## Frameworks Introduced

- **The four behavior categories** (§3.5): the lens through which all non-portable constructs are classified.
  - **Undefined behavior (UB)** — "behavior, upon use of a nonportable or erroneous construct or erroneous data, for which this document imposes *no requirements*." The compiler may do anything: ignore it, document something, or terminate. Catalogued in **Annex J.2**.
  - **Unspecified behavior** — two or more possibilities are allowed; the standard imposes no requirement on which is chosen (e.g. argument evaluation order). Catalogued in **J.1**.
  - **Implementation-defined behavior** — unspecified behavior that each implementation *documents* (e.g. sign propagation of `>>` on a negative signed int). Catalogued in **J.3**.
  - **Locale-specific behavior** — depends on nationality/culture/language conventions, documented per implementation (e.g. `islower` for non-Latin chars). Catalogued in **J.4**.
  - When to use: classify any portability question by finding which J-annex lists it.

- **The "shall" rule** (§4): `shall`/`shall not` = requirement/prohibition on implementation OR program.
  - **A `shall`/`shall not` violation _outside_ a constraint or runtime-constraint ⇒ undefined behavior.** No diagnostic required.
  - A violation *inside* a **constraint** (§3.11) ⇒ the implementation **must** issue a diagnostic.
  - How: when reading a rule, check whether it sits under a "Constraints" heading. If yes → diagnosable; if no → silent UB on violation.

- **Strictly conforming vs conforming program** (§4):
  - **Strictly conforming**: uses only standard features; output never depends on any unspecified/undefined/implementation-defined behavior; exceeds no minimum limit. Maximally portable.
  - **Conforming**: merely acceptable to *one* conforming implementation — may depend on nonportable features.

## Key Concepts
- **Constraint** (§3.11): syntactic/semantic restriction whose violation requires a diagnostic.
- **Runtime-constraint** (§3.21): a requirement when *calling a library function*; NOT a §3.11 constraint and need not be diagnosed at translation time (relevant to Annex K).
- **Hosted vs freestanding** (§4): hosted accepts any strictly conforming program; freestanding may restrict library use to a small header set (`<float.h>`, `<iso646.h>`, `<limits.h>`, `<stdalign.h>`, `<stdarg.h>`, `<stdbit.h>`, `<stdbool.h>`, `<stddef.h>`, `<stdint.h>`, `<stdnoreturn.h>`) plus parts of `<string.h>` and `memalignment`.
- **Diagnostic message** (§3.13): a message from an implementation-defined subset of the implementation's output.
- **Indeterminate / non-value representation** (§3.23–3.24): an object representation that either holds an unspecified value or doesn't represent any value of the type; fetching a non-value representation *permits* (does not require) a trap (§3.25).
- **Wraparound** (§3.28): reduction modulo 2^N where N is the result type's width — the defined behavior for *unsigned* overflow (signed overflow is UB).

## Mental Models
- **Think of UB as a contract you signed**: by writing it, you promise the construct never executes; the compiler optimizes assuming that promise. UB is not "random result" — it licenses arbitrary transformation of surrounding code.
- **Use the J-annexes as the canonical index**: any "is this portable?" question resolves to a lookup in J.1 (unspecified), J.2 (undefined), J.3 (implementation-defined), or J.4 (locale).
- **Constraint = diagnosable, "shall" alone = silent UB.** The presence of the word "Constraints" as a subclause heading is load-bearing.

## Code Examples
```c
/* §4 EXAMPLE — guarding a conditional feature keeps a program strictly conforming */
#ifdef __STDC_IEC_60559_BFP__  /* FE_UPWARD is defined */
    fesetround(FE_UPWARD);
#endif
```
- **What it demonstrates**: strictly conforming code may use conditional features only when guarded by the matching feature-test macro.

## Reference Tables

| Category | Documented? | Diagnostic? | Catalogue |
|---|---|---|---|
| Undefined | No | No | J.2 |
| Unspecified | No | No | J.1 |
| Implementation-defined | Yes (by impl) | No | J.3 |
| Locale-specific | Yes (by impl) | No | J.4 |
| Constraint violation | — | **Required** | throughout |

## Key Takeaways
1. A `shall` outside a "Constraints" subclause that is violated ⇒ **undefined behavior**, no diagnostic owed.
2. Constraint violations are the *only* errors the standard guarantees a compiler must diagnose.
3. UB is unbounded: it can corrupt behavior *before* the offending operation only insofar as observable behavior before it is preserved (§3.5.3 Note 3); compilers exploit it for optimization.
4. Unsigned overflow wraps (defined); signed overflow is UB.
5. For any portability concern, identify the category and consult the matching J-annex.

## Connects To
- **Ch 13 (Annexes J & K)**: J enumerates every UB/unspecified/impl-defined case; K adds runtime-constraints.
- **Ch 02 (Environment)**: defines observable behavior and the abstract machine that gives UB its teeth.
- **Ch 12 (Annex F)**: `__STDC_IEC_60559_BFP__` and the floating-point conformance macros.
