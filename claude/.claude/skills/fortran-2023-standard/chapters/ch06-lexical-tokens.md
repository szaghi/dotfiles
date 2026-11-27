# Chapter 6 (Clause 6): Lexical tokens and source form

## Core Idea
Defines the character set, the lexical tokens (names, constants, operators, labels, delimiters), and the two **source forms** (free and fixed). Home of two notable F2023 relaxations: **free-form lines up to 10,000 characters** and the new `.NIL.` token / `?` for conditional expressions.

## Frameworks Introduced
- **Fortran character set**: 26 letters (case-insensitive *except in a character context*), 10 digits, underscore, and the special characters of Table 6.1. `alphanumeric-character` (R601) = letter | digit | underscore.
- **Names** (R603): `letter [ alphanumeric-character ]...`; **C601 caps length at 63 characters**. Case-insensitive. "name" is a strict syntactic form; "identifier" is the looser context-dependent notion.
- **Lexical token** (6.2.1): keyword, name, literal constant (except complex), `.NIL.`, operator, label, delimiter, comma, `=`, `=>`, `:`, `::`, `;`, `..`, `?`, or `%`.
- **Operators** (R608): intrinsic-operator categories — power `**`, mult `* /`, add `+ -`, concat `//`, rel (`.EQ./==`, `.NE./=`, `.LT./<`, `.LE./<=`, `.GT./>`, `.GE./>=`), `.NOT.`, `.AND.`, `.OR.`, `.EQV./.NEQV.`. Defined operators: `.letter[letter]...` (R1004/R1024).
- **Statement labels** (R611): 1–5 digits, at least one nonzero (C603); used only for branch targets, FORMAT, and labeled-DO terminals. 99999 possible labels.

## Key Concepts
- **Two source forms**: free (6.3.2) and fixed (6.3.3, obsolescent). **Must not be mixed in one program unit.** Which form applies is processor-dependent (typically by file extension).
- **Free-form line length** (6.3.2.1): **up to 10,000 characters per line** (F2023 — was 132). No positional restrictions; a line may be empty.
- **Continuation**: free form uses trailing `&` (and optional leading `&` on the next line); fixed form uses a character in column 6.
- **Comments**: `!` to end of line (free form); a line whose first nonblank is `!`, or that is blank, is a comment line. No limit on consecutive comment lines.
- **Blank rules**: blanks separate adjacent keywords/names/constants/labels; Table 6.2 lists keyword pairs where the blank is optional (`ENDIF`/`END IF`, `GOTO`/`GO TO`, etc.).
- **`%`**: component/part selector (`x%re`, `x%im`, derived-type component access).
- **BOZ literals**: binary `B'...'`, octal `O'...'`, hex `Z'...'` constants.

## Reference Tables

### Real-literal kind & complex/char literals (selected token forms)
| Token | Form | Note |
|---|---|---|
| int-literal | `digit-string [_kind-param]` | `123_int64` |
| real-literal | `... [E\|D exp] [_kind]` | `1.0d0`, `3.14_wp` |
| char-literal | `[kind_] '...'` or `"..."` | doubled quote escapes |
| boz-literal | `B'...'` `O'...'` `Z'...'` | binary/octal/hex |
| complex-literal | `( real-part , imag-part )` | blanks allowed inside |

## Anti-patterns
- **Mixing free and fixed form in one program unit**: forbidden; symptoms are cryptic column/continuation errors.
- **Relying on the old 132-char limit**: F2023 allows 10,000 — but wrapping at ~80–132 remains a *style* convention (`fprettify`), not a language limit.
- **Names > 63 characters**: violates C601; a conforming processor must reject.
- **Significant trailing-blank assumptions**: outside a character context, a run of blanks ≡ one blank.

## Worked Example
Free-form continuation and the optional-blank keywords:
```fortran
real :: very_long_expression_result
very_long_expression_result = a*b + c*d &   ! trailing & continues
                            & - e*f          ! optional leading &
if (cond) then; end if          ! ENDIF and END IF both legal (Table 6.2)
```
- Demonstrates: trailing-`&` continuation, that blanks are free between tokens, and the keyword-pair blank-optionality.

## Key Takeaways
1. **Free-form lines now allow up to 10,000 characters** (F2023) — a real change from F2018's 132.
2. Names: ≤63 chars, case-insensitive, `letter` then alphanumerics/underscores.
3. Free and fixed form must never be mixed in one program unit; fixed form is obsolescent.
4. Relational ops have dual spellings (`.LT.`/`<`); both are standard.
5. `?` and `.NIL.` are lexical tokens supporting F2023 conditional expressions and the null pointer/allocatable sentinel.

## Connects To
- **Ch 7**: Types — literal-constant forms map to intrinsic types and kinds.
- **Ch 10**: Expressions — operator precedence and conditional expressions (`?`).
- **Ch 21 (Annex B)**: fixed source form is obsolescent.
