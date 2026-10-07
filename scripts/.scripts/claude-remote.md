# claude-remote

Run a Claude Code session on one machine, walk away, and pick it up later from
another. The reference setup, used throughout this guide:

| Role | Machine | Tailscale name | Needs |
|---|---|---|---|
| **host** (Claude runs here) | adam — Ubuntu on WSL2, at home | `wsl-adam` | tmux, claude, Tailscale, dotfiles |
| **client** (you sit here) | quark — CachyOS laptop, at the office | `quark` | ssh, Tailscale, dotfiles |

```
   office                                              home (behind Vodafone CGNAT)
┌───────────┐   ssh -t over Tailscale (WireGuard)   ┌──────────────────────────────┐
│  quark    │ ────────────────────────────────────► │ adam / WSL "wsl-adam"        │
│ client:   │   no open port, no public IP needed   │  tmux server                 │
│ ssh only  │                                       │   └─ session "claude"        │
└───────────┘                                       │        └─ bash ─ claude      │
                                                    └──────────────────────────────┘
```

The Claude process lives in tmux on adam. Disconnecting (closing the laptop,
losing Wi-Fi, `Ctrl-b d`) only detaches the *view*; Claude keeps working.

---

## 1. One-time setup

### 1.1 Tailscale on both machines

Both nodes log in to the **same** Tailscale account; each `tailscale up` prints a
URL to open in a browser.

```bash
# adam (WSL, Ubuntu) — systemd must be on in /etc/wsl.conf ([boot] systemd=true)
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up --ssh --hostname=wsl-adam

# quark (CachyOS)
sudo pacman -S tailscale
sudo systemctl enable --now tailscaled
sudo tailscale up
```

`--ssh` makes Tailscale itself answer ssh on the tailnet address and authenticate
by tailnet identity, so no key has to be copied from quark to adam. With the
default policy the first connection may print a URL to re-confirm the login
("check mode"); open it and the session proceeds.

In the admin console (login.tailscale.com → Machines → `wsl-adam` → ⋯) choose
**Disable key expiry**, or the node silently drops off the tailnet after 180 days.

Check from quark:

```bash
tailscale status                 # wsl-adam listed; "direct" or "relay" both work
ssh stefano@wsl-adam true && echo ok
```

### 1.2 The script on both machines

`claude-remote` is part of the `scripts` stow package.

```bash
cd ~/dotfiles && git pull
bash dotify.sh scripts           # adam: ~/.scripts holds per-file links, new files need a re-stow
                                 # quark: ~/.scripts is a link to the whole dir, git pull is enough
```

tmux is needed **only on adam** (`sudo apt install tmux`). quark needs nothing but ssh.

### 1.3 Keep adam alive

tmux survives a dropped connection, not a stopped machine. On WSL2 three things
can kill the session while you are away:

| Threat | Fix |
|---|---|
| Windows goes to sleep | Settings → Power → sleep **Never** when plugged in |
| Windows Update reboots overnight | Pause updates before leaving adam unattended |
| WSL shuts the distro down when no Windows-side process holds it — this kills the tmux server | Keep a WSL terminal open, **or** register a keeper that starts at logon (below) |

Keeper task, created once from a WSL shell on adam:

```bash
schtasks.exe /create /tn "WSL keepalive" /sc onlogon /rl limited \
  /tr "wsl.exe -d Ubuntu --exec sleep infinity"
schtasks.exe /run /tn "WSL keepalive"      # start it now without logging out
```

A reboot still needs a Windows logon before the task fires; WSL and tmux do not
come back on their own, so a session never survives a reboot.

---

## 2. Worked example: a day across adam and quark

**Evening, at adam.** Start a session in the project you want Claude to work on:

```bash
cd ~/fortran/foresight
claude-remote start
```

You land inside tmux, in a shell where `claude` has just been launched. Give it
the task, e.g. *"run the test suite, fix the failures, write a summary in
NOTES.md"*. Then detach: **Ctrl-b**, release, **d**. The terminal returns;
Claude keeps running. You can close the terminal too — the session belongs to
the tmux server, not to the window.

```bash
claude-remote list
# claude: 1 windows (created Wed Oct  7 21:10:03 2026)
```

**Next morning, at the office, on quark:**

```bash
claude-remote -H wsl-adam attach
```

You see exactly the screen you left, with whatever Claude did overnight. Answer
its pending questions, give it the next task. Before closing the laptop, detach
with **Ctrl-b d** — or just close it; a dropped connection is a detach too.

**Evening, back at adam:**

```bash
claude-remote attach
```

Same session again, now locally. When the work is done, either `/exit` Claude
(the tmux session stays, with a shell prompt — `claude --continue` resumes the
conversation) or remove the session altogether:

```bash
claude-remote stop
```

### Leaving a session without killing it

**Detach** closes your view and leaves Claude running. Any of these works:

| How | Where | Notes |
|---|---|---|
| **Ctrl-b**, release everything, then **d** | inside the session | Two separate keystrokes. Holding Ctrl while pressing `d` sends `Ctrl-b Ctrl-d`, which is unbound: nothing happens |
| `! tmux detach` | at Claude's prompt | `!` runs a shell command from Claude; it inherits `$TMUX`, so it detaches your client |
| `claude-remote -H wsl-adam detach [name]` | any other terminal | detaches every client of the session, e.g. a stuck one |
| **Enter**, then **~** **.** | the ssh client on quark | ssh escape: drops the connection; tmux detaches automatically |
| close the terminal or the laptop lid | — | a dropped connection is a detach |

What **ends** the session instead:

- **Ctrl-d** or `exit` at the shell prompt in the session: the shell is the
  session, when it exits the session is gone.
- `claude-remote stop`.
- Leaving Claude (`/exit`, or Ctrl-c twice) does *not* end the session — you land
  at the shell prompt inside it; run `claude --continue` there, or detach.

### Several sessions at once

Name them; the name is the handle everywhere.

```bash
# on adam
claude-remote start foresight ~/fortran/foresight
claude-remote start harp      ~/python/harp
CLAUDE_REMOTE_CMD=claude-cnr claude-remote start cnr ~/papers/draft   # another account

# from quark
claude-remote -H wsl-adam list
claude-remote -H wsl-adam attach harp
```

Inside tmux, **Ctrl-b s** shows all sessions and switches between them without
detaching.

### Starting a session from quark

Everything works through `-H`, including `start`; the directory is a path **on adam**:

```bash
claude-remote -H wsl-adam start review ~/python/harp -- --model opus
```

Arguments after `--` are passed to `claude`. Leave `~` unquoted: quark's shell
expands it to `/home/stefano`, the same path on adam. A quoted `'~/…'` reaches
adam as a literal tilde and the directory check fails.

---

## 3. Command reference

```
claude-remote [-H host] start  [name] [dir] [-- claude-args]   start, or reattach if it exists
claude-remote [-H host] attach [name]                          reattach
claude-remote [-H host] detach [name]                          detach all clients, keep the session
claude-remote [-H host] list                                   running sessions
claude-remote [-H host] stop   [name]                          kill a session
claude-remote [-H host] headless "prompt" [dir]                one-shot run, logged to dir/claude_run_*.log
```

| Item | Default / meaning |
|---|---|
| `name` | `claude`; letters, digits, `-`, `_` only (tmux reads `.` and `:` as separators) |
| `dir` | current directory (on the host when `-H` is used — the remote `$HOME`) |
| `-H host` | run the command on `host` via `ssh -t`; the client needs no tmux |
| `CLAUDE_REMOTE_CMD` | what is typed into the session, default `claude`; any wrapper from `~/.bash/claude_code` works (`claude-cnr`, `claude-local`, …) |
| `CLAUDE_ALLOWED_TOOLS` | tools pre-approved in `headless`, default `Bash,Read,Edit,Write,Glob,Grep` |

ssh does not forward the environment, so `-H` passes both variables to the host
explicitly: `CLAUDE_REMOTE_CMD=claude-cnr claude-remote -H wsl-adam start cnr`
launches `claude-cnr` on adam.

tmux keys used here (prefix **Ctrl-b**, then the key): `d` detach · `s` session
list · `[` scroll mode (`q` to leave). With screen as fallback the prefix is
**Ctrl-a**.

Plain-ssh equivalent, for a client without the script:
`ssh -t stefano@wsl-adam tmux attach -t claude`.

---

## 4. Headless runs

For a task that needs no conversation:

```bash
claude-remote -H wsl-adam headless "Run the benchmarks and summarise them in REPORT.md" ~/fortran/foresight
# → Headless run started (PID 12345). Log: /home/stefano/fortran/foresight/claude_run_20261008_091500.log
ssh stefano@wsl-adam tail -f /home/stefano/fortran/foresight/claude_run_20261008_091500.log
```

It runs `claude -p` with `--permission-mode acceptEdits` and the tools in
`CLAUDE_ALLOWED_TOOLS`. That set includes `Bash`, i.e. arbitrary shell commands
without asking: treat a headless run as unattended shell access to adam. Open
the result interactively afterwards with `cd <dir> && claude --continue`.

---

## 5. How it works, and why

- **Claude is typed into a shell, not run as the pane command.** The session
  starts an ordinary interactive login shell and `claude` is sent to it as
  keystrokes. The shell loads `~/.bash/claude_code`, so the `claude-*` wrappers
  exist; and when Claude exits the shell remains, so the session survives `/exit`.
- **`-H` re-runs the script on the host.** It executes
  `ssh -t host '$HOME/.scripts/claude-remote <args>'`, with the arguments
  re-quoted for the remote shell and `$HOME` expanded remotely.
- **Remote commands only get the system PATH.** `ssh host cmd` and `bash -lc cmd`
  start a non-interactive shell; `~/.bash_profile` sources `~/.bashrc`, which
  returns at its PS1 guard before `~/.bash/paths` runs. Measured from quark on
  2026-10-07:

  ```
  PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin
  ```

  Hence `ssh wsl-adam claude-remote list` → *command not found*. The script
  calls itself by absolute path and prepends `~/.bin`, `~/.scripts` and
  `~/.local/bin` (where `claude` lives) to its own PATH. The `.bashrc` guard is
  deliberately left alone: it protects scp, rsync and git-over-ssh on every host.
- **Targets are exact** (`tmux -t =name`): `stop cl` cannot kill `claude`.

---

## 6. Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `no server running on /tmp/tmux-1000/default` or `No session named 'claude'` | WSL was shut down or Windows rebooted; the session is gone | §1.3. Start a new session; `claude --continue` in the same directory restores the conversation |
| `claude-remote: command not found` on quark | script not pulled yet | `cd ~/dotfiles && git pull` |
| `bash: …/claude-remote: No such file or directory` with `-H` | not stowed on adam | on adam: `bash ~/dotfiles/dotify.sh scripts` |
| `Session 'claude' is running; no terminal to attach to` | no tty (plain `ssh host cmd`, a script, a pipe) | use `-H`, or `ssh -t` |
| `ssh: Could not resolve hostname wsl-adam` | Tailscale down on quark, or MagicDNS off | `sudo systemctl start tailscaled`; `tailscale status`; fall back to the `100.x.y.z` address |
| ssh prints a login URL and waits | Tailscale SSH check mode | open the URL, confirm, the connection continues |
| attach works but feels laggy | traffic goes through a DERP relay (office firewall blocks UDP) | expected; `tailscale status` shows `relay "…"`. Usable for a terminal |
| window is cropped / small | another client is attached with a smaller terminal | `tmux attach -d -t claude` (detaches the others) |
| `sessions should be nested with care` | running `tmux attach` inside tmux | `claude-remote attach` handles it (switch-client); or **Ctrl-b s** |
| Claude did nothing overnight | it stopped at a permission prompt | answer it; next time pre-approve tools, or use a permission mode |
| **Ctrl-b d** does nothing | Ctrl held down while pressing `d` (that is `Ctrl-b Ctrl-d`, unbound) | press Ctrl-b, release, then `d`; or `! tmux detach` in Claude; or `claude-remote -H wsl-adam detach` from another terminal (§2) |
| session vanished after trying to leave | Ctrl-d / `exit` reached the shell prompt in the session | detach instead of exiting (§2, *Leaving a session*) |

---

## 7. Related

- **Remote Control:** inside a session, `/remote-control` lets you follow and
  steer it from claude.ai or the mobile app. The process still has to live in
  tmux on adam; this is a second window onto it, not a replacement.
- Why Tailscale and not port forwarding: adam's line is behind carrier-grade
  NAT (no public IPv4, no global IPv6 in WSL), so nothing can connect *in*.
  Both Tailscale nodes connect *out* to the coordination server and to each
  other; if UDP hole punching fails, traffic falls back to HTTPS relays.
