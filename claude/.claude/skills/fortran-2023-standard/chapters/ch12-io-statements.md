# Chapter 12 (Clause 12): Input/output statements

## Core Idea
The I/O model: records, files (external/internal), unit↔file connection (OPEN/CLOSE), and the data-transfer statements (READ/WRITE/PRINT) with their full specifier sets, including asynchronous I/O and WAIT.

## Frameworks Introduced
- **Record kinds** (12.2): formatted, unformatted, endfile.
- **Access methods** (12.3.3): **sequential**, **direct** (fixed-length records, `REC=`), **stream** (byte-addressable, `POS=`, F2003+).
- **File connection** (12.5): OPEN binds a *unit* (integer or `NEWUNIT=` value) to a file; CLOSE severs it. Preconnected units exist at program start (typically input/output/error via `ISO_FORTRAN_ENV`).
- **Data-transfer forms** (12.6): READ/WRITE/PRINT with a *control information list* (`UNIT=`, `FMT=`, `IOSTAT=`, `IOMSG=`, `ERR=`, `END=`, `EOR=`, `ADVANCE=`, `ASYNCHRONOUS=`, `ID=`, `POS=`, `REC=`, `SIZE=`, `DECIMAL=`, `ROUND=`, `SIGN=`, …) and an output/input list.
- **List-directed** (`FMT=*`), **namelist** (`NML=`), **formatted** (FMT=label/string), **unformatted** (no FMT), and **user-defined derived-type I/O** (DT edit + `read(formatted)`/`write(formatted)` bindings).

## Key Concepts
- **`NEWUNIT=`** (F2008): processor allocates a free, negative unit number — never hardcode unit numbers.
- **`IOSTAT=` / `IOMSG=`**: nonzero IOSTAT on error/EOR/EOF; `IS_IOSTAT_END`/`IS_IOSTAT_EOR` test them. Without ERR=/END=/IOSTAT=, an error stops the program.
- **Asynchronous I/O**: `ASYNCHRONOUS='YES'` + `ID=`, completed/queried by **WAIT**.
- **Internal files**: a character variable used as a "file" for in-memory formatted I/O (parsing/formatting strings).
- **Stream access**: byte stream, `ACCESS='STREAM'`, `POS=` to seek — closest to C `fread`/`fwrite`.
- **OPEN re-OPEN rules**: re-OPENing a connected unit may only change changeable modes; `STATUS=` if present must be `OLD`.

## Reference Tables
### OPEN specifiers (selected)
| Specifier | Values / role |
|---|---|
| `UNIT=` / `NEWUNIT=` | unit number / auto-allocated |
| `FILE=` | path |
| `STATUS=` | OLD / NEW / REPLACE / SCRATCH / UNKNOWN |
| `ACCESS=` | SEQUENTIAL / DIRECT / STREAM |
| `FORM=` | FORMATTED / UNFORMATTED |
| `ACTION=` | READ / WRITE / READWRITE |
| `POSITION=` | ASIS / REWIND / APPEND |
| `RECL=` | record length (direct/sequential) |
| `ASYNCHRONOUS=` | YES / NO |
| `ENCODING=` | UTF-8 / DEFAULT |

## Worked Example
```fortran
integer :: u, ios
character(256) :: msg
open(newunit=u, file='data.bin', access='stream', form='unformatted', &
     action='read', status='old', iostat=ios, iomsg=msg)
if (ios /= 0) error stop trim(msg)
read(u, pos=1) header           ! seek to byte 1, stream read
close(u)

! internal file: format a number into a string
character(20) :: s
write(s, '(i0)') 42             ! s = "42"
```
- **Demonstrates**: `NEWUNIT=`, stream access with `POS=`, `IOSTAT=`/`IOMSG=` error handling, and an internal-file write.

## Anti-patterns
- **Hardcoding unit numbers** (e.g. `open(10, ...)`): collides with other code; use `NEWUNIT=`.
- **Ignoring IOSTAT on I/O that can fail**: an unhandled error terminates the program — pass `IOSTAT=` and test it.
- **Assuming SYSTEM_CLOCK kinds are free**: unrelated to I/O but a common F2023 trap — integer args must now share kind (ch04).
- **Comparing IOSTAT to a literal for EOF**: use `IS_IOSTAT_END(ios)` — the EOF value is processor-dependent (but must differ from EOR; ch04 F2008 delta).

## Key Takeaways
1. Always use `NEWUNIT=` for unit allocation; never hardcode.
2. Three access methods: sequential, direct (`REC=`), stream (`POS=`); stream is the C-like byte interface.
3. Handle errors with `IOSTAT=`/`IOMSG=` + `IS_IOSTAT_END`/`IS_IOSTAT_EOR`; otherwise errors abort.
4. Asynchronous I/O needs `ASYNCHRONOUS='YES'`, `ID=`, and a matching `WAIT`.
5. Internal files (character variables) are the idiom for in-memory format/parse.

## Connects To
- **Ch 13**: I/O editing — the format/edit descriptors used by formatted transfers.
- **Ch 16**: Intrinsics — `ISO_FORTRAN_ENV` unit constants, `IS_IOSTAT_*`.
- **Ch 15**: Procedures — user-defined derived-type I/O bindings.
