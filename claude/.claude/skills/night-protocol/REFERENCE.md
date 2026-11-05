# Night protocol: design notes

## Files (`<repo>/.night/<date>[-topic]/`, `.night/current` → the active one)

| File | Written by | Content |
|---|---|---|
| `base` | `init` | HEAD commit when the night started |
| `preexisting` | `init` | `blob-id<TAB>path` of each change already in the working tree (`-` = deleted) |
| `chain` | `snap` | one line per step: `NN-slug prev-tree step-tree` |
| `NN-slug.msg` | Claude | commit message (must exist before `snap`) |
| `NN-slug.tree` | `snap` | the step's tree object id |
| `NN-slug.patch` | `snap` | `git diff --binary prev step`: for review |
| `NN-slug.files` | `snap` | `--name-status` of that diff |
| `LOG.md` | `init`, Claude | morning brief, plan, decisions, chronology |
| `*.comment.md` | Claude | drafted issue/PR text, not yet posted |
| `*.comment.posted.md` | Claude | the same draft once the owner had it posted |
| `gate-<label>.log` | `gate` | output of the last gate on that step (or `candidate`) |
| `wt-<label>/` | `gate` | scratch worktree, removed when the gate ends |

`/.night/` goes into `.git/info/exclude` (local only, never committed). `git add -A` then skips it, so
the night directory never ends up inside a snapshot.

## Why trees and `read-tree`, not patches and `git apply`

A snapshot is a tree object built on a scratch index (`GIT_INDEX_FILE=<tmp> git read-tree <prev>;
git add -A; git write-tree`), so the real index, HEAD and branches never move while the owner is away.

The morning commit runs `git read-tree <step tree>` followed by `git commit -F <msg>` for each step.
The commit holds exactly the snapshot tree. Commit hooks still run, the working tree is never
touched, and there is no stash to drop. The patches are only for review and for `verify`, which
replays them on a scratch index from the base and checks that each one reproduces its tree.

`commit` refuses when HEAD is neither the base nor one of the step trees: the step trees would then
revert whatever was committed since. In that case rebase by hand, `git apply --3way` the patches in order.

## Owner's git config must not leak in

The patch chain is replayed byte for byte, so the script pins what the owner's config would change:
`git apply --whitespace=nowarn` (the owner has `apply.whitespace=fix`, which rewrote trailing spaces and
blank lines at EOF, so `verify` and therefore `commit` failed on a correct chain: FoBiS 10-30, FoXy
11-03, figure 11-04), and `diff.noprefix=false`, `--no-ext-diff`, `--no-textconv` for the patches.

## Pre-existing changes

`init` records every path that already differs from HEAD, with its blob id. `snap` without paths
excludes each one (`:(exclude,literal)` pathspecs) while its content is still the recorded one, and
includes it with a note once a step has edited it. This keeps a `HANDOFF-*.md` or the owner's own
uncommitted edits out of step 01 without the agent having to remember explicit paths. `verify` still
lists them under "changes outside every step", which is accurate.

## Gating the snapshot: `night gate`

A gate run on the working tree can pass while the snapshot misses a file (explicit paths) or holds
one the working tree has since changed. `night gate [NN-slug] -- cmd` checks the tree out in
`.night/<night>/wt-<label>` (`git worktree add --detach <base>` then `read-tree -u --reset <tree>`),
runs `cmd` there, and removes the worktree on exit. It writes only worktree metadata under `.git/`:
no index, HEAD or branch of the main worktree moves. Ignored inputs are absent from the checkout, so
the command reaches them through `$NIGHT_REPO` (symlink the venv, `node_modules`, fetched deps). Before
it existed, nights wrote their own `gate.sh` (9 copies in StringiFor, one per night in shore and VecFor).
The cost is a clean build per gate, so use it for the step's real gate, not for edit-compile loops.

## Cleaning up: `night clean`

The night directory outlives the commits on purpose, because it holds the drafted comments and the
decisions left to the owner. `clean` deletes it only when both of these hold:

- **committed:** the last step's tree is the tree of some commit in `base..HEAD`. An exact tree
  match means a squash of the whole chain counts. A last step amended in the morning does not, and
  neither does a rebase onto a moved upstream: use `--force` then.
- **no draft to post:** no `*.comment.md` is left. Posted drafts are renamed `*.comment.posted.md`
  and do not block; nights from before that convention need the posted ones renamed, or `--force`.

It also removes `.night/current` when that link points at the deleted night. When `.night/` ends up
empty it removes the directory and the `/.night/` line in `.git/info/exclude`. It never touches the
working tree, the index or any ref. Like `commit`, it needs a TTY unless run with `--dry-run`.

## PATH

`scripts/.scripts/night` in the dotfiles is a relative symlink to this script, so stow puts `night`
on the owner's PATH. SKILL.md keeps using the absolute `$NIGHT` path for Claude, because the agent's
shell does not necessarily have `~/.scripts` on its PATH (see `claude-remote` in the repo CLAUDE.md).

## Failure modes this design closes (from the 2026-10 nights)

| Date, repo | What happened | Rule / mechanism now |
|---|---|---|
| 10-29 adam | Claude ended its turn mid-night while waiting for jobs; the owner woke up to nothing done | Hard rule 3: no turn ends without a wake source |
| 10-29 adam | The morning `git apply --index p3.patch` failed with "does not match index": the working tree already held the changes | `commit` uses `read-tree` and never applies patches to the real tree |
| 10-29 llm-wiki | Agents stalled for hours on a rate limit, resumed 20 min to 2.5 h late | Hard rule 4: schedule the wakeup at the first stop notice |
| 10-27 adam | Times in the log were estimated, off by up to an hour | Times come from `date` |
| 10-28 shore | The 0028 investigation could not reach its goal without changing frozen behaviour | Stop the step, log the evidence and the options for the owner, then move on |
| 10-27 llm-wiki | Tarball snapshots overwrite whole trees and silently revert edits made in the morning | Trees plus a verified patch chain; no tarballs |
| 10-30 FoBiS, 11-03 FoXy, 11-04 figure | `verify`/`commit` FAIL on a correct chain: `apply.whitespace=fix` rewrote the patch | `git apply --whitespace=nowarn`; diff config pinned |
| 10-31 adam | 3 h idle with a wake source armed: it fired on the last of 14 runs, 13 were done | Rule 3: event source on the first actionable result plus a ≤ 60 min timed fallback |
| 10-31 shore | Gates killed for memory; a harness notice said not to restart unless asked; the agent stopped | Rule 6: resume at lower parallelism |
| 11-01 adam | 14 h lost: a WSL reboot killed every in-session wake source | Rule 3: long jobs where they survive the session; `LOG.md` kept current |
| 11-03 adam | Hours of full suite gating a two-line change | Gates sized per step; full suite at the end of the night |
| 11-02 FOSSIL, 11-04 figure | Nights used in short day-time bursts interleaved with staging and commits; `commit` refused (staged index, HEAD moved) | Rule 7; `init` refuses a staged index; `snap` warns on HEAD or index moving |
| 11-04 FOSSIL, adam | `HANDOFF-*.md` in the root, warned about at every `init`, at risk of landing in step 01 | Pre-existing changes recorded and excluded |
| 10-30 → 11-05, all repos | Posted drafts left in place; up to 15 nights per repo cleaned by hand | `*.comment.posted.md`; `night clean` |

## Project overrides

Constraints that only apply to one repository go in that repository's `CLAUDE.md` or its project
memory, under a line naming the night protocol. For example, ADAM: build on the medooza login node,
one CPU job and one FNL job at a time, test only in the `/ifs` mirrors. They add rules; they cannot
lift the hard rules.
