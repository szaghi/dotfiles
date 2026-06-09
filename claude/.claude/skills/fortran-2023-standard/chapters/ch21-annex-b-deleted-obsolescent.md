# Chapter 21 (Annex B, informative): Deleted and obsolescent features

## Core Idea
The authoritative "what not to use" list: **deleted** features (removed — a conforming processor must be able to reject them) and **obsolescent** features (still legal, printed in smaller type, candidates for future deletion), each paired with the standard's recommended replacement.

## Deleted features
### From Fortran 90 (B.1)
| Deleted feature | Replacement |
|---|---|
| Real/double-precision DO variables | integer DO + explicit exit test |
| Branching to an END IF from outside its block | branch to a CONTINUE after the END IF |
| `PAUSE` statement | WRITE a message then READ |
| `ASSIGN` / assigned `GO TO` / assigned format | other control constructs; a character variable holding the format |
| `H` edit descriptor | character-string edit descriptor (`'...'`) |
| Vertical format control (column-1 carriage control) | post-process the file |

### From Fortran 2008 (B.2)
| Deleted feature | Why |
|---|---|
| **Arithmetic IF** (`IF (e) l1, l2, l3`) | incompatible with IEEE 60559:2020 (NaN); needs labels; hinders optimization |
| **Nonblock DO** (shared termination / labeled-action terminus) | confusing, error-prone |

## Obsolescent features (B.3) — still legal, avoid in new code
| Obsolescent feature | Replacement |
|---|---|
| **Alternate return** (`*label` args) | return code + `SELECT CASE` |
| **Computed GO TO** | `SELECT CASE` |
| **Statement functions** | internal procedures |
| **DATA among executables** | DATA in the specification part / initializers |
| **Assumed-length character functions** | explicit/deferred length |
| **Fixed source form** | free source form |
| **`CHARACTER*n`** declaration form | `CHARACTER(LEN=n)` |
| **`ENTRY` statements** | separate module/internal procedures |
| **Label form of DO** (`DO 10 i=...`) | block DO (`DO ... END DO`) |
| **COMMON / EQUIVALENCE / block data** | module variables |
| **Specific names for intrinsics** (e.g. `DSQRT`) | the generic name (`SQRT`) |
| **FORALL** construct and statement | `DO CONCURRENT` (ch11) |

## Worked Example
Replacing an alternate return (from B.3.2):
```fortran
! OBSOLESCENT alternate return:
call subr_name(x, y, z, *100, *200, *300)
! ... 100 / 200 / 300 are caller labels

! RECOMMENDED replacement:
call subr_name(x, y, z, return_code)
select case (return_code)
case (1); ...
case (2); ...
case (3); ...
case default; ...
end select
```
- **Demonstrates**: trading an irregular argument-list mechanism for a structured, label-free return-code dispatch.

## Mental Models
- **Deleted ≠ obsolescent.** Deleted features *must* be rejectable by a conforming processor (though many compilers still accept them as extensions). Obsolescent features still conform but signal "migrate away."
- The smaller type font in the normative text *is* the obsolescence marker (4.1.5) — treat it as a deprecation warning baked into the standard.
- Every entry here has a clean modern replacement; there is no obsolescent feature you *need*.

## Anti-patterns
- **FORALL for parallel loops**: obsolescent and rarely optimized well — use `DO CONCURRENT` with locality/REDUCE (ch11).
- **`CHARACTER*n` / specific intrinsic names / labeled DO**: legacy style; modernize to `CHARACTER(LEN=n)`, generic names, block DO.
- **COMMON/EQUIVALENCE/block data for sharing/init**: use module variables with initializers.
- **Arithmetic IF / computed GOTO / assigned GOTO**: deleted or obsolescent — use IF/SELECT CASE.

## Key Takeaways
1. Deleted (must be rejectable): real DO vars, PAUSE, ASSIGN/assigned-GOTO, H descriptor, vertical format control, **arithmetic IF**, nonblock DO.
2. Obsolescent (legal, avoid): alternate return, computed GOTO, statement functions, fixed form, `CHARACTER*n`, ENTRY, labeled DO, COMMON/EQUIVALENCE/block data, specific intrinsic names, **FORALL**.
3. Every item has a documented modern replacement — migration is mechanical.
4. The smaller-font marker in the standard's text is the in-band obsolescence signal.

## Connects To
- **Ch 4**: Conformance — the deleted/obsolescent categories and the smaller-font convention.
- **Ch 11**: Execution control — DO CONCURRENT replaces FORALL; SELECT CASE replaces computed GOTO.
- **Ch 14 & 19**: Modules replace COMMON/EQUIVALENCE/block data.
