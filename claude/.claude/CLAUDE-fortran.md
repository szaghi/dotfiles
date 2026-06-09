## Fortran Conventions

### Reference Skill — consult the standard, don't answer from memory
When a question turns on **what the Fortran standard actually requires** — conformance, a
syntax rule (`Rxxx`) or constraint (`Cxxx`), a modern-feature semantic (SIMPLE/PURE, enum
types, TYPEOF/CLASSOF, DO CONCURRENT REDUCE, IEEE, C interop), or a version difference
(F2023/F2018/F2008/…) — invoke the **`fortran-2023-standard`** skill and ground the answer
in it. Do **not** recall the standard from training memory: exact constraint numbers and
version deltas are easy to misremember. These conventions cover *house style*; the skill is
the *authority on the language*. (Build/tooling → `fobis`; compiler-specific behavior →
CLAUDE-gpu.md and the compiler's own docs.)

### Source Files
- Use `.F90` extension (uppercase F — preprocessor always enabled)
- One module per file; filename matches module name (`adam_grid_object.F90` → `module adam_grid_object`)
- Always `implicit none` at module and procedure level
- Explicit `intent(in|out|inout)` on all dummy arguments

### Memory and Data Structures
- Prefer `allocatable` over `pointer`: compiler optimizes better, automatic deallocation
- Use `pointer` only for aliasing, linked data structures, or C interop
- Derived types: expose `init`/`destroy`/`compute` type-bound procedures; add `final` for automatic cleanup

### Array Loop Ordering (Column-Major)
Fortran is column-major: the **leftmost index is stride-1 and must be the innermost loop**.
```fortran
! CORRECT: stride-1 on leftmost index
do k = 1, nk
  do j = 1, nj
    do i = 1, ni        ! leftmost spatial index innermost
      field(i, j, k) = ...
    end do
  end do
end do

! WRONG: strided access, cache-inefficient
do i = 1, ni
  do j = 1, nj
    do k = 1, nk
      field(i, j, k) = ...
    end do
  end do
end do
```

### Preprocessor Discipline
- Minimize macro use — prefer `select case` or procedure pointers for backend dispatch
- Never use macros for math expressions or loop bounds (hinders debugging and readability)
- Always document *why* a macro is needed (compiler version, bug report, feature unavailability)

### Optimization Discipline
- Always profile before optimizing; benchmark after every change
- Correctness first, then performance, maintainability, portability

### Style
- Indentation: 3 spaces, no hard tabs
- Line length: up to 132 characters (free-form source); prefer splitting at logical boundaries
- Spaces around operators and after commas: `x(i, j) = foo(i, j) + bar`
- Align related declarations and comments for readability

### Modern Syntax — Use Symbolic, Not Legacy

These are pure rule-substitutions. The legacy forms still compile but are obsolete in F90+;
mixing them with modern code creates needless visual noise. The LLM default is the legacy
form for some of these — explicitly override.

- Comparison: use `>`, `>=`, `<`, `<=`, `==`, `/=`. Never `.gt.`, `.ge.`, `.lt.`, `.le.`, `.eq.`, `.ne.`.
- Array constructors: use `[ 1, 2, 3 ]`. Never `(/ 1, 2, 3 /)`.
- Logical equivalence: use `.eqv.` / `.neqv.` for `logical` operands. `==` and `/=` are
  not standard-conforming on `logical` operands, even though most compilers accept them.
  For `if (flag .eqv. .true.)`-style code, prefer the direct form `if (flag)` instead.
- Keywords lowercase: `do`, `if`, `then`, `end`, `subroutine`, `module`. Never `DO`, `IF`, `THEN`.

### Kind Specifications (Portability)
- Use `iso_fortran_env` kinds (`int32`, `real64`) or `selected_*_kind` — never bare `real` or `integer`
- Always suffix literal constants with the kind parameter: `3.14_R8`, `1.0_real64`
- Use `iso_c_binding` for C interop types

#### Forbidden kind-violating patterns

These are the LLM's default Fortran sins — the forms generated when no kind discipline
is enforced. Reject every one of them on sight; they bypass the kind system, hardcode
precision, and silently break single/mixed-precision builds.

- `dsqrt`, `dexp`, `dlog`, `dabs`, `dcos`, `dsin`, `dtan`, `datan`, `datan2`, `dble`,
  `dmin1`, `dmax1`, etc. → use the **generic intrinsics** `sqrt`, `exp`, `log`, `abs`,
  `cos`, ...; let the compiler resolve to the right kind from the argument.
- `1.0d0`, `2.5d-3`, `1.d-12` (the `d` exponent literal) → use kind-suffixed literals:
  `1.0_R8P`, `2.5e-3_R8P`. The `d` form silently locks to double precision.
- `real(8)`, `real(4)`, `real(16)` → bare numeric kinds are non-portable and
  meaningless across compilers. Use `real(R8P)` / `real(real64)` via your kind module.
- `double precision` keyword → use `real(R8P)` / `real(real64)`.
- `dble(x)` for type conversion → use `real(x, R8P)` / `real(x, real64)`.
- Hardcoded byte sizes like `int(8._R8P, 8)` → use `storage_size(0._R8P)/8` or
  `c_sizeof` for portability across precision modes.
- Bare integer-kinded "real" literal like `2_R8P` → spelled `2.0_R8P`; `2_R8P` is an
  *integer* literal of kind R8P, not a real, and silently wrong in expressions expecting a real.

The single test: every floating-point literal and every intrinsic call must compile
identically when `R8P` is redefined from `real64` to `real32` (single precision) or to
`real128` (quad). If anything breaks under that re-definition, the discipline is violated.

### Implicit SAVE Trap
Initializing a local variable **at declaration** gives it implicit `SAVE` — its value persists across calls:
```fortran
! WRONG: ke has implicit SAVE — persists between calls
real function kinetic_energy(v)
   real :: ke = 0.0   ! implicit SAVE!
   ...
end function

! CORRECT: initialize in executable section
real function kinetic_energy(v)
   real :: ke
   ke = 0.0           ! reset each call
   ...
end function
```

### `pure` Annotation Must Match Reality — Module-Scope Reads Break It Under Debug

Declaring a function `pure function` is a hard contract: the body may not access any
entity outside its argument list, except `parameter` constants and intrinsic functions
known-pure. Reading a module-scope variable (a singleton, a configuration flag, a
logger handle, a `use`-imported `target` derived type's components) violates the
contract — even when the read is "obviously harmless" like fetching an MPI rank-prefix
string for log formatting.

Release builds (`gfortran -O2`, `ifort` default) typically compile the function anyway
and produce correct output — the violation is silent. **Debug builds**
(`-fcheck=all -fbounds-check`, `-check all -traceback`) trip on the same code with an
obscure SIGSEGV inside the impure expression, usually at a string concatenation, an
allocatable-component access, or a derived-type-component dereference. The backtrace
points at the offending expression line, not at the `pure` keyword on the function
declaration — so the diagnosis is hard. Symptom that flags this class: *"release-mode
run is fine, debug-mode build segfaults during initialization, and the segfaulting
line is inside a method like `description()` / `to_string()` / `summary()` that
formats and returns a string."* Suspect a `pure function` on that method that reaches
into a module-scope singleton.

*Why:* `-fcheck=all` enables descriptor / pointer / allocation-status sanity checks;
the compiler's purity assumption lets it skip those checks inside `pure` bodies on
the basis that purity excludes the conditions they catch. The mismatch between
assumed purity and actual module-scope access then aliases into use-after-something
at runtime.

*How to apply:* if a "pure" function reads any module-scope state, **drop the `pure`
annotation** — the function is not pure. Alternatively, refactor to pass the needed
module state as an explicit dummy argument; then `pure` is honest and the compiler's
optimizations stay valid. Same rule applies to `elemental pure` — `elemental` does
not relax purity.

### Error Handling
- Never ignore error codes from `allocate`, MPI, or I/O operations
- Always use `stat=` and `errmsg=` with `allocate`/`deallocate`
- Check MPI return codes explicitly
- Use `error stop 'message'` for unrecoverable errors — never silent failure

### Array Programming
- Prefer whole-array syntax when vectorizable: `a(:,:) = b(:,:) + c(:,:)`
- Add `contiguous` attribute on performance-critical dummy arguments: `real(rp), intent(in), contiguous :: a(:,:,:)`
- Avoid assumed-size arrays `a(*)` — use assumed-shape `a(:)` or explicit-shape instead
- **Rank-N dummies for arrays-with-ghosts: use EXPLICIT bounds, never assumed-shape.** When the caller declares `U(1:nb, 1-ng:ni+ng, ..., 1:nc)`, an assumed-shape dummy `U(:,:,:,:,:)` silently rebases all lower bounds to 1 inside the callee — so `U(b, 1:ni, ...)` selects the lower ghost region, not the interior. *Why:* silent semantic bug, no compiler warning, `-fbounds-check` does not catch it (indices in range, just wrong). Symptom: constant relative L2 error invariant in step count. *How to apply:* every helper taking ghost-extended arrays must declare the dummy as `real(rp), intent(...) :: U(1:nb, 1-ng:ni+ng, 1-ng:ni+ng, 1-ng:ni+ng, 1:nc)`. The block/component dimensions can be assumed-shape; the ghost-extended spatial ones cannot.

### Module Visibility
- All module entities `private` by default; explicitly declare `public` only the API surface
- Type components `private` unless external access is required
- Use `use module, only: ...` at all use sites — no implicit wildcard imports

### Module Wiring — Completeness Envelope

A task that creates or moves a Fortran module file is **not done** until the module is
reachable from the rest of the project. "Reachable" means at least one consumer file
contains a `use ModuleName, only: ...` and a call site that exercises the new symbols,
and the project build (FoBiS / make / fpm) still compiles.

Rules — apply on every task that creates, splits, or relocates a `.F90`:

1. **Same-task wiring.** Creating the module and adding `use` in consumers is **one task**,
   not two. Splitting them leaves a window where the new file exists but is dead code, and
   the second task depends on wiring that may not exist yet.
2. **Public surface must be explicit.** If callers will `use` new symbols, declare them
   `public ::` explicitly — do not rely on the module being public-by-default. (You
   default to `private`-by-default per the rule above; this is the corollary.)
3. **Update stale `use` lists on rename/move.** Renaming or moving a module without
   sweeping all `use OldName` sites is a guaranteed build break — grep before committing.
4. **Self-test, every time.** After the change, the question to ask is:
   *"If I run `fobis build` (or `make` / `fpm build`) right now, does the new code compile
   AND is it reached from at least one call site?"* If either half fails, the task is
   incomplete — don't move on.

A module file with no `use` referencing it is dead code by definition. The compiler will
not warn; only the wiring discipline catches this.

### Method Extraction From a Legacy Loop — Absorb the Whole Iteration Body

When carving a method out of a long-lived loop body (a `do while`, a time-stepping
integration loop, a per-timestep substage loop), the extracted method must absorb
**every** inline operation the loop wrapper ran during that iteration — not just the
obvious "compute" body. The non-obvious operations include counters being incremented,
caps applied to arguments, progress printing, cadence-gated side dumps, AMR/IO hooks,
and barriers used as timing fences. *Why:* the original loop wrapper keeps calling the
extracted method, so the leftover inline operations continue to fire **for that
caller** and the bug is invisible. The moment a **different** orchestrator drives the
extracted method (a new wrapper, a different framework loop, a test harness), the
missing operations stop firing — and the failure mode is "loop never terminates" or
"output frozen at iteration 0", which reads like a counter bug rather than an
extraction bug.

*How to apply:* before committing an extraction, diff the original loop body against
the new method's body **plus** the new wrapper. Anything in the original body that
doesn't appear in either half is a leak. The "behavior unchanged" claim is true only
for the original caller; a new caller will expose every leak. Regression suites
driven only by the original caller cannot catch this — they pass through the leak
path. The right test is to drive the extracted method from a NEW caller (even a
trivial one that just calls the method N times) and check the output matches the
original loop's output for the same inputs.

### OOP & Encapsulation

#### Per-component vs blanket `private`
Two ways to make derived-type components private — they are NOT interchangeable:

```fortran
! Blanket — all-or-nothing. Every component declared after it is private.
type :: t
   private
   integer :: a   ! private
   integer :: b   ! private
endtype

! Per-component attribute — mix freely with public components.
type :: t
   integer, private :: a   ! private
   integer          :: b   ! public
endtype
```

The blanket `private` statement applies to all subsequent components and **cannot be
overridden** for a single later component. To get partial encapsulation (e.g. one
public allocatable + several private scalars), use the `, private` attribute on each
hidden component individually.

Same applies to type-bound procedures: `procedure, private :: helper` works per-binding.

When in doubt about a Fortran rule, write a 5-line test program and compile it. Do not
guess from C++/Java intuition.

#### Function-result component access — chained `func()%component` is illegal
Fortran does NOT allow `surface%get_bmax()%x` (component access on a function result).
Three workarounds:

```fortran
! 1. Local temp
v = surface%get_bmax(); print *, v%x

! 2. associate (preferred — scoped, no name pollution)
associate (v => surface%get_bmax())
   print *, v%x
end associate

! 3. Method chain on a derived-type function result IS allowed (TBP call, not %)
print *, surface%get_bmax()%norm()   ! OK if get_bmax returns a type with %norm()
```

Use `associate` over scalar accessors-per-component (`get_bmax_x()`, `get_bmax_y()`,
`get_bmax_z()`) — three accessors per vector is API noise.

#### Encapsulation without copy-cost (zero-copy patterns)

The "private + accessor = copy" intuition is wrong for Fortran. Patterns that preserve
encapsulation at zero data-copy cost:

| Pattern | Use for | Cost |
|---|---|---|
| `pure function get_x(self)` returning a scalar / small derived type | Read access to scalar state | Inlined at -O2 |
| `function ptr(self)` returning `pointer` to internal array | Whole-array read-write external access | Pointer descriptor only |
| `subroutine adopt(self, arr)` using `move_alloc(arr, self%arr)` | Hand off ownership from caller | Pointer swap |
| `subroutine for_each(self, op)` taking a procedure pointer | Mutate every element without exposing storage | None |
| Index-based mutator `subroutine set_at(self, i, v)` | Single-element writes | None |

Pointer-returning accessors require `target` on the component AND on `self` in the accessor
signature, and the accessor cannot be `pure`. Reserve them for cases where the whole-array
view is genuinely needed by external code.

#### When NOT to encapsulate
Genuine cases for keeping components public:
- POD value types whose fields ARE the contract (`vector_R8P`'s `%x %y %z`, geometric
  primitives in tight kernels).
- Hot inner-loop element fields where accessor inlining can't be relied upon (verify with
  `-fdump-tree-optimized` before keeping public).
- Internal state-machine records with no invariants worth defending.

For domain types that carry invariants (sizes that must match arrays, init flags, file
handles) — encapsulate. The dispatch-knob lesson: if external code is poking a flag like
`is_initialized=.false.` to force a code path, the right fix is a separate `set_*` mutator
expressing intent, not exposing the invariant flag. Don't lie about state to control
behaviour.

#### Assignment overloads are easy to get wrong
When overloading `assignment(=)`, the procedure must explicitly copy every component.
Forgetting one silently corrupts the LHS — the compiler will not warn. Common bug pattern:
adding a new component to the type and forgetting to update the assignment overload.

If the type's components are all-allocatable / intrinsic-assignable, **prefer dropping
the overload entirely** — Fortran 2003+ intrinsic assignment correctly deep-copies
allocatable components. Custom overloads should exist only when copy semantics genuinely
differ from the intrinsic (shallow copy of pointers, lazy clone, etc.).

#### Finalisers (`final ::`) for arrays-of-types
A type with `allocatable` components needs a `final :: cleanup` procedure to release
storage when wrapped in an `allocatable :: arr(:)` of that type. Without it, gfortran
mostly does the right thing today, but ifort and older compilers leak.

```fortran
type :: container
   integer, allocatable :: data(:)
contains
   final :: container_finalize
endtype

contains
   subroutine container_finalize(self)
   type(container), intent(inout) :: self   ! NOT class — final must take type
   if (allocated(self%data)) deallocate(self%data)
   endsubroutine
```

Note the `type(...)` (not `class(...)`) on the finaliser dummy.

### I/O
- Use standard units from `iso_fortran_env`: `input_unit`, `output_unit`, `error_unit`
- Never hardcode unit numbers 5/6

### OpenMP
- Always `default(none)` — forces explicit scoping of all variables, catches bugs
- Use `reduction(op:var)` for accumulations; never manually sum into a shared variable
- Use `workshare` for array-syntax parallelism

