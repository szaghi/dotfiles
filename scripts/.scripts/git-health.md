# git-health — report-only git repository integrity scanning

Detects git repositories damaged by an unclean shutdown, and reports them.
It never repairs anything.

- [Why this exists](#why-this-exists)
- [The corruption signature](#the-corruption-signature)
- [Why a git hook cannot do this](#why-a-git-hook-cannot-do-this)
- [Components](#components)
- [Manual use](#manual-use)
- [Automatic use](#automatic-use)
- [What the scanner checks](#what-the-scanner-checks)
- [Recovery playbook](#recovery-playbook)
- [Configuration](#configuration)
- [Limits](#limits)
- [Installation](#installation)

---

## Why this exists

On 2026-07-31 `~/fortran/adam` failed every git command with:

```
fatal: bad object HEAD
```

`refs/heads/develop` held `bad0995496e044b20cd0f0a310488ff8b0840d7f` — an
object present in no pack and in no reflog entry. Alongside it, 13 loose object
files were **zero bytes on disk** and the reflog tail was padded with NUL bytes.
`git fsck` reported 45 problems.

Nothing had gone wrong with git. The filesystem lost unflushed writeback while
git was mid-write: the metadata (filename, inode, size entry) was committed, the
data blocks never were. Two artefacts timestamped at the moment of the loss — a
leftover `tmp_pack_*` and a zero-length `FETCH_HEAD` — showed a fetch or gc had
been interrupted. On WSL2 the usual cause is an abrupt `wsl --shutdown` or a
host reset.

The repository was fully recoverable, but only because the damage was diagnosed
before anything was deleted. **Four of the thirteen "orphaned" empty objects
turned out to be blobs that were staged but not yet committed** — their
working-tree files were the only surviving copies. A cleanup that had simply
removed the corrupt objects would have destroyed real work.

That is the whole design rationale for this tool: detect early, report
precisely, and let a human decide.

## The corruption signature

An unflushed-writeback loss leaves a recognisable pattern:

| Symptom | Why it happens |
|---|---|
| Zero-length files under `.git/objects/??/` | Metadata survived, data blocks did not |
| A ref naming an object that exists nowhere | The ref file itself was written with garbage |
| NUL-padded tail in `.git/logs/HEAD` | Partial record write |
| Leftover `.git/objects/pack/tmp_pack_*` | A fetch or gc died mid-write |
| Empty `FETCH_HEAD` | Same |

The zero-length objects are the dangerous ones. They are **worse than missing
files**: git sees a filename in the object directory, concludes the object is
present, tries to read it, and aborts. They poison every read and write path
that touches them — including `git fetch`, which is how you would otherwise
repair the repository.

## Why a git hook cannot do this

Git hooks fire on git events (commit, push, checkout, merge). A crash runs no
hooks — and this corruption happens *during* a git write, so any hook would have
been killed alongside the operation that triggered it. There is no `post-crash`
hook, and by the time you next run a git command the damage is already done.

The trigger has to be **boot**, not a git event. That is a systemd concern.

## Components

| File | Deployed to | Role |
|---|---|---|
| `scripts/.scripts/git-health` | `~/.scripts/git-health` | The scanner. Report-only. Usable by hand. |
| `scripts/.scripts/git-health-boot` | `~/.scripts/git-health-boot` | Dirty-boot gate — runs the scanner only after an unclean shutdown |
| `scripts/.config/systemd/user/git-health-boot.service` | `~/.config/systemd/user/` | systemd **user** unit; arms a marker at start, disarms it at clean stop |

## Manual use

```bash
git-health                    # every repo under $HOME (slow — 235 repos here)
git-health -d 7               # only repos touched in the last 7 days (fast)
git-health -r ~/fortran       # limit to one tree
git-health -r ~/fortran/adam  # a single repo (and its submodules)
git-health --deep             # additionally run `git fsck` — slower, rarely needed
git-health -q                 # print only problems and the summary
```

Exit status is scriptable:

- **0** — every scanned repo is healthy
- **1** — at least one repo is suspect
- **2** — usage error, or git not found

Healthy output:

```
git-health: scanning under /home/stefano/fortran/adam

git-health: OK -- 13 repo(s) healthy, 0 skipped.
```

Suspect output names each repo and each specific defect, then prints the
recovery commands (reproduced in [Recovery playbook](#recovery-playbook)).

Approximate cost on this workstation: a single repo with submodules ~12 s,
`-d 14` across `$HOME` ~8 s, a full sweep of all 235 repos several minutes.

## Automatic use

`git-health-boot` runs from a systemd user unit at session start and decides
whether a scan is warranted:

- **Previous shutdown was clean** → arm the marker, exit silently. No scan.
- **Previous shutdown was unclean** → scan repos active in the last 14 days,
  report to the journal, change nothing.

How the dirty-boot detection works: the marker lives in `$XDG_RUNTIME_DIR`
(`/run/user/$UID`), which is tmpfs and therefore wiped on every boot.
`ExecStart` creates it; `ExecStop` removes it during an orderly shutdown. A
marker that is *already present* at `ExecStart` means the previous session never
reached its stop job — it died.

Read the results:

```bash
journalctl --user -u git-health-boot -b        # this boot
journalctl --user -u git-health-boot -b -1     # previous boot
```

Nothing is displayed interactively. **The habit worth forming: after any WSL
crash or abrupt shutdown, check that journal.**

The unit is sandboxed so that report-only is enforced structurally rather than
by good intentions:

```ini
ProtectSystem=strict      # no writes outside the allowed paths
ProtectHome=read-only     # the scan CANNOT modify a repository
ReadWritePaths=%t         # only the runtime dir, for the marker
NoNewPrivileges=yes
Nice=19                   # never compete with interactive work
IOSchedulingClass=idle
SuccessExitStatus=0 1     # exit 1 = "suspect found", a report, not a failure
```

## What the scanner checks

Five checks per repository, all read-only:

1. **Zero-length loose objects** — the primary writeback-loss signature.
2. **HEAD resolves** to an object that actually exists. An unborn branch in a
   freshly initialised repo is not flagged.
3. **No ref points at a missing object** — `for-each-ref` reports these on
   stderr while still exiting 0, so the text is inspected rather than the status.
4. **Graph walk** (`rev-list --objects --all`) — catches refs and commits
   pointing at objects that are gone.
5. **Full decompression** (`cat-file --batch-all-objects --batch`) — inflates
   every object payload.

Check 5 is the load-bearing one, and the reason deserves stating. Check 1 is
**vacuous on a fully packed repository** — 71 of the 235 repos here have zero
loose objects, so there is no file whose size could be wrong. And check 4 reads
only object *headers*: a repository whose pack is genuinely shredded (checksum
mismatch, CRC mismatch, inflate errors, content unreadable) still exits 0 from
`rev-list`. This was verified against a deliberately corrupted pack — `rev-list`
said 0, `fsck` said 128. Only a full `cat-file --batch` inflates payloads and
actually fails.

A sixth check reports a leftover `tmp_pack_*`, but only when no git process is
currently running (otherwise it is simply a fetch in flight).

Repositories are skipped, not scanned, when they have no `HEAD` and no `config`
— a bare `info/` directory is a stray `git init`, not a repository. `~/.git` here
is exactly that.

## Recovery playbook

When the scanner reports SUSPECT, it stops and hands over. Work in this order —
it is the order the 2026-07-31 repair actually required.

**1. Get the full picture. Touch nothing yet.**

```bash
git -C <repo> fsck --no-dangling        # complete error list
git -C <repo> status                    # may itself fail — that is a data point
```

**2. Find out whether real history survived.** This decides everything else:

```bash
git -C <repo> rev-list --objects HEAD >/dev/null && echo "history INTACT"
```

Exit 0 means the damage is orphaned debris and recovery is straightforward. If
it fails, the history itself is holed and a fresh clone may be the honest answer.

**3. Check whether staged work is among the casualties.** The step that is easy
to skip, and the one that nearly cost four golden files:

```bash
git -C <repo> ls-files --stage          # staged blob SHAs
git -C <repo> hash-object <file>        # hash the working-tree copy
```

If a zero-length object's SHA appears in the index, the working-tree file is the
**only surviving copy**. When `hash-object` matches the staged SHA, the file is
byte-identical to what was staged and can be restored exactly.

**4. Restore, in this order:**

```bash
# a) quarantine the empty objects -- MOVE, never rm
mkdir -p /tmp/gh-quarantine
mv .git/objects/XX/YYYY... /tmp/gh-quarantine/

# b) rewrite lost blobs that were staged
git hash-object -w <file>

# c) fix a ref pointing at a dead object; the reflog names the last good commit
tail -5 .git/logs/HEAD
git update-ref refs/heads/<branch> <last-good-sha>

# d) refetch to backfill from the remote
git fetch origin --prune

# e) confirm
git fsck --no-dangling && git status
```

Two traps, both encountered live:

- **`git add` can report success and write nothing.** Unchanged stat metadata
  makes git skip the write, so the blob never lands in the object database and
  the repository fails again later. Force it with `git hash-object -w`, then
  verify with `git cat-file -s <sha>`.
- **Never `rm` a suspect object.** Move it aside. Some of them are your staged
  work.

## Configuration

The boot scan's window is set in the unit:

```ini
Environment=GIT_HEALTH_BOOT_DAYS=14
```

After editing, run `systemctl --user daemon-reload`.

Environment overrides honoured by the scripts:

| Variable | Default | Meaning |
|---|---|---|
| `GIT_HEALTH_ROOT` | `$HOME` | Directory to search |
| `GIT_HEALTH_DAYS` | *(all)* | Restrict to repos active in the last N days |
| `GIT_HEALTH_MAXDEPTH` | `6` | How deep to search for `.git` directories |
| `GIT_HEALTH_BOOT_DAYS` | `14` | Window used by the boot-triggered scan |
| `GIT_HEALTH_MARKER` | `$XDG_RUNTIME_DIR/git-health.boot-marker` | Dirty-boot marker |
| `GIT_HEALTH_BIN` | `~/.scripts/git-health` | Scanner used by `git-health-boot` |

The 14-day default exists because a full scan of every repository costs minutes
of saturated disk I/O, and reboots vastly outnumber crashes. Corruption from a
crash lands in whatever was mid-write, which is by definition recently active —
so the recency filter is both far cheaper and nearly as effective.

## Limits

Stated plainly, so the tool is trusted for what it does and not for what it
does not:

- **It detects; it never repairs.** By design. Repair required judgement at four
  separate points during the 2026-07-31 incident.
- **It only runs after a *detected* dirty boot.** If the session dies in a way
  that still executes the stop job, the marker is cleared and the next start is
  silent.
- **The 14-day window can miss a repository** that was corrupted but has not been
  touched since. After a serious crash, run a full `git-health` by hand.
- **It cannot catch a crash mid-session** — only at the next session start.
- **`Linger=no`**, so the user manager starts at first login rather than at boot
  proper. Under WSL that is when you open a shell, so in practice the check runs
  every session.
- **`GIT_HEALTH_MAXDEPTH=6`** — a repository nested deeper than six levels below
  `$HOME` is invisible to the scan.

## Installation

Deployed by stow with the rest of the `scripts` package:

```bash
bash ~/dotfiles/dotify.sh scripts
```

Then enable the boot check once:

```bash
systemctl --user daemon-reload
systemctl --user enable --now git-health-boot.service
systemctl --user status git-health-boot.service
```

To disable it while keeping the scripts usable by hand:

```bash
systemctl --user disable --now git-health-boot.service
```

Requires systemd (`/etc/wsl.conf` must set `systemd=true` under WSL) and git.
