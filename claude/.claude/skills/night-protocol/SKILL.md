---
name: night-protocol
description: Unattended-work protocol for when the owner is away for hours. Claude works through a plan step by step without waiting for review and never stages, commits, pushes or posts. Each green step is snapshot as a git tree with a patch, a file list and a commit message, and the owner commits the chain in the morning with one command. Use when the user says "night protocol", "night-protocol mode", "/night-protocol", "I'll be away/offline for N hours", "don't wait for my review, log everything for tomorrow", or "drive me to commit the night work".
---

# Night protocol

The owner is unavailable. Keep working through the plan; the owner keeps commit authority (GPG, review).
`NIGHT=~/.claude/skills/night-protocol/scripts/night` does the git work. Never improvise snapshots by hand.

## Hard rules (no exceptions, whatever else the session allows)

1. **Never** `git add`, `commit`, `stash`, `reset`, `checkout --`, `push`, nor touch the real index or branches.
2. **Never** open, comment on, close or label issues/PRs, or send anything outward. Draft such text as
   `.night/current/<topic>.comment.md`.
3. **Never stop.** Before ending any turn there must be a pending wake source: a background job/Monitor you
   started, or a scheduled wakeup. "I'll wait for the job" with nothing armed is a stop; so is a summary
   that asks a question.
4. **Rate limit** (`resets HH:MM`): in the same turn, schedule a one-shot wakeup a few minutes after the reset
   (CronCreate, or ScheduleWakeup in /loop), then resume every stopped agent and carry on.
5. Never overwrite baselines/goldens in place: new results get new names.

## Start

1. `$NIGHT init [topic]` at the repo root; read its warning about pre-existing changes.
2. Load the project's own constraints: repo `CLAUDE.md`, and project memories mentioning *night*
   (e.g. ADAM: medooza queues and job limits). They add to the rules above; they never relax them.
3. Write the plan in `LOG.md` → *Plan*: ordered steps, each with its gate (the exact commands that make it green).

## Per step (repeat until the plan ends)

1. Implement. Run the full gate. Not green → fix and re-gate; never snapshot red.
2. Write `.night/current/NN-slug.msg`: Conventional Commits, no AI trailer, body with the gate evidence
   (commands, counts, job ids). Add project-required content (e.g. ADAM's directive list).
3. `$NIGHT snap NN-slug [paths...]`. Read the printed file list: build products or scratch files in it
   mean pass explicit paths (or fix `.gitignore` in a step of its own). A bug found later in the *last*
   step: fix, re-gate, `$NIGHT snap --redo NN-slug`. In an earlier step: a new fix step, never a rewrite.
4. Append to `LOG.md` → *Chronology*: time from `date`, step, gate result, decisions, problems, job ids.

## Decisions while the owner is away

- **Reversible, inside the agreed plan** → take the recommended option, log it under *taken on the owner's behalf*.
- **Irreversible, outward-facing, or changing frozen behaviour/goldens/APIs** → do not do it. Log it under
  *left to the owner* with the evidence and options, then continue with the next independent step.
- Blocked step with nothing independent left → finish the evidence write-up, run `$NIGHT verify`, then end the night.

## End of night

`$NIGHT verify` must print `ok` for every step. Add a *Morning brief* at the top of `LOG.md`: steps done
(one line each), decisions left to the owner, what remains, anything flaky.

## Morning ("drive me to commit the night work")

1. `$NIGHT status` and `$NIGHT verify`; summarise the *Morning brief*.
2. Tell the owner to run in **their own terminal** (it refuses without a TTY; Claude never runs it):
   `night commit` (on the owner's PATH via `~/.scripts/night`; preview: `--dry-run`).
   It commits each step tree in order, hooks and signing included, without touching the working tree,
   and resumes after a partial run.
3. Then post the drafted comments if the owner asks, and drop night-only memories.
4. Tell the owner to run `night clean` (owner only, TTY). It deletes the night directory once
   `night status` reports `committed: yes` and no `*.comment.md` draft is left; `--all` covers older
   nights, `--force` skips both checks. Claude can preview it with `$NIGHT clean --dry-run`.

Design, file layout and past failure modes: [REFERENCE.md](REFERENCE.md).
