# Compiler-bug tracker

One issue per repository, titled `Compiler bugs: reproducers and workarounds`, labelled `compiler-bug`
if the label exists. Search before opening: `gh issue list --search "Compiler bugs in:title" --state all`.
The body is the index; each bug is one comment, so adding a bug never rewrites the body.

## Body

```markdown
Compiler bugs met in this repository, each with a minimal reproducer and the workaround in the code,
ready to file with the vendor. One comment per bug; this table is the index.

| Bug | Compiler | Status | Workaround in | Vendor ticket |
|---|---|---|---|---|
| [B1](<comment URL>) | nvfortran 26.9 | open | `src/lib/foo.F90:120` | not filed |
```

Status: `open` (present in the current toolchain), `fixed in <version>` (workaround removable),
`not a bug` (our code was non-conforming: say which rule, from the `fortran-2023-standard` skill).

## One comment per bug

````markdown
### B<n>: <one-line symptom> (<compiler> <version>)

**Toolchain.** <compiler, exact version, flags>; <MPI, CUDA if relevant>; <OS>.
**Other compilers.** <gfortran 16.2.0: correct / also fails>, with the same flags.
**Standard.** <why the code conforms: the rule (Rxxx/Cxxx or clause) from the fortran-2023-standard skill>.

**Reproducer** (self-contained, no dependency on this repository):

```fortran
<the smallest program that shows it>
```

```console
$ <compile and run commands>
<actual output>
```

**Expected.** <what the standard requires, and what the other compiler prints>.

**Workaround.** <what the code does instead>, at `<path:line>` (commit <sha>). Remove it when the
bug is fixed: <what to check>.

**Vendor ticket.** <not filed | URL>.
````

Then add the row to the body's index (`plan-issue` is the plan-issue skill's script): `plan-issue body REF > <scratchpad>/body.md`, add the row with the
Edit tool (a fixed-string change, the rest byte-identical), `gh issue edit N --body-file <scratchpad>/body.md`.
Not `plan-issue edit`: this body has no plan skeleton and its lint would refuse it.
