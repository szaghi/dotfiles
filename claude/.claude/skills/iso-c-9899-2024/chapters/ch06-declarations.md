# Chapter 6: Declarations — constexpr, typeof, auto, enums, attributes (Clause 6.7)

## Core Idea
Declarations bind a **declaration-specifier sequence** (storage class, type specifiers, qualifiers, attributes) to declarators. C23 massively expands this clause: `constexpr` objects, `auto`/`typeof` type inference, enums with a **fixed underlying type**, and standard `[[…]]` attributes.

## Frameworks Introduced

- **`constexpr` objects** (§6.7.2): a storage-class specifier making a *named compile-time constant object*.
  - When to use: typed constants usable in constant expressions (unlike `#define`, they have a type and scope).
  - Rules: must be a definition with an initializer; the value must be *exactly representable* (no narrowing); may NOT be atomic, VLA, `volatile`, or `restrict`. May combine with `auto`/`register`/`static`. Pointer `constexpr` must init to a null pointer constant.

- **Type inference — `auto` and `typeof`** (§6.7.10): C23 type deduction.
  - `auto x = expr;` infers `x`'s type from the initializer (the initializer is required; one declarator only).
  - `typeof(expr)` / `typeof_unqual(expr)`: yield the (qualified / unqualified) type of an operand or type-name, usable anywhere a type is needed.
  - When to use: generic macros, avoiding repetition of long types, capturing the type of an expression for casts/temporaries.

- **Enumerations with fixed underlying type** (§6.7.3.3): C23 `enum E : int { … }`.
  - A fixed underlying type makes enum values well-defined (representable in that type) and gives the enum predictable size/ABI. Without it, the underlying type is the implementation-chosen compatible integer type.

- **Standard attributes** (§6.7.13): `[[…]]` syntax; support is implementation-defined/optional, probe with `__has_c_attribute`.
  - `[[deprecated]]`, `[[deprecated("msg")]]` — diagnose use.
  - `[[fallthrough]]` — mark intentional `switch` fall-through.
  - `[[maybe_unused]]` — suppress unused warnings.
  - `[[nodiscard]]`, `[[nodiscard("msg")]]` — warn if return value ignored.
  - `[[noreturn]]` — function does not return (replaces `_Noreturn`).
  - `[[reproducible]]`, `[[unsequenced]]` — function effectfulness/idempotence hints for optimization.
  - `attr` and `__attr__` spellings are interchangeable (e.g. `[[nodiscard]]` ≡ `[[__nodiscard__]]`).

## Key Concepts
- **Storage-class specifiers** (§6.7.2): `typedef`, `extern`, `static`, `thread_local`, `auto`, `register`, `constexpr` (≤1 per declaration, with stated combination exceptions).
- **Type qualifiers** (§6.7.4): `const`, `volatile`, `restrict`, `_Atomic`.
- **Alignment specifier** `alignas` (§6.7.6): set an object/type's alignment; cannot reduce below the natural alignment.
- **Flexible array member** (§6.7.3.2): a trailing `T arr[];` in a struct; contributes nothing to `sizeof` but addresses storage beyond the struct (allocate `sizeof(struct) + n*sizeof(T)`).
- **`static_assert`** (§6.7.12): compile-time assertion; message optional in C23.
- **`restrict`** (§6.7.4.2): promises no aliasing through this pointer for the object's lifetime — UB if violated; enables aggressive optimization.
- **Underspecified declaration**: a `constexpr`/`auto` declaration that declares no/multiple entities is constrained (implementation-defined or invalid in some forms).

## Mental Models
- **Use `constexpr` over `#define` for typed constants** — it respects scope and type, and feeds other constant expressions.
- **`enum E : uint8_t { … }`** when you need a guaranteed 1-byte enum ABI.
- **`[[nodiscard]]` on allocation/error-returning functions** — turns "ignored return" into a diagnostic.
- **`restrict` is a promise, not a check** — violating it is silent UB.

## Code Examples
```c
constexpr double PI = 3.14159265358979;     /* typed compile-time constant */
enum Color : unsigned char { RED, GREEN };  /* fixed 1-byte underlying type */

[[nodiscard]] int parse(const char *s);     /* warn if result ignored */

struct packet { size_t len; char data[]; }; /* flexible array member */
struct packet *p = malloc(sizeof *p + n);   /* allocate with the tail */

auto v = compute();                         /* type inferred from initializer */
typeof(v) w = v;                            /* w has v's exact type */
```
- **What it demonstrates**: the core C23 declaration additions in one block.

## Reference Tables

| Attribute | Effect | `__has_c_attribute` |
|---|---|---|
| `[[deprecated]]` | diagnose use | 201904L |
| `[[fallthrough]]` | intentional switch fall-through | 201904L |
| `[[maybe_unused]]` | suppress unused warning | 201904L |
| `[[nodiscard]]` | warn if return ignored | 202003L |
| `[[noreturn]]` | function never returns | 202202L |
| `[[reproducible]]` / `[[unsequenced]]` | effect hints | 202207L |

## Key Takeaways
1. `constexpr` gives typed, scoped compile-time constants usable in further constant expressions — prefer over `#define`.
2. `auto` and `typeof`/`typeof_unqual` bring type inference to C23.
3. `enum E : T { … }` fixes the underlying type → predictable size and ABI.
4. Standard attributes use `[[…]]`; `[[noreturn]]` supersedes `_Noreturn`; probe support with `__has_c_attribute`.
5. A flexible array member costs zero `sizeof` but you must over-allocate; `restrict` is an un-checked no-alias promise.

## Connects To
- **Ch 03 (Types)**: the type categories these specifiers compose.
- **Ch 05 (Expressions)**: `constexpr` objects in constant expressions; `_Generic` pairs with `typeof`.
- **Ch 08 (Preprocessor)**: `__has_c_attribute` and `__has_include` feature probes.
- **Ch 11 (Atomics)**: `_Atomic` qualifier interplay with `constexpr` (forbidden together).
