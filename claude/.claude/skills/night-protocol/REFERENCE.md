# Night protocol: design notes

## Files (`<repo>/.night/<date>[-topic]/`, `.night/current` → the active one)

| File | Written by | Content |
|---|---|---|
| `base` | `init` | HEAD commit when the night started |
| `chain` | `snap` | one line per step: `NN-slug prev-tree step-tree` |
| `NN-slug.msg` | Claude | commit message (must exist before `snap`) |
| `NN-slug.tree` | `snap` | the step's tree object id |
| `NN-slug.patch` | `snap` | `git diff --binary prev step`: for review |
| `NN-slug.files` | `snap` | `--name-status` of that diff |
| `LOG.md` | `init`, Claude | morning brief, plan, decisions, chronology |
| `*.comment.md` | Claude | drafted issue/PR text, never posted |

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

## Failure modes this design closes (from the 2026-10 nights)

| Date, repo | What happened | Rule / mechanism now |
|---|---|---|
| 10-29 adam | Claude ended its turn mid-night while waiting for jobs; the owner woke up to nothing done | Hard rule 3: no turn ends without a wake source |
| 10-29 adam | The morning `git apply --index p3.patch` failed with "does not match index": the working tree already held the changes | `commit` uses `read-tree` and never applies patches to the real tree |
| 10-29 llm-wiki | Agents stalled for hours on a rate limit, resumed 20 min to 2.5 h late | Hard rule 4: schedule the wakeup at the first stop notice |
| 10-27 adam | Times in the log were estimated, off by up to an hour | Times come from `date` |
| 10-28 shore | The 0028 investigation could not reach its goal without changing frozen behaviour | Stop the step, log the evidence and the options for the owner, then move on |
| 10-27 llm-wiki | Tarball snapshots overwrite whole trees and silently revert edits made in the morning | Trees plus a verified patch chain; no tarballs |

## Project overrides

Constraints that only apply to one repository go in that repository's `CLAUDE.md` or its project
memory, under a line naming the night protocol. For example, ADAM: build on the medooza login node,
one CPU job and one FNL job at a time, test only in the `/ifs` mirrors. They add rules; they cannot
lift the hard rules.
