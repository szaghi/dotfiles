# Chapter 13 (Clause 13): Input/output editing

## Core Idea
Format specifications and edit descriptors — how values map to/from text. Numeric, logical, character, and generalized editing; control descriptors; and the **F2023 additions: `AT` (auto-trim) and `LZS`/`LZP`/`LZ` (leading-zero control)**.

## Frameworks Introduced
- **Format specification** (13.1): a parenthesized list of edit descriptors, in a FORMAT statement (labeled) or a character expression (`FMT='(...)'`).
- **Data edit descriptors** (13.7): `I` (integer), `F`/`E`/`EN`/`ES`/`D` (real), `G` (generalized), `B`/`O`/`Z` (binary/octal/hex), `L` (logical), `A` (character), `DT` (derived-type), `EX` (hex real).
- **Control edit descriptors** (13.8): `T`/`TL`/`TR`/`X` (positioning), `/` (slash, new record), `:` (colon, stop if list exhausted), `SS`/`SP`/`S` (sign), `BN`/`BZ` (blank handling), `RU`/`RD`/`RZ`/`RN`/`RC`/`RP` (rounding), `DC`/`DP` (decimal comma/point), `P` (scale factor).
- **F2023 new descriptors**:
  - **`AT`** — like `A` but **auto-trims trailing blanks** (writes the trimmed character value; convenient for variable-width text).
  - **`LZS` / `LZP` / `LZ`** — leading-zero control: suppress / print / (LZ) the leading-zero behavior for numeric output.

## Key Concepts
- **`I0`, `F0.d`, `G0`**: zero-width forms — minimal field width, no padding. The idiom for clean, width-agnostic output.
- **`ES`/`EN`**: scientific (`d.dddE±xx`, one digit before point) vs engineering (exponent a multiple of 3).
- **Reversion**: when the list outlasts the format, control reverts to the last top-level `( )` group, emitting a new record.
- **`*` repeat / unlimited**: `'(*(...))'` repeats the group as needed (F2008) — pairs well with list output of unknown length.
- **Rounding modes** (`RU`/`RD`/`RZ`/`RN`/`RC`): up/down/zero/nearest/compatible — match IEEE rounding for reproducible text (ch17).
- **`DC`/`DP`**: decimal comma vs point (locale-style), per-connection or per-descriptor.

## Reference Tables
### Common data edit descriptors
| Descriptor | Meaning | Idiom |
|---|---|---|
| `Iw[.m]` / `I0` | integer | `I0` = minimal width |
| `Fw.d` / `F0.d` | fixed real | |
| `ESw.d` | scientific | `ES12.4` |
| `ENw.d` | engineering | exponent mult. of 3 |
| `Gw.d` / `G0` | generalized | auto F/E choice |
| `Aw` / `A` / **`AT`** | character / **trimmed** (F2023) | `AT` drops trailing blanks |
| `Lw` | logical | |
| `Zw` `Ow` `Bw` | hex/oct/bin | |
| `DT'...'(...)` | user-defined derived-type | |

### F2023 leading-zero control
| Descriptor | Effect |
|---|---|
| `LZS` | suppress leading zeros |
| `LZP` | print leading zeros |
| `LZ` | (controls leading-zero default for subsequent numeric output) |

## Worked Example
```fortran
real    :: x = 0.012345
character(*), parameter :: name = 'value   '   ! trailing blanks
write(*, '(a, 1x, es12.4)')      'x =', x       ! x =   1.2345E-02
write(*, '(at, 1x, f0.3)')        name, x       ! F2023: trims 'value', then number
write(*, '(*(i0,:,","))')         [1,22,333]    ! 1,22,333  (unlimited repeat + colon)
write(*, '(lzs, f8.4)')           0.5           ! F2023: ' .5000' (leading zero suppressed)
```
- **Demonstrates**: `ES`, the `AT` auto-trim (F2023), unlimited-repeat `*` with colon separator, and `LZS` leading-zero suppression (F2023).

## Anti-patterns
- **Fixed-width descriptors for unknown magnitudes**: `I5` overflows to `*****` when the value needs 6 digits — use `I0`.
- **Padding strings manually then writing with `A`**: use `AT` (F2023) to auto-trim instead of `trim()` gymnastics.
- **Assuming `.5` vs `0.5` output**: leading-zero rendering is now controllable (`LZS`/`LZP`) — set it explicitly when format matters.
- **Mismatched decimal symbol**: data written with `DC` (comma) and read with `DP` (point) corrupts values — keep them consistent.

## Key Takeaways
1. **F2023 `AT`** = `A` with automatic trailing-blank trimming — cleaner variable-width text output.
2. **F2023 `LZS`/`LZP`/`LZ`** give explicit leading-zero control for numeric fields.
3. `I0`/`F0.d`/`G0` (zero-width) avoid overflow asterisks and manual width math.
4. `ES`/`EN` for scientific/engineering; rounding descriptors (`RU`…`RC`) align text with IEEE rounding.
5. Unlimited-repeat `'(*(...))'` + colon `:` cleanly prints lists of unknown length.

## Connects To
- **Ch 12**: I/O statements — formats are consumed by formatted READ/WRITE.
- **Ch 17**: IEEE — rounding descriptors mirror IEEE rounding modes.
- **Ch 15**: Procedures — `DT` editing dispatches to user-defined I/O bindings.
