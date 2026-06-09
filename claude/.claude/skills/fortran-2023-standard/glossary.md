# Glossary — Fortran 2023 Standard

Key normative terms (Clause 3 has 243; this is the high-leverage subset). Format: **Term** — definition (Ch).

**actual argument** — an expression, variable, or procedure passed in a procedure reference; associated with a dummy argument (15).
**allocatable** — attribute for an object whose allocation status is dynamic; auto-deallocated at scope exit (8).
**array section** — a designator selecting a subset of an array via triplets or vector subscripts (9).
**assumed-rank** — dummy `a(..)` whose rank is taken from the actual argument; used with SELECT RANK (8, 11).
**assumed-shape** — dummy `a(:)` whose extents come from the actual; **lower bound defaults to 1** (8).
**assumed-size** — dummy `a(*)`; last dimension size unknown; legacy/interop (8).
**assumed-type** — `TYPE(*)` dummy; unlimited polymorphic, opaque pass-through (7).
**association** — a relationship by which an entity is reachable by another name/storage; 9 kinds (3, 19).
**attribute** — a property of an entity (ALLOCATABLE, POINTER, INTENT, …) (8).
**BIND(C)** — gives an entity C linkage and an optional binding label (18).
**BLOCK construct** — a nested scope permitting local declarations within the execution part (11).
**characteristics** — the fixed properties of a procedure/dummy used in interface matching (15).
**CLASS(*)** — unlimited polymorphic declaration; dynamic type may be anything (7).
**coarray** — an object with codimensions, accessible across images (8, 9).
**collating sequence** — processor-dependent ordering of a character set (3, 20).
**conditional expression** — F2023 `( cond ? a : ... : b )`; only the chosen branch evaluates (10).
**conformable** — arrays/scalars compatible in shape for an operation (3).
**constant expression** — expression guaranteed constant; gates kind selectors, bounds, initializers (3, 10).
**construct entity** — an entity whose scope is a construct (e.g. ASSOCIATE name, DO index) (19).
**contiguous** — object whose elements are not separated in memory; CONTIGUOUS attribute / IS_CONTIGUOUS (3, 8).
**declared type** — the static type of an entity (vs dynamic type) (3, 7).
**deferred type parameter** — a `:` type parameter set by ALLOCATE/assignment/pointer-assign (7).
**defined / undefined** — whether a variable currently holds a valid value (19).
**dummy argument** — the procedure-side placeholder associated with an actual argument (15).
**dynamic type** — the runtime type of a polymorphic entity (3, 7, 11).
**elemental** — a procedure defined on scalars that applies element-wise to arrays; implicitly pure (15).
**enum type** — F2023 integer-backed type declared `ENUM`/`ENUM, BIND(C)`, used as `TYPE(name)` (7).
**enumeration type** — F2023 ordinal nonintrinsic type via `ENUMERATION TYPE`; not interoperable (7).
**extensible type** — a type that may be extended via EXTENDS (7).
**final subroutine** — a FINAL-bound subroutine invoked on finalization; order processor-dependent (7, 20).
**generic resolution** — selecting a specific procedure from a generic by type/kind/rank/presence (15).
**host association** — access to a host scoping unit's entities from a contained unit (19).
**image** — an instance of the program in coarray/parallel execution (1, 9).
**IMPORT** — statement controlling host association into an interface body/BLOCK (14, 19).
**INTENT** — IN / OUT / INOUT use specification for a dummy; OUT undefines/deallocates on entry (8).
**interoperable** — having a defined correspondence with a C entity (18).
**intrinsic type** — integer, real, complex, character, logical (7).
**kind type parameter** — integer parameter known at compile time; drives generic resolution (7).
**length type parameter** — integer parameter that may vary at runtime; does not drive generics (7).
**module** — program unit whose public entities are accessible by use association (14).
**named constant** — a data object with the PARAMETER attribute (3, 8).
**pointer association** — link between a pointer and its target; associated/disassociated/undefined (19).
**polymorphic** — able to be of differing dynamic types; declared with CLASS (7).
**potential subobject component** — a component that could be a subobject; affects finalization/init (3).
**processor** — compiler + runtime + system implementing Fortran (1, 4).
**processor-dependent** — behavior the standard leaves to the processor; cataloged in Annex A (4, 20).
**PROTECTED** — module variable read-only outside its defining module (8).
**pure** — procedure with no side effects; required for DO CONCURRENT bodies, spec expressions (15).
**RANK clause** — declare rank separately for rank-agnostic code (8).
**SELECT RANK** — construct dispatching on the rank of an assumed-rank dummy (11).
**SELECT TYPE** — construct dispatching on the dynamic type of a polymorphic selector (11).
**simple** — F2023 prefix: pure **and** result depends only on arguments (no host/use/COMMON state) (15).
**simply contiguous** — a designator the compiler can prove contiguous syntactically (9).
**SOURCE= / MOLD=** — ALLOCATE options copying value+shape / shape+type only (9).
**stream access** — byte-addressable file access via POS= (12).
**submodule** — a program unit holding the bodies of a module's separate module procedures (14).
**TARGET** — attribute marking an object as a permissible pointer target (8).
**TYPEOF / CLASSOF** — F2023 specifiers declaring an entity that mirrors a data-ref's type (non-poly / poly) (7).
**type parameter inquiry** — `x%kind`, `s%len` (9).
**unlimited polymorphic** — `CLASS(*)` or `TYPE(*)`; no declared type (7).
**use association** — access to module entities via USE (14, 19).
**variable definition context** — syntactic positions where a variable may be defined (19).
**vector subscript** — array section by an integer index array (gather/scatter) (9).
