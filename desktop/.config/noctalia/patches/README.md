# Local patches to Noctalia-generated files

## qt6ct disabled colors

**Problem.** Noctalia's Qt template (`/usr/share/noctalia/assets/templates/qt/qtct.conf`)
emits `disabled_colors` byte-identical to `active_colors`. Disabled Qt widgets are
therefore indistinguishable from enabled ones — greyed-out buttons and menu entries
do not look greyed out.

**Fix.** `~/.local/bin/noctalia-qt-dim-disabled` rewrites the `disabled_colors` row
of `~/.config/qt6ct/colors/noctalia.conf`, blending only the foreground roles toward
the window background. Background roles are left untouched so disabled controls stay
on the same surface. The values are computed from whatever palette is active, so the
script works after a palette switch, not just for Solarized.

**When to run it.** Noctalia regenerates the palette file and reverts this fix on:

- a colour-scheme change (`noctalia msg color-scheme-set ...`, or the GUI)
- `noctalia msg templates-apply`
- a theme-mode switch (dark/light)

Re-run afterwards:

    noctalia-qt-dim-disabled

It is idempotent — running it when already dimmed prints "already dimmed" and exits 0.

**Not automated.** Noctalia's hooks system exposes only a `wallpaper_changed` event
(checked against the v5.0.0 binary, 2026-08-30); there is no templates-applied or
theme-changed event to attach this to. Invocation is manual by necessity.

**Contrast achieved** (Solarized dark, against background `#002b36`):

| role                    | ratio   |
|-------------------------|---------|
| active text (unchanged) | 4.75:1  |
| disabled text           | 2.76:1  |
| disabled placeholder    | 2.21:1  |

Tune the `FADE` factors at the top of the script to taste; higher = fainter.

**Qt setup this depends on** (already in place):

- `qt6ct` installed; `QT_QPA_PLATFORMTHEME=qt6ct` exported from `~/.config/sway/config`
- `~/.config/qt6ct/qt6ct.conf` sets `style=Fusion` + `custom_palette=true`
  (Fusion is required: the other Qt styles ignore custom palettes)
- `qt5ct` deliberately NOT installed — there is no `qt5-base` on this system

---

## foot bright0 (vim background)

**Problem.** Noctalia emits `bright0` (ANSI 8) as a lifted slate `#335e69` instead of
Solarized's canonical `#002b36`. Solarized's vim colorscheme maps `base03` -> ANSI 8
and uses it as the `Normal` background (`solarized.vim:372`, `let s:back = s:base03`),
so vim's entire editor area renders washed-out slate rather than near-black.
Confirmed by sampling a screenshot: editor background was `srgb(51,94,105)` = `#335e69`.

Only affects terminals whose colorscheme reads the ANSI palette — vim in 16-colour
mode (`g:solarized_termcolors` defaults to 16), which is the case here.

**Fix.** `~/.local/bin/noctalia-foot-fix-bright0` sets `bright0` equal to the theme's
own `background` value.

    noctalia-foot-fix-bright0

Idempotent. Re-run after any palette change or `noctalia msg templates-apply`,
same triggers as the qt6ct patch above.

**Trade-off.** "Bright black" text (ANSI 8, or SGR 90) becomes invisible against the
background — contrast 1.00:1. That is canonical Solarized behaviour, and the reason
Noctalia lifted the value in the first place. Checked at the time of writing: nothing
in `LS_COLORS` used it. If some tool's dim text disappears, that is this trade-off,
and `bright0` can be lifted slightly (e.g. `#0a3540`) as a compromise.

**Restart required.** foot reads its config only at startup; open a new window.

---

## Google Chrome — NOT themeable by Noctalia

Recorded so this is not re-investigated. Noctalia has no Chrome template and cannot
gain one: its Firefox support works only because Pywalfox supplies a browser extension
plus a native host process. Chrome's UI chrome (tab strip, toolbar, omnibox) is not
styleable by any external config file — only by a Web Store theme or Chrome's own
settings. Chrome will not be Solarized.

What was done instead — `~/.config/chrome-flags.conf`:

    --ozone-platform-hint=auto
    --gtk-version=4

Native Wayland rendering (sharper on the 1.5x-scaled DSI-1 output) and GTK4 integration,
so the window frame, menus, and toolbar follow `adw-gtk3-dark`.

NOTE the filename: Arch's `/usr/sbin/google-chrome-stable` wrapper reads
`$XDG_CONFIG_HOME/chrome-flags.conf` — NOT `google-chrome-flags.conf`, which is the
Chromium convention and is silently ignored here.

Also required, once, in the GUI: `chrome://settings/appearance` -> Theme = GTK,
Mode = Dark. Chrome's stored theme was unset, so it sat on its built-in default and
ignored GTK regardless of the flags.

Verify with `chrome://version`: "Command Line" should list both flags and the Ozone
platform should be `wayland`.

Revert: `rm ~/.config/chrome-flags.conf` and restart Chrome.

---

## Switching palettes: use `noctalia-retheme`

    noctalia-retheme --list                 show available schemes + current
    noctalia-retheme                        re-apply current palette + patches
    noctalia-retheme builtin Nord           switch to a builtin scheme
    noctalia-retheme community Solarized    switch to a cached community palette

Builtins: Catppuccin, Dracula, Gruvbox, Kanagawa, Nord, Oxocarbon.
Community (cached): Oxocarbon, Solarized.

It switches the scheme, re-applies templates, then re-runs both patches above.
Takes ~7s. Afterwards: new terminal window, restart GTK/Qt apps, `swaymsg reload`.

### Two daemon behaviours the wrapper works around

**1. `color-scheme-set` alone is not enough.** It persists the choice to
`settings.toml`, but the running daemon keeps rendering templates from its
previously loaded palette — so the generated files come out with the OLD colours
even though `color-scheme-get` already reports the new scheme. The wrapper issues
`noctalia msg config-reload` after switching. Without it, sway/gtk/qt silently keep
the previous palette while foot and btop update, leaving a half-switched desktop.

**2. `templates-apply` returns `ok` before the files are written.** Rendering is
asynchronous and `~/.config/sway/noctalia` is consistently written several seconds
after the rest. Patching immediately reads stale content and no-ops. The wrapper
waits for the generated files' checksums to stop changing (content hashing, not
mtime — Noctalia skips rewriting a file whose content would be unchanged, so its
mtime never moves).

### The foot bright0 patch is conditional

Every Noctalia palette lifts bright-black above the background (Solarized
`#335e69` vs `#002b36`; Oxocarbon `#393939` vs `#161616`) — a deliberate convention
so dim text stays legible, not a Solarized-specific bug. It only causes trouble
because *Solarized's vim colorscheme* maps `base03` -> ANSI 8 and paints `Normal`
with it. The wrapper therefore applies that patch only when `~/.vimrc` sets a
`solarized*` colorscheme, and skips it otherwise. If you switch vim colorschemes,
that condition is what to revisit.

