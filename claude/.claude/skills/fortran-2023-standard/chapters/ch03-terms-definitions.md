# Chapter 3 (Clause 3): Terms and definitions

## Core Idea
The normative vocabulary — **243 defined terms** that fix the precise meaning of every word the rest of the standard relies on. When two readings of a clause conflict, the Clause 3 definition decides. This chapter is a map to the vocabulary; the full alphabetical list lives in `glossary.md`.

## Key Concepts (the load-bearing definitions)
- **entity** — anything a program can refer to: a data object, procedure, type, etc. The umbrella term.
- **data object** — a constant, variable, or subobject; a "thing with a value." Distinguished from a *data entity* (object, function reference value, or constant expression value).
- **declared type** vs **dynamic type** — the type a polymorphic entity is *declared* with vs the type it *actually has* at runtime. The split is the basis of polymorphism (ch07, ch15).
- **attribute** — a property an entity has (e.g. ALLOCATABLE, POINTER, TARGET, INTENT). Attributes compose; many constraints are attribute-compatibility rules.
- **association** — the standard recognizes 9 named kinds: argument, construct, host, inheritance, linkage, name, pointer, storage, use. Each has distinct rules (ch19).
- **companion processor** — the (often C) processor a Fortran processor interoperates with; the anchor for C interoperability (ch18).
- **contiguous** — array/multi-part object whose elements are not separated in memory by other objects; governs performance and C interop.
- **constant expression** — an expression whose value is guaranteed constant (rules in 10.1.12); gates what may appear as a kind selector, bound, or initializer.
- **potential subobject component** — a component that could be a subobject; central to finalization and default-initialization rules.

## Mental Models
- Treat Clause 3 as a **type system for English**: every italic term elsewhere is a defined term here. "Resolve by definition" is the standard's own dispute-resolution rule.
- The **declared/dynamic type** distinction is the single most important conceptual split in the language — master it before reasoning about CLASS, SELECT TYPE, or generic resolution.
- Association is **not** one concept — when you read "associated," ask *which* of the 9 associations; the rules differ sharply (pointer vs argument vs storage).

## Anti-patterns
- **Conflating "data object" with "variable"**: constants and subobjects are data objects too; some rules apply to the wider category.
- **Assuming "associated" means pointer association**: in argument passing or host scoping it means something else entirely.

## Key Takeaways
1. 243 normative terms; the alphabetical reference is `glossary.md`.
2. Declared type vs dynamic type underpins all of OOP-Fortran.
3. There are 9 distinct *associations* — never reason about "association" generically.
4. "Contiguous," "constant expression," and "potential subobject component" are quiet but high-leverage definitions that gate many later constraints.

## Connects To
- **Ch 7**: Types — declared/dynamic type, type parameters.
- **Ch 9 & 19**: Data objects and association — the association taxonomy is applied here.
- **glossary.md**: full alphabetical term list.
