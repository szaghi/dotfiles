---
title: The machines
---

# The machines

Three machines share this repository. What they have in common is in the common packages; what differs
is declared in two files per host under `machines/`, chosen by `hostname -s`.

## The hosts

| | adam | quark | astrobit |
|---|---|---|---|
| Hardware | workstation | Chuwi Minibook X N150 | GMKtec NucBox G5, Intel N97, 12 GB |
| OS | WSL2 (Ubuntu) on Windows 11 | CachyOS | CachyOS (since 2026-09-15, replacing Windows 11) |
| Desktop | none | sway + Noctalia | niri + Noctalia |
| Terminal | Windows Terminal | foot | foot |
| Role | HPC development: Fortran, GPU, MPI, the local LLMs | the laptop | telescope control: INDI, KStars, PHD2 |

## The two files per host

| File | Read by | Content |
|---|---|---|
| `machines/<host>` | `dotify.sh` | extra stow packages, one per line, applied after the common ones |
| `machines/<host>.skills` | `skills-apply` | third-party (class C) Claude Code skills to install on this host |

Both accept blank lines and `#` comments.

### Packages per host

| Host | `machines/<host>` | Packages |
|---|---|---|
| adam | `machines/adam` | `usr`, `bash-adam` |
| quark | `machines/quark` | `bash-quark`, `desktop` |
| astrobit | `machines/astrobit` | `bash-astrobit`, `desktop-astrobit` |

`bash-<host>` holds the per-host bash overrides and `.gitconfig.local` (signing key, local LLM
settings): see [Per-host packages](/packages/host-specific). astrobit stows `desktop-astrobit` and never
quark's `desktop`: niri, not sway.

### Skills per host

| Host | `machines/<host>.skills` |
|---|---|
| adam | `mattpocock-skills`, `book-to-skill`, `pdf-deps`, `latex-document-skill`, `stop-slop`, `remotion-best-practices` |
| quark | `book-to-skill`, `pdf-deps`, `latex-document-skill`, `stop-slop`, `remotion-best-practices` |
| astrobit | `stop-slop`: deliberately minimal, it drives the telescopes |

A host without a `.skills` file installs every entry of the manifest. Custom (class A) and plugin
(class B) skills are the same on every host: see [Skills](/claude/skills).

## Adding a machine

1. Pick the host name: `hostname -s` on the new machine is what `dotify.sh` will look for.
2. Create `machines/<host>` with its packages, and a `bash-<host>/` package if it needs overrides.
3. Create `machines/<host>.skills` if it should not get every third-party skill.
4. Commit, then follow [Fresh install](/guide/installation) on the machine.

## Things to know

- **No profile, no error.** A host with no `machines/<host>` gets the common packages only, silently.
- **Renaming a host changes its packages.** The profile is matched by name at every run of `dotify.sh`.
