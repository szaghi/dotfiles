# Chapter 2 (Clause 2): Normative references

## Core Idea
Lists the external documents whose content is **normatively** incorporated into the Fortran standard — chiefly the IEEE floating-point standard and the character-set standards.

## Key Concepts
- **ISO/IEC 60559:2020** — the floating-point arithmetic standard (formerly IEEE 754). Normatively referenced by Clause 17; the source of IEEE conformance semantics, exceptions, and rounding modes.
- **ISO/IEC 646** — the 7-bit ASCII character set, basis of the default and ASCII character kinds.
- **ISO/IEC 10646** — the universal coded character set (Unicode-aligned), basis of the ISO 10646 character kind for wide characters.
- **ISO 8601** — date/time representation, relevant to `DATE_AND_TIME`.

## Mental Models
- A normative reference means: **the cited document's requirements are binding as if written here**. So "IEEE conformance" in Clause 17 is precisely conformance to 60559:2020, not a Fortran-local approximation.

## Key Takeaways
1. Floating-point semantics are defined by reference to ISO/IEC 60559:2020 — for FP64/FP32 behavior, the IEEE doc is authoritative, surfaced through Clause 17 (ch17).
2. The three character kinds (default/ASCII, ISO 10646) trace to ISO/IEC 646 and 10646.

## Connects To
- **Ch 7**: Types — character kinds depend on these character-set standards.
- **Ch 17**: IEEE arithmetic — built directly on ISO/IEC 60559:2020.
