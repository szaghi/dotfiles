---
title: scripts
---

# scripts

The `scripts/` package holds the personal command-line tools: image and PDF helpers, package-list dumps, mount and
backup wrappers, the git integrity scanner, the editor installers, the Claude Code tooling and the root-owned
installers of the two desktops. Stow deploys `scripts/.scripts/` to `~/.scripts/`, `scripts/.bin/` to `~/.bin/` and
`scripts/.config/systemd/user/` to `~/.config/systemd/user/`. `~/.bash/paths` appends `~/.bin` and `~/.scripts` to
`PATH`, so every tool runs by name in an interactive shell.

```bash
bash ~/dotfiles/dotify.sh scripts
```

A new file in `scripts/.scripts/` needs a re-stow on hosts where `~/.scripts` is a directory of per-file links (adam).
Where `~/.scripts` is a single link to the whole directory, `git pull` is enough.

## Reference

Usage lines come from each script's own help text or argument parsing. Scripts that loop over the current directory
take no file argument.

### Images and photos

ImageMagick (`convert`, `composite`, `montage`) unless noted. Output files get a prefix; `trim_image` works in place.

| Script | What it does | Usage |
|---|---|---|
| `alpha_image` | Makes white pixels transparent, writes `alpha-<file>` | `alpha_image [file]` (no argument: every `*png *jpg`) |
| `convert_image` | Converts every `*<from>` file to `<to>` | `convert_image <from_ext> <to_ext>` |
| `crop_image` | Crops every file in the directory, writes `cropped-<file>` | `crop_image <width> <height> <x> <y>` |
| `gray_image` | Flattens on white and converts to grey, writes `grey-<file>` | `gray_image <ext>` |
| `overlap_image` | Composites every file onto a canvas, writes `overlap-<file>` | `overlap_image <canvas> <+x> <+y>` |
| `scale_image` | Scales by an ImageMagick geometry, writes `scaled-<file>` | `scale_image <geometry>` (all files) or `scale_image <file> <geometry>` |
| `trim_image` | Trims borders in place | `trim_image [file]` (no argument: every `*png *jpg`) |
| `proof_sheet.sh` | Proof sheets of the `*.jpg` files, landscape and portrait separately (exiftool, montage) | `proof_sheet.sh [-Nx 8] [-Ny 4] [-cs 28] [-o proof_sheet.jpg]`, `-h` for help |
| `jpg_rename` | Renames `*.jpg` to the EXIF `DateTimeOriginal`, `YYYY_MM_DD-HH_MM_SS.jpg` (exiftool) | `jpg_rename` |
| `nef_rename` | Same for Nikon `*.nef` | `nef_rename` |
| `mp4_rename` | Same for `*.mp4` from `CreateDate`, and renames the matching `.SRT` / `.LRF` sidecars | `mp4_rename` |
| `nef2jpg_thumb` | Extracts the embedded JPEG thumbnail of every `*.nef` (`dcraw -e`) | `nef2jpg_thumb` |

### PDF

Ghostscript (`gs`) unless noted.

| Script | What it does | Usage |
|---|---|---|
| `pdf2grey` | Converts a colour PDF to greyscale | `pdf2grey file.pdf -o out.pdf` |
| `pdfA4scale` | Scales every page to fit A4 | `pdfA4scale file.pdf -o out.pdf` |
| `pdfcompress` | Recompresses with a `-dPDFSETTINGS` preset; default output `<name>-small.pdf` | `pdfcompress large.pdf [-o small.pdf] [-c screen\|ebook\|printer\|prepress\|default]` |
| `image2pdf` | Converts every `*png *jpg` to PDF (ImageMagick) | `image2pdf` |

### Video

| Script | What it does | Usage |
|---|---|---|
| `jpg2mjpeg` | Encodes every `*.jpg` into an MJPEG AVI, 25 fps by default (mencoder) | `jpg2mjpeg out.avi` or `jpg2mjpeg -fps <n> out.avi` |
| `png2xvid.sh` | Encodes `<prefix>*.png` into an Xvid AVI (mencoder) | `png2xvid.sh <path_prefix> <fps> <bitrate> <out.avi>` |

### Tecplot

The sources live in `scripts/.scripts/tecplot/`; top-level symlinks put them on `PATH`.

| Script | What it does | Usage |
|---|---|---|
| `body2tec` | Body file (point count, then 8 corners per body) to Tecplot zones | `body2tec <input_body_file> <output.tec>` |
| `boxes2tec` | Boxes file to Tecplot zones, one zone per box | `boxes2tec <input_boxes_file> <output.tec>` |
| `info2tec` | `domain` lines of one or more `.geo` info files to Tecplot zones | `info2tec <info1.geo> [info2.geo ...] <output.tec>` |
| `cvs2tec` | Comma-separated table to a Tecplot file, rows sorted on one column | `cvs2tec <sort_column> <file.csv> <file.dat>` |
| `tec2vtk` | Tecplot ASCII to legacy VTK (pyvtk, SciPy); ASCII output unless `-b` | `tec2vtk [-b] [-vect2D=i,j,name] [-vect3D=i,j,k,name] file.tec ...` |

### Package lists

| Script | What it does | Usage |
|---|---|---|
| `dpkg-list-pkgs.sh` | Dumps `dpkg --get-selections`, to stdout or a file | `dpkg-list-pkgs.sh [file]` |
| `dpkg-install-pkgs.sh` | Restores a selection list and runs `apt-get dselect-upgrade` | `dpkg-install-pkgs.sh <file>` |
| `pacman-list-pkgs.sh` | Writes explicit repo packages (minus `base`) and foreign (AUR) packages to two lists | `pacman-list-pkgs.sh <main-list> <local-list>` |
| `pacman-install-pkgs.sh` | Installs the two lists: `pacman -S --needed`, then `yaourt` for the foreign ones | `pacman-install-pkgs.sh <main-list> <local-list>` |

### Backup and mounting

| Script | What it does | Usage |
|---|---|---|
| `borg-automated-backup.sh` | `borg create` + `borg prune` to two NAS repositories, see [below](#borg-automated-backup-sh) | `borg-automated-backup.sh` |
| `mount_nas.sh` | NFSv3 mount of the NAS home share; the address comes from `NAS_ODROID_IP` | `mount_nas.sh` |
| `mountiso` | Loop-mounts an ISO 9660 image (sudo) | `mountiso <file.iso> <dir>` |
| `umountiso` | Unmounts it (sudo) | `umountiso <dir>` |
| `archive.sh` | One `tar` per entry of the current directory; optionally deletes the originals and compresses with pbzip2 | `archive.sh [--delete] [--pbzip2]` |

### Git

| Script | What it does | Usage |
|---|---|---|
| `git-health` | Report-only integrity scan of git repositories, see [below](#git-health) | `git-health [-d N] [-r DIR] [--deep] [-q]` |
| `git-health-boot` | Runs `git-health` after a detected unclean shutdown; driven by a systemd user unit | `git-health-boot [check\|clean]` |
| `git_list_large_files.sh` | The 10 largest objects in the pack files, with their paths; run from the repository root | `git_list_large_files.sh` |
| `rwd` | "rewind": a small diff/patch version control for text files, with optional kdialog GUI variants | `rwd help` lists `init`, `add`, `commit`, `branch`, `log`, ... |

### Editor installers

| Script | What it does | Usage |
|---|---|---|
| `install-nvim` | Neovim plus rg, fd and the tree-sitter CLI, see [below](#install-nvim) | `install-nvim` |
| `install-vim-lsp.sh` | LSP servers and linters shared by vim and nvim, see [below](#install-vim-lsp-sh) | `install-vim-lsp.sh` |

### Claude Code tooling

| Script | What it does | Usage |
|---|---|---|
| `skills-apply` | Installs, updates and reports the declared Claude Code skills, see [below](#skills-apply) | `skills-apply install\|update\|status\|remove <name>` |
| `claude-remote` | Claude Code sessions in tmux that survive SSH disconnects, see [below](#claude-remote) | `claude-remote [-H host] <command> [args]` |
| `night` | Step snapshots for unattended work; symlink to `claude/.claude/skills/night-protocol/scripts/night`, see [Night protocol](/claude/night-protocol) | `night init\|snap\|gate\|verify\|status\|commit\|clean` |
| `llama-anthropic-proxy.py` | Anthropic Messages API to OpenAI Chat Completions proxy, for llama-server | `llama-anthropic-proxy.py [--host 127.0.0.1] [--port 4000] [--backend http://127.0.0.1:8080] [--no-think]` |

`--no-think` appends `/no_think` to the system prompt, which disables extended reasoning on Qwen3.5-style models.
`LLAMA_PROXY_VERBOSE` set in the environment turns on request logging.

### Desktop and host installers

| Script | What it does | Usage |
|---|---|---|
| `quark-desktop-install` | quark, root-owned parts: touchpad hwdb fuzz (then `udevadm trigger`), iwlwifi and NetworkManager power-save off, power save off on the active WiFi profile, a reminder of the Noctalia template set | `quark-desktop-install` (calls `sudo` itself) |
| `astrobit-system-install` | astrobit, root-owned parts: rtw88 Deep Power Save and NetworkManager power-save off, virtual EDID blob in `/lib/firmware/edid/`, Limine kernel command line (backs up `/etc/default/limine` first) | `sudo astrobit-system-install` |
| `noctalia-retheme` | Switches or re-applies the Noctalia palette, reloads the daemon, waits for the templates to settle, re-runs the Qt patch | `noctalia-retheme [--list \| builtin <Name> \| community <Name>]` |
| `noctalia-qt-dim-disabled` | Blends the foreground roles of qt6ct's `disabled_colors` toward the background; idempotent | `noctalia-qt-dim-disabled` |

Both installers are idempotent and exit 1 when a step fails. `DOT` overrides the dotfiles path (default
`~/dotfiles`). Context: [quark desktop](/packages/desktop-quark), [astrobit desktop](/packages/desktop-astrobit).

### Mail

| Script | What it does | Usage |
|---|---|---|
| `mbox-index.py` | Google Takeout MBOX archives to a searchable SQLite FTS5 database, see [below](#mbox-index-py) | `mbox-index.py build\|search\|show\|get ...` |

### Miscellaneous

| Script | What it does | Usage |
|---|---|---|
| `bd` | Jump back to a parent directory by name. Vendored from `vigneshwaranr/bd` (v1.03); its completion is `bash/.bash/completions/bd` | `bd [-s\|-si] <pattern>` |
| `pps` | Lists processes, or sends HUP/KILL/STOP/CONT to the ones matching a name (or the PID in the newest `*.pid`) | `pps -a\|-e\|-l\|-h\|-k\|-s\|-c [prog]` |
| `Ds+.sh` | First-cell wall spacing for y+ = 1, modelled and resolved wall, from the Reynolds number | `Ds+.sh <Re> [<high-Re switch, default 1e6>]` |
| `md-preview.sh` | Renders every `*.md` with `github-markdown-preview` and opens it in Chromium; Ctrl-C cleans up | `md-preview.sh` |
| `texcount.pl` | TeXcount 3.0, vendored: word count of LaTeX sources | `texcount.pl [options] file.tex`, `-h` for help |
| `rainix` | Vendored `dialog` menu player for RAI live, replay and radio streams (2015 endpoints) | `rainix` |

### `~/.bin`

| File | What it does | Usage |
|---|---|---|
| `act` | Static `nektos/act` binary (0.2.28): runs GitHub Actions workflows locally | `act [event]` |
| `hpc-login` | HPC SSH login through `step ssh login` (Step CA), with the OIDC browser flow driven by headless Playwright; username, password and OTP are asked on the terminal and never stored | `hpc-login [--headed] [--identity ID] [--provisioner P] [--screenshot] [--debug]` |

`hpc-login` creates its own venv (`~/.bin/hpc-login-venv/`, gitignored) with Playwright and Chromium on first run.

## git-health

Detects the corruption an unclean WSL2 or host shutdown leaves in git repositories and reports it. It never repairs.
Rationale, measured costs and the recovery playbook: `scripts/.scripts/git-health.md`.

```bash
git-health                 # every repository under $HOME
git-health -d 7            # only repositories whose .git changed in the last 7 days
git-health -r ~/fortran    # search one tree
git-health --deep          # also run git fsck --no-dangling
git-health -q              # only suspect repositories and the summary
```

| Option | Environment | Default |
|---|---|---|
| `-d`, `--days N` | `GIT_HEALTH_DAYS` | all repositories |
| `-r`, `--root DIR` | `GIT_HEALTH_ROOT` | `$HOME` |
| none | `GIT_HEALTH_MAXDEPTH` | `6` |

Exit status: `0` all scanned repositories healthy (or none found), `1` at least one suspect, `2` usage error or git
missing.

Per repository it checks: zero-length loose objects; `HEAD` resolves (an unborn branch with no refs is not flagged);
no ref names a missing object; `rev-list --objects --all` walks the graph; `cat-file --batch-all-objects --batch`
inflates every object; no leftover `tmp_pack_*` while no git process runs. The decompression pass is the one that
catches a shredded pack: the graph walk reads object headers only.

### Boot-time scan

`git-health-boot` and `scripts/.config/systemd/user/git-health-boot.service` run the scanner only after an unclean
shutdown. `ExecStart` runs `git-health-boot check`: if the marker file exists, it scans the repositories active in
the last `GIT_HEALTH_BOOT_DAYS` days (14, set in the unit) and re-arms the marker; otherwise it arms the marker and
exits. `ExecStop` runs `git-health-boot clean`, which removes the marker.

```bash
systemctl --user daemon-reload
systemctl --user enable --now git-health-boot.service
journalctl --user -u git-health-boot -b        # read the result
```

| Variable | Default | Meaning |
|---|---|---|
| `GIT_HEALTH_MARKER` | `$XDG_RUNTIME_DIR/git-health.boot-marker` | Dirty-boot marker |
| `GIT_HEALTH_BOOT_DAYS` | `14` | Recency window of the boot scan |
| `GIT_HEALTH_HOME` | `$HOME` | Root passed to `git-health --root` |
| `GIT_HEALTH_BIN` | `~/.scripts/git-health` | Scanner path |

### Things to know

- **It never repairs, by design.** During the 2026-07-31 incident 4 of the 13 empty objects were staged blobs whose
  working-tree files were the only copies. An automatic cleanup would have deleted real work.
- **`ProtectHome=read-only`** enforces report-only in the unit: the scan cannot write to any repository.
  `ReadWritePaths=%t` leaves only the runtime directory writable, for the marker.
- **`SuccessExitStatus=0 1`**: exit 1 means "suspect repositories found". Without it the unit shows as failed.
- **The marker lives in `$XDG_RUNTIME_DIR`, not `/run`.** A user unit gets EACCES on root-owned `/run`; the marker
  then never appears and no crash is ever detected. `git-health-boot` prints an error when it cannot write the marker.
- Both scripts ignore SIGPIPE, so `| head` cannot turn the 0/1 status into 141.
- The unit runs at `Nice=19` with idle CPU and I/O scheduling.

::: warning The dirty-boot gate does not fire after a VM restart
`$XDG_RUNTIME_DIR` is tmpfs, and tmpfs is empty after every boot, clean or not. After a WSL VM restart or a host
reset the marker is therefore absent and `git-health-boot` reports a clean boot. The journal on adam shows this:
sessions that ended without the stop job were followed by "clean boot -- marker armed, no scan needed". The gate
fires only if the user manager restarts within one kernel boot without running `ExecStop`. After a crash, run
`git-health -d 14` by hand.
:::

## claude-remote

Runs Claude Code inside a tmux session (screen as fallback) so the session survives an SSH disconnect, and reattaches
to it from another host. Setup across adam and quark, worked example and troubleshooting:
`scripts/.scripts/claude-remote.md`.

```bash
claude-remote start [name] [dir] [claude-args]   # start or reattach; dir defaults to $PWD
claude-remote attach [name]                      # reattach, detaching other clients
claude-remote detach [name]                      # detach every client, the session keeps running
claude-remote list
claude-remote stop [name]
claude-remote headless "prompt" [dir]            # one-shot claude -p run, logged to claude_run_<date>.log
claude-remote -H wsl-adam attach                 # run the command on another host over ssh -t
```

The default session name is `claude`. Claude arguments start at the first argument beginning with `-`, or after `--`.
Detach with Ctrl-b d (tmux) or Ctrl-a d (screen).

| Variable | Default | Meaning |
|---|---|---|
| `CLAUDE_REMOTE_CMD` | `claude` | Command typed into the session; a wrapper such as `claude-cfd-cnr` works |
| `CLAUDE_ALLOWED_TOOLS` | `Bash,Read,Edit,Write,Glob,Grep` | Tools pre-approved for `headless` |

### Things to know

- **Remote commands get the system `PATH` only.** `ssh host cmd` and `bash -lc cmd` stop at the PS1 guard of
  `~/.bashrc` before `~/.bash/paths` runs, so `~/.scripts` and `~/.local/bin` (where `claude` lives) are missing. The
  script prepends `~/.bin`, `~/.scripts` and `~/.local/bin` itself, and `-H` calls the remote copy as
  `$HOME/.scripts/claude-remote`. Do not loosen the `.bashrc` guard: it protects scp, rsync and git over ssh.
- **`-H` needs only ssh locally.** quark has neither tmux nor screen. `CLAUDE_REMOTE_CMD` and
  `CLAUDE_ALLOWED_TOOLS` are passed to the remote side explicitly, since ssh does not forward the environment.
- **Claude is typed into the session's shell** (`send-keys`), not run as the pane command. The shell loads
  `~/.bash/claude_code`, so the `claude-*` wrappers exist, and the session outlives `/exit`.
- **Claude is launched as `TMUX= claude`.** With `$TMUX` set, Claude freezes its terminal-title status on the idle
  mark. Side effect: `! tmux detach` from Claude's prompt finds no client; use `! claude-remote detach`.
- A non-UTF-8 locale is replaced by `LANG=C.UTF-8`, and attach uses `tmux -u`; otherwise tmux draws every non-ASCII
  cell as `_`.
- Session names are letters, digits, `-` and `_`, not starting with `-`. Targets are exact (`-t =name`).
- tmux survives a dropped connection, not a stopped machine: on WSL2 the distro must be kept running (see
  `claude-remote.md`, "Keep adam alive").

## skills-apply

The per-host driver of the three-class skills machinery. The design (classes A, B, C, `manifest.toml`, host
profiles) is on [Skills](/claude/skills); this section covers the CLI only.

```bash
skills-apply install          # install every declared class-B plugin and class-C skill; idempotent
skills-apply update           # update every installed plugin and class-C skill
skills-apply status           # installed vs declared, for all three classes
skills-apply remove <name>    # uninstall one plugin or manifest skill (alias: uninstall)
```

| Input | Role |
|---|---|
| `~/.claude/settings.json`, `enabledPlugins` | Class B, through `claude plugin install\|update\|uninstall` |
| `~/.claude/skills/manifest.toml` | Class C: each entry's `check`, `install`, `update`, `uninstall` shell strings |
| `~/dotfiles/machines/<hostname>.skills` | Optional class-C filter; missing file means every manifest entry |

### Things to know

- Requires `python3` (with `tomllib`, or `tomli` as fallback) and the `claude` CLI; exits 2 when either is missing,
  and on an unknown command.
- `remove` does not edit `settings.json` or `manifest.toml`; it prints which declaration to delete. Without that edit
  the next `install` brings the skill back.
- `remove` matches plugin names by substring (`grep -F`): pass the full `name@marketplace`.
- Restart Claude Code after `install` or `update` so plugin changes load.

## mbox-index.py

Indexes Google Takeout MBOX exports into one SQLite FTS5 database and extracts attachments to a
`<year>/<sender>/<hash>_<name>` tree. Python 3 standard library only. Takeout export steps, output layout and the
Gmail quota clean-up: `scripts/.scripts/mbox-index.md`.

```bash
mbox-index.py build  ARCHIVE_DIR [--db mail.db] [--attach-dir attachments]
mbox-index.py search "QUERY"     [--db mail.db] [--limit 50]
mbox-index.py show   ID          [--db mail.db] [--chars 4000 | --full]
mbox-index.py get    ID          [--db mail.db] [--to .]
```

`build` recurses into `ARCHIVE_DIR` for `.mbox` files. Re-running it on the same database adds only new messages;
messages are de-duplicated by `Message-ID`, so a message exported under several labels is indexed once. `search`
prints the id in its first column; `show` and `get` take that id.

| Query token | Matches |
|---|---|
| bare words | FTS5 over subject, sender, recipients, body (`AND`, `OR`, `NOT`, `"phrase"`, `prefix*`) |
| `from:` / `to:` / `subject:` | Substring of that field |
| `has:attachment` | At least one attachment |
| `larger:N[K\|M\|G]` | Raw message size at least N |
| `before:YYYY-MM-DD` / `after:YYYY-MM-DD` | Date before / on or after |

Filters combine with AND: `mbox-index.py search "has:attachment larger:5M before:2022-01-01"`.

## borg-automated-backup.sh

Backs up the home directory and `~/fortran` to two borg repositories on NAS mounts. Each run creates an archive
named `<hostname>-<date>-<time>` with `--stats`, then prunes archives with the `<hostname>-` prefix to 7 daily,
4 weekly and 6 monthly.

```bash
BORG_NAS_ZAGHI=<repo> BORG_NAS_ODROID=<repo> borg-automated-backup.sh
```

The two variables override the built-in repository paths. The NAS shares must be mounted first (`mount_nas.sh`).

### Things to know

- No passphrase handling: borg reads it from its own environment (`BORG_PASSPHRASE`, `BORG_PASSCOMMAND`) or prompts.
- Nothing in the repository schedules it: no cron entry, no systemd timer.
- The script ends with `exit 0` and does not check borg's status: a failed backup still exits 0. Read the output.

## install-nvim

Installs Neovim and the tools its config needs, alongside vim. Idempotent; never touches vim.

```bash
~/.scripts/install-nvim
```

| Host | What it installs |
|---|---|
| Arch / CachyOS (`/etc/arch-release`) | `pacman -S --needed neovim ripgrep fd tree-sitter-cli` |
| Ubuntu (anything else) | nvim from the upstream x86_64 tarball, pinned and sha256-checked; `ripgrep` and `fd-find` with apt; `tree-sitter-cli` with npm |

### Things to know

- The pinned version and digest are `NVIM_VERSION` and `NVIM_SHA256` at the top of the script; bump them together.
- On Ubuntu each release unpacks into `~/.local/opt/nvim-v<version>/` and `~/.local/bin/nvim` links to the active
  one. Old versions stay, so a rollback is one `ln -sfn`.
- On Arch the version is whatever pacman ships, not the pin.
- Debian names fd `fdfind`; the script links `~/.local/bin/fd` to it.
- `npm install -g` runs in the nvm scope, without sudo.
- LSP servers are not installed here: see `install-vim-lsp.sh`.

## install-vim-lsp.sh

Installs the LSP servers and the linter of the vim setup; nvim uses the same binaries. Idempotent: a tool already on
`PATH` is skipped.

```bash
~/.scripts/install-vim-lsp.sh
```

| Tool | Role | Installed with |
|---|---|---|
| `fortls` | Fortran LSP | pipx |
| `basedpyright` | Python LSP and type checker | pipx |
| `bash-language-server` | Bash LSP | npm (nvm scope, no sudo) |
| `texlab` | LaTeX LSP | latest GitHub release (x86_64) into `~/.local/bin` |
| `shellcheck` | Bash linter for ALE | apt (sudo) |

### Things to know

- It stops at once unless `pipx`, `npm` and `apt-get` are all present: it is Debian/Ubuntu only.
- `ruff` and `gfortran` are assumed installed.
- It ends by printing the resolved path of each tool, or `MISSING`.

## Things to know

- **`-o` is mandatory for `pdf2grey` and `pdfA4scale`.** Their parser shifts the input file and then rejects the
  empty argument, so the documented default output (`<name>-grey.pdf`, `<name>-A4.pdf`) is never reached.
- **`proof_sheet.sh -cs` and `-o` are broken:** they read `$3` and `$4` after the shift instead of `$1`. Only `-Nx`
  and `-Ny` take effect.
- **`Ds+.sh` and `tec2vtk` are Python 2** (`print x`); they fail under Python 3.
- **`pacman-install-pkgs.sh` calls `yaourt`**, which is unmaintained. Both pacman scripts exit 2 even on success.
- `image2pdf` strips only `.png` from the name: `photo.jpg` becomes `photo.jpg.pdf`.
- `hpc-login`'s docstring shows `--shell-export`, but the parser does not define it; the call fails.
- `git-health.md`, `claude-remote.md` and `mbox-index.md` sit next to the scripts and are stowed into `~/.scripts/`
  with them.
