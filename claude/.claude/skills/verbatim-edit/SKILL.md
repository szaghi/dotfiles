---
name: verbatim-edit
description: Byte-exact edit protocol (TOML before/after plan, unique match, sd -F, build after). Use for numerical-kernel inner loops, generated code, licence/version/manifest sweeps, golden outputs, whitespace-significant files, or after an Edit failed to match.
---

# Verbatim-Edit Protocol

For changes where **exact bytes** matter — numerical kernels, generated code, license
headers, version strings, manifest files, compiler-pragma blocks, golden test outputs —
do not let me (the LLM) free-hand the edit through `Edit`. The cost of a paraphrased
whitespace, a reformatted continuation line, or a "helpful" comment removal can be a
silently broken kernel or a regenerated diff that no longer reviews cleanly.

### When to use it

Trigger this protocol when any of the following is true:

- The edit is to a numerical-kernel inner loop (vectorised, OpenACC `!$acc parallel loop`,
  OpenMP `!$omp parallel do`) — formatting/ordering matters for the compiler
- The block is auto-generated or under a "do not edit" header
- Whitespace, trailing newlines, or column alignment are load-bearing (Fortran fixed-form,
  POSIX shell heredocs, Makefile recipes)
- The change must be byte-identical across N files (header/license sweep)
- A previous Edit attempt produced "looks right but doesn't match" pattern-match failures

### How to apply

Write a TOML plan with `before`/`after` blocks copied **verbatim from the source** (use
`Read` or `git show`, never paraphrase), then apply via `sd -F` (fixed-string replace).

```toml
[task.kernel_intent_fix]
file = "src/kernels/exchange.F90"
type = "replace"
before = '''
SUBROUTINE compute_exchange(rho, n, e)
    REAL(R8P) :: rho(n)
    INTEGER   :: n
    REAL(R8P) :: e
'''
after = '''
SUBROUTINE compute_exchange(rho, n, e)
    REAL(R8P), INTENT(IN)  :: rho(n)
    INTEGER,   INTENT(IN)  :: n
    REAL(R8P), INTENT(OUT) :: e
'''
```

Apply with:

```bash
sd -F "$(cat before.txt)" "$(cat after.txt)" src/kernels/exchange.F90
```

Or one-shot via Python with base64-encoded blocks when the strings contain shell
metacharacters.

### Rules

1. **Verbatim source.** Copy `before` from the file via `Read`/`git show` — never type it
   from memory and never abbreviate with `...`.
2. **Unique match.** Include enough surrounding context that `before` appears exactly
   once in the file. Verify with `grep -cF "$before" file` before applying.
3. **Whitespace is content.** Tabs vs spaces, trailing whitespace, blank lines — all
   must match the source. `sd -F` is byte-exact, not regex-fuzzy.
4. **Pre-flight check.** Confirm `before` exists in the target file before invoking `sd`
   (it returns exit 0 even on zero matches — silent no-op is the failure mode).
5. **One file per change.** Multi-file sweeps are N separate changes, not one fuzzy one.
6. **Verify after.** Run the relevant compile step (`fobis build`, `gfortran -c -Wall`)
   immediately — a verbatim-edit protocol that doesn't end with a build check defeats
   the point.

### Why not just `Edit`?

`Edit` already does fixed-string replacement. The discipline this section adds is
*upstream of the tool*: writing the before/after into a reviewable TOML artefact forces
me to fetch the source verbatim instead of reconstructing it, makes the change auditable
without re-running the LLM, and makes the edit re-applicable to a sibling branch or a
regenerated file with zero ambiguity. For one-off tweaks `Edit` is fine; for kernel and
generated-code changes, the artefact is worth the overhead.
