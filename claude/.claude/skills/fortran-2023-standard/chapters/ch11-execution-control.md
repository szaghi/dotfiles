# Chapter 11 (Clause 11): Execution control

## Core Idea
All control-flow constructs: BLOCK, ASSOCIATE, IF, SELECT CASE/TYPE/RANK, DO (incl. **DO CONCURRENT with the F2023 REDUCE locality**), CRITICAL, CHANGE TEAM, and the branch/stop statements. The home of the parallel-loop and polymorphic-dispatch constructs.

## Frameworks Introduced
- **DO CONCURRENT** (11.1.7.4.2, 11.1.7.5): asserts iterations are independent so the processor may run them in any order / in parallel. `concurrent-locality` (R1130):
  - **LOCAL(vars)** — each iteration gets a fresh, uninitialized copy.
  - **LOCAL_INIT(vars)** — fresh copy initialized from the outer value on entry.
  - **SHARED(vars)** — shared across iterations (caller's variable).
  - **DEFAULT(NONE)** — force explicit locality for every variable (discipline; like OpenMP).
  - **REDUCE(op : vars)** (**F2023**) — reduction with op ∈ `+ * .AND. .OR. .EQV. .NEQV.` or function `IAND IEOR IOR MAX MIN` (C1122). Reduce vars must be intrinsic type, definable, not ASYNCHRONOUS/VOLATILE/coindexed/assumed-size (C1131).
- **SELECT TYPE** (11.1.11): dispatch on the *dynamic* type of a polymorphic selector — `type is (t)`, `class is (t)`, `class default`. The associate name takes the guarded type in each block.
- **SELECT RANK** (11.1.10): dispatch on the rank of an assumed-rank (`a(..)`) dummy — `rank(0)`, `rank(1)`, `rank(*)` (assumed-size), `rank default`.
- **ASSOCIATE** (11.1.3): bind a name to an expression/variable for the construct's scope — readability + avoids recomputation.
- **BLOCK** (11.1.4): a nested scope with its own declarations *inside* the execution part — the standard way to introduce late/locally-scoped variables.
- **CHANGE TEAM / CRITICAL** (11.1.5–6): coarray team scoping and mutual exclusion across images.

## Key Concepts
- **DO CONCURRENT body must be pure-ish**: no branches out, no image control, no impure procedure calls that violate independence; the mask must be pure (C1123).
- **CRITICAL**: only one image executes the block at a time (cross-image lock).
- **EXIT / CYCLE**: leave / skip-to-next-iteration; may name a construct label.
- **STOP / ERROR STOP**: normal vs error termination; ERROR STOP signals failure to the environment.
- **GO TO / arithmetic IF**: present but **obsolescent** (arithmetic IF, computed GOTO).

## Worked Example
F2023 DO CONCURRENT reduction (the construct most relevant to HPC):
```fortran
real    :: a(n), total
integer :: i
total = 0.0
do concurrent (i = 1:n) reduce(+:total) default(none) shared(a)
  total = total + a(i)          ! parallel-safe reduction, F2023
end do
```
Polymorphic dispatch + rank dispatch:
```fortran
select type (p => obj)          ! dynamic-type dispatch
type is (real);     print *, p          ! p is real here
class is (shape_t); call p%area()       ! p is class(shape_t)
class default;      error stop 'unknown'
end select

select rank (a)                 ! a is assumed-rank a(..)
rank (1); call kern1d(a)
rank (2); call kern2d(a)
rank default; error stop
end select
```
- **Demonstrates**: REDUCE locality (the new parallel-reduction primitive), SELECT TYPE narrowing the associate name, SELECT RANK over assumed-rank dummies.

## Anti-patterns
- **Pre-F2023 DO CONCURRENT reductions via SHARED + atomics**: now expressible with `REDUCE`; the old workaround was error-prone — but note DO CONCURRENT independence is a *programmer assertion*, the processor need not parallelize it (cf. `feedback_gpu_benchmark_timing` — verify it actually offloaded).
- **Treating DO CONCURRENT as a parallelism guarantee**: it permits, not mandates, parallel execution; a serial processor may run it sequentially.
- **Mutating SHARED vars without REDUCE**: data race / undefined; only REDUCE/atomic patterns are safe for cross-iteration accumulation.
- **Using arithmetic IF / computed GOTO**: obsolescent — use IF/SELECT CASE.
- **Forgetting `class default`/`rank default`**: an unmatched dynamic type/rank with no default is a program error.

## Reference Tables
### DO CONCURRENT locality specs (R1130)
| Spec | Per-iteration semantics |
|---|---|
| `LOCAL(v)` | fresh, uninitialized |
| `LOCAL_INIT(v)` | fresh, initialized from outer value |
| `SHARED(v)` | shared (caller's) |
| `REDUCE(op:v)` | reduction (F2023) |
| `DEFAULT(NONE)` | require explicit locality for all |

## Key Takeaways
1. **F2023 `DO CONCURRENT ... REDUCE(op:var)`** is the standard parallel-reduction primitive — op ∈ `+ * .AND. .OR. .EQV. .NEQV.` / `IAND IEOR IOR MAX MIN`.
2. `DEFAULT(NONE)` forces explicit locality — adopt it like `implicit none` for parallel loops.
3. DO CONCURRENT permits but does not require parallel execution — always verify offload/vectorization actually happened.
4. SELECT TYPE dispatches on dynamic type; SELECT RANK on assumed-rank dummy rank.
5. BLOCK gives a nested scope for late declarations; ASSOCIATE binds readable names.

## Connects To
- **Ch 7**: Types — SELECT TYPE resolves declared vs dynamic type.
- **Ch 8**: Attributes — assumed-rank `a(..)` feeds SELECT RANK; locality interacts with attributes (C1130/C1131).
- **Ch 16**: Intrinsics — atomic subroutines, image control, ISO_FORTRAN_ENV team/event types.
- **Ch 21 (Annex B)**: arithmetic IF, computed GOTO are obsolescent/deleted.
