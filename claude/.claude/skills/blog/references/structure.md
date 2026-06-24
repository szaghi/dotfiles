# Post structure — technical dev write-ups

A dev post is not a manuscript and not a tutorial-mill SEO article. It is a
focused explanation of one thing you did or learned, with code that works.

## Skeleton

1. **Hook (1 para).** The concrete problem or change. State it plainly. A
   reader skimming should know in two sentences whether this post is for them.
2. **Context (1–2 sections).** What the situation was, why the obvious approach
   was insufficient. Show the relevant existing code.
3. **The work (1–2 sections).** What you did. Code blocks copied from the repo,
   each followed by prose that explains the *non-obvious* part — the trade-off,
   the constraint, the gotcha. Skip narration of what the code obviously does.
4. **Result (1 para to 1 section).** What it buys. A measurement if you have one
   (and if you show a benchmark, state the conditions — see your GPU/timing
   discipline). End when the point lands.

## Length

Most good dev posts are 600–1500 words. If it's longer, it's probably two
posts. If it's shorter than 400, it's probably a code comment or a README note,
not a post.

## What to leave out

- No "table of contents" for a 900-word post.
- No keyword-stuffed headings. Headings describe the section, not target a SERP.
- No "in this article we will explore" preamble. Start with the substance.
- No hollow conclusion that restates the post. Stop when done.

## Code blocks

- Always copied from the real repo, never reconstructed from memory.
- Show the minimum that makes the point; mark elisions with `! ...` (Fortran)
  or `# ...` (Python/shell) and say in prose what was cut.
- Label the language fence correctly (` ```fortran `, ` ```python `, ` ```bash `).
- A command shown must be the modern form (e.g. FoBiS `--mode`, not `-mode`).
