# Chapter 10 (Clause 10): Expressions and assignment

## Core Idea
The expression grammar (five precedence levels), operator precedence, the **F2023 conditional expression** (`( cond ? a : b )`), and the four assignment forms: intrinsic, defined, pointer, and masked (WHERE / FORALL).

## Frameworks Introduced
- **Conditional expression** (10.1.2.3, R1002, **F2023**): `( scalar-logical-expr ? expr [ : scalar-logical-expr ? expr ]... : expr )`. Evaluates each guard in order, picks the first true branch's expr (else the final expr), and **only the chosen expr is evaluated** (short-circuit selection). C1004: every branch expr must share declared type, kind, and rank.
- **Expression levels** (10.1.2): level-1 (defined unary) → level-2 (numeric `** * / + -`) → level-3 (`//`) → level-4 (relational) → level-5 (logical `.NOT. .AND. .OR. .EQV. .NEQV.`). The grammar *is* the precedence.
- **Intrinsic assignment** (10.2.1.2): `var = expr`; for allocatable LHS, automatic (re)allocation to the RHS shape (the "auto-LHS-realloc" semantics, also extended to deferred-length character — see ch04 F2018 delta).
- **Defined assignment** (10.2.1.4): `interface assignment(=)` bound to a subroutine; elemental allowed.
- **Pointer assignment** (10.2.2): `p => target` (data) / `p => proc` (procedure); bounds/rank-remapping forms `p(lb:ub) => t`.
- **Masked assignment**: `WHERE (mask) a = b [ELSEWHERE ...]`; `FORALL (i=...) a(i) = ...` (FORALL is **obsolescent** — prefer DO CONCURRENT).

## Key Concepts
- **Integrity of parentheses** (10.1.8): the processor shall respect parentheses — it may *not* reassociate `(a+b)+c` to `a+(b+c)`. Use parentheses to pin numerically sensitive evaluation order.
- **Evaluation of operands** (10.1.7): operands of `.AND.`/`.OR.` need **not** be short-circuited — Fortran does **not** guarantee short-circuit evaluation of logical operators (unlike C). Side-effecting guards are unsafe.
- **`-A ** 2` parses as `-(A**2)`**: `**` binds tighter than unary minus.
- **Integer division truncates toward zero**; `MOD`/`MODULO` differ in sign handling; F2023 forbids a zero second argument (ch04 F90 delta).

## Reference Tables
### Operator precedence (Table 10.1, high → low)
| Operator | Category |
|---|---|
| `defined-unary-op` | Extension (highest) |
| `**` | Numeric |
| `* /` | Numeric |
| unary `+ -` | Numeric |
| binary `+ -` | Numeric |
| `//` | Character |
| `.EQ. .NE. .LT. .LE. .GT. .GE.` / `== /= < <= > >=` | Relational |
| `.NOT.` | Logical |
| `.AND.` | Logical |
| `.OR.` | Logical |
| `.EQV. .NEQV.` | Logical |
| `defined-binary-op` | Extension (lowest) |

## Worked Example
F2023 conditional expressions (from the standard's own NOTE):
```fortran
msg = ( abs(residual) <= tolerance ? 'ok' : 'did not converge' )
val = ( i > 0 .and. i <= size(a) ? a(i) : present(opt) ? opt : 0.0 )
```
Pointer rank-remapping and WHERE:
```fortran
real, target  :: flat(100)
real, pointer :: mat(:,:)
mat(1:10, 1:10) => flat        ! remap rank-1 target as 10x10
where (a > 0.0)
  b = sqrt(a)
elsewhere
  b = 0.0
end where
```
- **Demonstrates**: conditional-expr chaining (note nested `?`), the only-chosen-branch evaluation, pointer remapping, and masked assignment.

## Anti-patterns
- **Assuming short-circuit `.AND.`/`.OR.`**: Fortran may evaluate both operands. Guard pointer/array-bound checks with a *conditional expression* or nested IF, never `if (allocated(a) .and. a(1) > 0)`.
- **Relying on reassociation for speed**: parentheses are honored (10.1.8); but writing `(a+b)+c` to control rounding is *exactly* the right tool for numerically sensitive sums (cf. pairwise/Kahan summation, `feedback_diagnostic_precision_floor`).
- **Using FORALL for performance**: it's obsolescent and rarely faster; use **DO CONCURRENT** (ch11) for parallel-safe loops.
- **Forgetting auto-reallocation of an allocatable LHS**: `a = b` may silently reallocate `a` to `b`'s shape — usually wanted, occasionally a hidden cost.

## Key Takeaways
1. **F2023 conditional expressions** `( cond ? a : b )` evaluate only the chosen branch; all branches must match type/kind/rank.
2. `**` > unary `-`; precedence follows Table 10.1 top-to-bottom.
3. Fortran does **not** short-circuit `.AND.`/`.OR.` — never write bound-guard-then-access in one logical expression.
4. Parentheses are honored and **not** reassociated — your tool for pinning floating-point evaluation order.
5. Four assignments: intrinsic (auto-realloc allocatable LHS), defined, pointer (with rank remapping), masked (WHERE; FORALL obsolescent).

## Connects To
- **Ch 6**: Lexical tokens — operator spellings, the `?` token.
- **Ch 11**: Execution control — DO CONCURRENT supersedes FORALL.
- **Ch 15**: Procedures — defined operators/assignment via OPERATOR/ASSIGNMENT interfaces.
- **Ch 17**: IEEE — evaluation order and parentheses for FP reproducibility.
