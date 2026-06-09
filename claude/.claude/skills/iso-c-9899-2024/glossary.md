# Glossary — ISO/IEC 9899:2024 (C23)

**access** — read or modify the value of an object; unevaluated expressions don't access (Ch 1).
**aggregate type** — array or structure type (Ch 3).
**alignment** — requirement that objects sit on address multiples of a byte address; set via `alignas` (Ch 3, 6).
**Annex F** — normative IEC 60559 (IEEE 754) floating-point binding; gated by `__STDC_IEC_60559_BFP__` (Ch 12).
**Annex J** — informative catalogue of unspecified/undefined/implementation-defined/locale-specific behavior (Ch 1, 14).
**Annex K** — optional bounds-checked `_s` library functions; gated by `__STDC_LIB_EXT1__` (Ch 14).
**Annex L** — optional analyzability: bounded vs critical undefined behavior (Ch 14).
**atomic type** — `_Atomic(T)`; may differ in size/representation/alignment from `T` (Ch 3, 11).
**auto (type inference)** — C23 deduction of an object's type from its initializer (Ch 6).
**bit-precise integer** — `_BitInt(N)`; exempt from integer promotion (Ch 3).
**bounded undefined behavior** — UB that performs no OOB write/trap; limited effects (Annex L) (Ch 14).
**byte** — addressable storage unit large enough to hold a basic-charset member (Ch 1).
**ckd_add/sub/mul** — `<stdckdint.h>` overflow-checked arithmetic; return `bool` overflow (Ch 13).
**compound literal** — `(T){…}` unnamed object, automatic or static duration (Ch 5).
**conditional feature** — optional feature (atomics, threads, VLAs, complex, decimal FP) gated by `__STDC_NO_*` macros (Ch 8).
**conforming program** — acceptable to one conforming implementation; may use nonportable features (Ch 1).
**constexpr** — C23 storage-class for a typed compile-time constant object (Ch 4, 6).
**constraint** — syntactic/semantic restriction whose violation **requires** a diagnostic (Ch 1).
**critical undefined behavior** — UB that may, e.g., write OOB (Annex L) (Ch 14).
**data race** — conflicting accesses, ≥1 non-atomic and unordered ⇒ UB (Ch 11).
**diagnostic message** — message from an implementation-defined subset of output (Ch 1).
**#embed** — C23 directive embedding a binary resource as integer values (Ch 8).
**enumeration with fixed underlying type** — `enum E : T {…}`; predictable size/ABI (Ch 6).
**flexible array member** — trailing `T arr[];` in a struct; zero `sizeof` contribution (Ch 6).
**fma** — fused multiply-add; one rounding for `a*b+c` (Ch 12).
**freestanding** — implementation with minimal library; startup function impl-defined (Ch 1, 2).
**full expression** — an expression that is not a subexpression; ends at a sequence point (Ch 5).
**`_Generic`** — compile-time type selection; controlling expression unevaluated (Ch 5).
**hosted** — implementation providing full library and `main` (Ch 1, 2).
**implementation-defined behavior** — unspecified behavior the implementation documents (Ch 1).
**indeterminate representation** — object representation holding an unspecified value or a non-value (Ch 1, 3).
**indeterminately sequenced** — A before or after B, unspecified which; no interleave (Ch 2).
**integer constant expression** — required for array bounds, bit-fields, `case`, `#if` (Ch 5).
**integer conversion rank** — total order on integer types driving promotion/conversion (Ch 3).
**integer promotion** — small types → `int`/`unsigned int`; `_BitInt` exempt (Ch 3).
**linkage** — external / internal / none; controls identity across declarations (Ch 3).
**lvalue conversion** — yields stored value; arrays decay to pointers, functions to function pointers (Ch 5).
**memory location** — a scalar object or maximal sequence of adjacent nonzero-width bit-fields (Ch 1).
**memory_order** — relaxed/consume/acquire/release/acq_rel/seq_cst consistency lattice (Ch 11).
**nullptr / nullptr_t** — C23 null pointer constant and its type (Ch 3, 5).
**object** — region of storage whose contents can represent values (Ch 1).
**perform a trap** — interrupt execution so no further operations occur (Ch 1).
**restrict** — un-checked promise of no aliasing through a pointer; violation is UB (Ch 6, 10).
**rsize_t / RSIZE_MAX** — Annex K bounded size type and its limit (Ch 14).
**runtime-constraint** — requirement when calling a library function; not a §3.11 constraint (Ch 1, 14).
**scalar type** — arithmetic, pointer, or `nullptr_t` (Ch 3).
**sequence point** — where all prior value computations/side effects precede subsequent ones (Ch 2, 5).
**sequenced before** — asymmetric transitive ordering of evaluations in one thread (Ch 2).
**side effect** — volatile access, object/file modification, or a call doing those (Ch 2).
**`stdc_*` (stdbit)** — type-generic CLZ/CTZ/popcount/bit-width utilities (Ch 13).
**strictly conforming program** — uses only standard features; no reliance on unspecified/UB/impl-defined behavior (Ch 1).
**tentative definition** — file-scope object decl with no initializer/`extern`; zero-init if undefined (Ch 7).
**translation unit** — source file + all `#include`d content after preprocessing (Ch 2).
**typeof / typeof_unqual** — C23 operators yielding the (un)qualified type of an operand (Ch 4, 6).
**undefined behavior (UB)** — construct/data for which the standard imposes no requirements (Ch 1).
**universal character name** — `\uXXXX`/`\UXXXXXXXX` (Ch 4).
**unreachable()** — `<stddef.h>` assertion of impossibility; reaching it is UB (Ch 13).
**unsequenced** — evaluations that may interleave; same-object conflict ⇒ UB (Ch 2).
**unspecified behavior** — ≥2 allowed outcomes, no requirement on which (Ch 1).
**usual arithmetic conversions** — common-type rule after integer promotion (Ch 3).
**`__VA_OPT__`** — C23 variadic-macro construct expanding only when args are present (Ch 8).
**wraparound** — reduction modulo 2^N; the defined behavior of unsigned overflow (Ch 1, 3).
