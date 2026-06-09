# Chapter 9: Modules (Clause 10)

## Core Idea
Modules (C++20) replace the textual `#include` model with a **compiled interface**: a named module exports an explicit interface, hides everything else, and is imported by name — eliminating header re-parsing, macro leakage, and most ODR fragility.

## Frameworks Introduced

- **Module units & purview** (§10.1 `[module.unit]`):
  - **Module declaration**: `export module M;` makes a TU part of named module `M`.
  - **Module interface unit**: contains `export module M;` — defines what `M` exposes.
  - **Module implementation unit**: `module M;` (no `export`) — contributes to `M` but exports nothing.
  - **Module partitions**: `export module M:part;` split a large module across files.
  - **Global module fragment**: a leading `module;` … block where legacy `#include`s go before the module declaration.

- **Export & import** (§10.2–10.3):
  - `export` on a declaration (or `export { … }` block) makes a name visible to importers; un-exported names have **module linkage** (internal to the module).
  - `import M;` brings in module `M`'s exported names; `import :part;` imports a partition; `import <header>;` is a **header unit** (importable header).

## Key Concepts
- **Module linkage** (Ch 2): un-exported module entities are reachable across the module's own TUs but invisible to importers — a genuinely new linkage kind.
- **No macro leakage**: macros do not cross `import` (except from header units) — modules are not textual.
- **One interface per module name**; partitions and implementation units attach to it.
- **`std` module** (C++23): `import std;` imports the entire standard library as a module (and `import std.compat;` adds the C library names in the global namespace) — the headline C++23 modules feature.
- **Reachability vs visibility**: an entity can be *reachable* (its definition usable, e.g. for template instantiation) without its name being *visible*.

## Mental Models
- **`import std;` is the C++23 fast-compile win** — one import replaces dozens of standard headers and skips repeated parsing.
- **Put legacy `#include`s in the global module fragment** (`module;` … `#include …` … `export module M;`) — you can't `#include` after the module declaration.
- **Exported = public API; everything else is module-private by default** — modules invert the header model's "everything visible" default.
- **Modules largely dissolve the include-order and macro-collision class of bugs** — but build-system/toolchain support is still maturing; check your compiler's module flags.

## Code Examples
```cpp
// math.ixx — module interface unit
module;                    // global module fragment
#include <cmath>           // legacy includes go here
export module math;        // module declaration

export double square(double x) { return x * x; }   // exported API
double helper(double x)    { return x + 1; }        // module-internal (not exported)

// main.cpp — consumer
import math;               // import by name, no header parsing
import std;                // C++23: whole standard library as a module
int main() { return (int)square(3); }
```
- **What it demonstrates**: interface unit with a global module fragment, selective `export`, and C++23 `import std;`.

## Reference Tables

| Construct | Meaning |
|---|---|
| `export module M;` | interface unit of module M |
| `module M;` | implementation unit of M |
| `export module M:p;` | partition p of M |
| `module;` (leading) | global module fragment (`#include`s here) |
| `import M;` | import module M's exports |
| `import <h>;` | header unit import |
| `import std;` | C++23 whole standard library |

## Key Takeaways
1. Modules provide a compiled, name-imported interface — no header re-parsing, no macro leakage.
2. `export` defines the public API; un-exported names have module linkage (importer-invisible).
3. Legacy `#include`s must go in the global module fragment, before `export module`.
4. C++23 `import std;` imports the entire standard library as a module — a major compile-time improvement.
5. Modules eliminate most ODR/include-order/macro-collision bugs; toolchain support is still maturing.

## Connects To
- **Ch 02 (Linkage)**: module linkage as the fourth linkage kind.
- **Ch 10 (Preprocessor)**: header units bridge `#include` and `import`.
- **Ch 01 (ODR)**: modules remove most cross-TU ODR fragility.
