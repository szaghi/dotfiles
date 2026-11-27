---
title: Subscription accounts
---

# Subscription accounts

The extra subscription accounts (`claude-iac`, `claude-cfd-cnr`, `claude-cfd-iac`, `claude-soma`) run the
same setup as the personal one, each logged in separately. This page covers logging in, what the accounts
share, and the 2026-10-14 rename.

## Log in and use

Each extra account runs Claude Code with `CLAUDE_CONFIG_DIR` set to its own directory. Login state never
collides with `~/.claude`, while everything account-agnostic is shared through symlinks (see [What is shared](#what-is-shared)).

```bash
claude-cfd-iac login            # first use: authenticate this config dir
claude-cfd-iac login --no-sso   # same, for a plain subscription without SSO
claude-cfd-iac status           # which account the config dir is logged into
claude-cfd-iac logout
claude-cfd-iac                  # a session on that account
claude-cfd-iac --resume         # any other argument goes to claude
```

The same subcommands exist for `claude-iac`, `claude-cfd-cnr` and `claude-soma`. All four go through
`_claude_account`:

| Argument | Runs |
|---|---|
| `login [--no-sso] [args]` | `claude auth login --email <EMAIL> --sso`, with `--email` only when the account's email variable is set |
| `status [args]` | `claude auth status --text` |
| `logout [args]` | `claude auth logout` |
| anything else | `claude "$@"` |

Before any of these, `_claude_account_bootstrap` creates the directory and links `CLAUDE.md`,
`CLAUDE-fortran.md`, `CLAUDE-gpu.md`, `RTK.md`, `commands`, `skills`, `agents`, `hooks`, `plugins`,
`projects`, `settings.json`, `settings.local.json` and `statusline-command.sh` from `~/.claude`. An item
already present there as a real file or directory is reported and left alone: merge it by hand, remove it,
re-run. An item absent from `~/.claude` is skipped.

::: warning Log in from a clean browser
The OAuth page reuses the Claude session your browser already holds, so a plain login binds the personal
account. `login` pre-fills the email and forces SSO, and prints a reminder: open the URL in an incognito window
or a browser profile not signed into the personal claude.ai.

`--email` only pre-fills: a browser signed into a *sibling* seat (e.g. the `cnr.it` one while logging in
`claude-cfd-iac`) authorises that seat anyway. So when the account's email variable is set,
`_claude_account_check` compares it with `oauthAccount.emailAddress` in the dir's `.claude.json` after `login`
and before every session. On a mismatch, or when the dir has no login yet, it refuses to start. Hosts that
leave the email variable empty skip the check.
:::

Set the four email variables in `~/.bash/claude_code.local` (it is per host and lives in the host's
`bash-<host>` package):

```bash
CLAUDE_IAC_EMAIL="..."
CLAUDE_CFD_CNR_EMAIL="..."
CLAUDE_CFD_IAC_EMAIL="..."
CLAUDE_SOMA_EMAIL="..."
```

## What is shared

Each account runs with its own `CLAUDE_CONFIG_DIR` (`~/.claude-iac`, `~/.claude-cfd-cnr`,
`~/.claude-cfd-iac`, `~/.claude-soma`). On every call the wrapper links the shareable parts of `~/.claude`
into that directory:

| Shared (symlink to `~/.claude`) | Per account |
|---|---|
| `CLAUDE.md`, `CLAUDE-fortran.md`, `CLAUDE-gpu.md`, `RTK.md` | `.credentials.json` |
| `commands`, `skills`, `agents`, `hooks`, `plugins` | `.claude.json` (OAuth identity) |
| `settings.json`, `settings.local.json`, `statusline-command.sh` | `history.jsonl` and the client's other state |
| `projects` (auto-memory and transcripts) | |

Because `projects/` is shared, `claude-cfd-cnr --resume` resumes a session started with plain `claude`.

## Renamed accounts

On 2026-10-14 `claude-cnr` became `claude-cfd-cnr` and `claude-cnr-iac` became `claude-cfd-iac`.

- The old names are kept as functions that print the new name and return 1. They are never aliases, so they
  cannot start a session on another account.
- The first run of a new name moves the old directory (`~/.claude-cnr`, `~/.claude-cnr-iac`) to the new path
  and leaves a symlink at the old one, so sessions started before the rename keep writing to the same files.
- If both the old and the new directory exist as real directories, the wrapper refuses: keep the logged-in one,
  remove the other, re-run.
- `~/.claude-science` belongs to another tool and is not an account directory.
