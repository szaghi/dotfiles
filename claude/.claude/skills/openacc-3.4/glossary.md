# Glossary — OpenACC 3.4

Key terms from the spec's Glossary (Ch 6) plus directive/clause vocabulary. Format: **Term** — definition (Ch).

**Accelerator** — a device attached to a CPU to which data/compute is offloaded (Ch1, 11).
**Accelerator routine** — a procedure compiled for the device via the `routine` directive (Ch7).
**Aggregate datatype** — any non-scalar type (array, struct, derived type); implicitly `copy` in a compute construct (Ch4, 11).
**async-argument** — nonnegative scalar int selecting an activity queue, or a special `acc_async_*` value (Ch7).
**Activity queue** — an in-order stream of device operations; same async-value → same queue (Ch7).
**`atomic`** — construct ensuring race-free read/write/update/capture of one location (Ch6).
**`attach`/`detach`** — translate a host pointer member to its device target address (Ch4).
**Barrier** — synchronization point; not portable across gangs/workers/vector lanes (Ch1).
**`cache`** — directive hinting array elements into fast memory for a loop (Ch5).
**`collapse(n)`** — fuse n tightly-nested loops; `collapse(force:n)` allows non-tight nests (v3.4) (Ch5).
**Combined construct** — `parallel loop`/`kernels loop`/`serial loop` shorthand (Ch5).
**Compute construct** — `parallel`, `serial`, or `kernels` (Ch3, 11).
**Compute intensity** — arithmetic ops ÷ data moved; the offload-worthwhileness metric (Ch1, 11).
**Compute region** — the dynamic execution of a compute construct (incl. callees) (Ch11).
**`copy`/`copyin`/`copyout`/`create`** — data clauses: in+out / in / out / scratch (Ch4).
**`declare`** — associate a device copy with a variable's scope (module/global/program) (Ch6).
**`default(none|present)`** — force explicit data clauses / assume present (Ch3, 4).
**`device_resident`** — declare data living only on the device (Ch6).
**`device_type` (`dtype`)** — per-architecture clause partitioning on a directive (Ch2).
**Device thread** — one vector lane of one worker of one gang (Ch1, 11).
**Discrete memory** — device memory not accessible from the local thread (needs copies) (Ch1, 11).
**`enter data`/`exit data`** — unstructured (non-lexical) device data lifetimes (Ch4, 6).
**`firstprivate`** — per-gang private initialized from the host value (Ch3).
**Gang** — coarse-grain parallelism, organized in a 1–3D grid; no portable inter-gang sync (Ch1, 5).
**GR / GP mode** — gang-redundant (all gangs run same code) / gang-partitioned (iterations split) (Ch1).
**`host_data use_device`** — expose a present var's device address to host code (Ch5).
**ICV** — internal control variable (device type/num, default async) (Ch2).
**`if(cond)`** — run on device conditionally; on `data`, skip all alloc/transfer if false (Ch3, 4).
**`independent`** — assert loop iterations are parallel-safe (default on `parallel`) (Ch5).
**`kernels`** — compute construct where the compiler parallelizes each loop (Ch3).
**Kernel** — a nested loop executed in parallel on the device (Ch11).
**Local thread/device/memory** — the thread executing a directive (host or device) and its device/memory (Ch1, 11).
**`loop`** — maps iterations to gang/worker/vector/seq parallelism (Ch5).
**`no_create`** — use a device copy if present, else operate locally; never allocate (Ch4).
**`nohost`** — `routine` clause: don't compile a host version (Ch7).
**Orphaned loop** — a `loop` with no enclosing compute construct (Ch5, 11).
**`parallel`** — compute construct; programmer asserts parallelism + controls geometry (Ch3).
**Parent compute construct/scope/procedure** — nearest enclosing compute construct / either / procedure (Ch3, 11).
**Present data** — structured + dynamic reference counters sum > 0 (resident on device) (Ch4, 11).
**`present`** — data clause asserting data is already on device (error if not) (Ch4).
**`private`** — per-iteration/per-gang private copy (Ch3, 5).
**Reference counter** — structured + dynamic counts; data freed when both reach 0 (Ch4).
**`reduction(op:vars)`** — combine partial results across gangs/workers/lanes (Ch3, 5).
**Region** — all code executed during a construct instance, including called procedures (Ch11).
**`routine [gang|worker|vector|seq]`** — make a procedure device-callable at a parallelism level (Ch7).
**Scalar** — intrinsic non-aggregate type; implicitly `firstprivate` in a compute construct (Ch4, 11).
**`self`** — compute: run on local thread; update: copy device→host (Ch3, 6).
**`seq`** — execute a loop/routine sequentially (no parallelism) (Ch5).
**`serial`** — compute construct: one gang, one worker, vector length 1 (Ch3).
**Shared memory** — accessible from both local thread and current device; no copy needed (Ch1, 11).
**Structured vs unstructured data** — lexically-scoped (`data`) vs `enter/exit data` lifetimes (Ch4).
**`tile(sizes)`** — block a loop's iteration space for locality (Ch5).
**`update self`/`device`** — refresh resident data host↔device without changing lifetime (Ch6).
**Vector** — SIMD/vector-lane parallelism within a worker (Ch1, 5).
**`wait[(q)] [async(q2)]`** — block host on queue(s), or make q2 depend on q (device-side) (Ch7).
**Worker** — fine-grain parallelism (threads within a gang) (Ch1, 5).
