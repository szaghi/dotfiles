# Chapter 1 (Clause 1): Scope

## Core Idea
ISO/IEC 1539-1:2023 specifies the **form** and **interpretation** of programs in the base Fortran language — the syntactic forms a program may take and the meaning of those forms. It constrains *programs*, not *processors*, except where it explicitly lists processor detection/reporting duties.

## Frameworks Introduced
- **What the standard specifies**: (1) the forms a program can take; (2) rules for interpreting program + data meaning; (3) the form of input data; (4) the form of output data.
- **What it deliberately does NOT specify**: the compilation mechanism; OS setup/control; transcription to storage media; behavior where interpretation fails (beyond the 4.2 detect/report duties); the number/size of images or program-size limits; physical properties of images, numeric representation/rounding (except via ISO/IEC 60559:2020 under Clause 17), I/O records, or storage implementation.

## Key Concepts
- **Base language**: Part 1 of the ISO/IEC 1539 series — the core language, as opposed to varying-length-string or conditional-compilation auxiliary parts.
- **Processor**: the combination of compiler + runtime + computing system that implements Fortran. The standard governs programs; processors get only detection duties.
- **Image**: an instance of the program (coarray/parallel execution model); the standard refuses to fix image count or physical mapping.

## Mental Models
- Think of the standard as a **contract on portability**: it pins down meaning so a conforming program runs equivalently across conforming processors — but explicitly leaves numerics, image count, and storage layout to the processor, which is exactly where portability surprises live.
- When a behavior "isn't in the standard," it's usually **deliberately processor-dependent**, not an oversight — check Annex A (ch20) for the catalogue.

## Key Takeaways
1. The standard binds programs, not processors — the only processor obligations are the detect/report list in 4.2 (ch04).
2. Numeric rounding/representation is out of scope *except* through IEEE (Clause 17 / ch17) — do not assume bit-reproducibility across processors otherwise.
3. Parallelism (images) is in scope semantically but image *count* and physical mapping are not.
4. "Portability, reliability, maintainability, efficient execution" is the stated purpose — the lens for resolving interpretation questions.

## Connects To
- **Ch 4**: Conformance — the precise meaning of "standard-conforming" and the processor detect/report duties.
- **Ch 17**: IEEE arithmetic — the one place numeric properties enter scope.
- **Ch 20 (Annex A)**: the full list of processor-dependent behaviors this clause gestures at.
