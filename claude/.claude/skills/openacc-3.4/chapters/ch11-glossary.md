# Chapter 11 (Ch 6): Glossary

## Core Idea
The spec's normative terminology — the words that mean something *specific* in OpenACC, especially where they conflict with base-language usage. This chapter reproduces the key definitions; the alphabetical quick-reference is also in `glossary.md`.

## Key Concepts (the load-bearing definitions)
- **Accelerator** – a device attached to a CPU that the CPU offloads data/compute to.
- **Device** – general reference to an accelerator *or* a multicore CPU acting as one.
- **Compute construct** – a `parallel`, `serial`, or `kernels` construct. **Compute region** – the dynamic execution of one.
- **Construct** – a directive + its associated statement/loop/structured block. **Region** – *all* code encountered during an instance of a construct's execution (includes called procedures — dynamic, not lexical).
- **Levels of parallelism** (high→low): gang, worker, vector, seq.
- **Gang / Worker / Vector** – coarse / fine / SIMD parallelism (see ch1).
- **Device thread / Accelerator thread** – a single vector lane of a single worker of a single gang.
- **Local thread / Local device / Local memory** – the thread executing a directive (host or device), its device, its memory.
- **Discrete memory** – memory of the local thread not accessible from the current device (and vice versa) → requires copies.
- **Shared memory** – accessible from both local thread and current device → no copy needed.
- **Present data** – data whose structured + dynamic reference counters sum > 0 (it's in device memory).
- **Partly present data** – a section only partially resident.
- **Data lifetime / Data region / Implicit data region** – when device data exists; structured (lexical) vs implicit (subprogram).
- **Compute intensity** – ratio of arithmetic operations to data movement for a loop/region — the metric that decides if offload pays off.
- **Orphaned loop construct** – a `loop` with no lexically-enclosing compute construct (e.g. in a `routine`).
- **Parent procedure / parent compute construct / parent compute scope** – nearest lexically enclosing procedure / compute construct / either — used by data-attribute and routine rules.
- **Async-argument** – a nonnegative scalar integer selecting an activity queue (or a special `acc_async_*` value).
- **Aggregate vs scalar datatype** – non-scalar (array/struct/derived) vs intrinsic scalar; governs implicit `copy` vs `firstprivate`.
- **Captured / Private / Exposed variable** – discrete copy in device memory / per-iteration private / accessed data-or-address in a compute construct.

## Mental Models
- **"Region" is dynamic, "construct" is static**: a construct is the syntax; a region is everything that *runs* because of it — including called procedures. Reason about data presence and side effects over the *region*, not just the lexical block.
- **Compute intensity is the offload decision metric**: high arithmetic-to-transfer ratio → offload wins; low → host wins (ties back to ch1's discrete-memory bandwidth argument).
- **"Present" is a reference-count fact**, not a yes/no flag — it's why nested data regions compose correctly (ch4).

## Anti-patterns
- **Conflating OpenACC terms with base-language terms**: e.g. "scalar," "block construct," "procedure" have OpenACC-specific scoping meanings here — when a rule cites a glossary term, use *this* definition.
- **Treating "construct" and "region" as synonyms**: a region spans called procedures; a construct is just the directive + block.

## Key Takeaways
1. "Region" = dynamic execution (incl. callees); "construct" = static directive+block.
2. "Present" = reference counters sum > 0; the basis of composable data regions.
3. "Compute intensity" (flops/byte-moved) is the metric for whether offload is worthwhile.
4. device/accelerator/local-thread/discrete-vs-shared-memory terms underpin the whole memory model.
5. Where OpenACC terms conflict with base-language usage, the glossary definition governs.

## Connects To
- **Ch 1**: execution & memory models — most terms originate there.
- **Ch 4**: present data, reference counters, data lifetimes.
- **glossary.md**: full alphabetical list.
