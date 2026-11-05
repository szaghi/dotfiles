---
title: astrobit desktop
---

# astrobit desktop

The `desktop-astrobit/` package is the Wayland desktop of astrobit, a GMKtec NucBox G5 (Intel N97, 12 GB) running
CachyOS. The machine exists to control the telescopes (INDI, KStars, PHD2), and the desktop is configured around
that job: **niri** as compositor, **Noctalia** as shell, **foot** as terminal and **Sunshine** as an emergency remote
desktop. It shares almost nothing with [quark's desktop](/packages/desktop-quark), so it is a separate package and
astrobit never stows `desktop/`.

## Install

```bash
bash ~/dotfiles/dotify.sh desktop-astrobit    # symlink the configs
sudo ~/.scripts/astrobit-system-install       # root-owned parts: WiFi power save, virtual EDID
```

`machines/astrobit` lists the two machine-specific packages, `bash-astrobit` (see
[per-host packages](/packages/host-specific)) and `desktop-astrobit`. `machines/astrobit.skills` restricts the
class-C Claude Code skills to `stop-slop`: this host drives telescopes, it is not a writing or video machine.

## Files

| Source | Deployed to | Sets |
|---|---|---|
| `.config/niri/config.kdl` | `~/.config/niri/config.kdl` | Only `include` lines |
| `.config/niri/cfg/*.kdl` | `~/.config/niri/cfg/` | One concern per file, see below |
| `.config/foot/foot.ini` | `~/.config/foot/foot.ini` | Terminal, Solarized inlined |
| `.config/sunshine/sunshine.conf` | `~/.config/sunshine/sunshine.conf` | Sunshine server settings |
| `.config/sunshine/apps.json` | `~/.config/sunshine/apps.json` | Sunshine application list |
| `system/` | not stowed | Root-owned files, installed by `astrobit-system-install` |

## niri

`config.kdl` holds nothing but eight `include "./cfg/<name>.kdl"` lines. The split comes from the CachyOS niri +
Noctalia preset and is kept so that one concern is editable without scrolling through the rest. Both levels are
tracked, and stow links them file by file: `~/.config/niri/` stays a real directory, so files niri or Noctalia write
there land next to the symlinks, not in the repo.

| File | Sets |
|---|---|
| `cfg/animation.kdl` | Spring and easing curves for workspace switch, window open/close/move/resize, view movement, config notification, screenshot UI, overview |
| `cfg/autostart.kdl` | `spawn-at-startup "noctalia"` |
| `cfg/display.kdl` | One output example (`DP-1`, 2560x1440, scale 1), disabled with the `/-` prefix: no output is configured |
| `cfg/input.kdl` | Keyboard, touchpad, mouse, focus behaviour |
| `cfg/keybinds.kdl` | All key bindings |
| `cfg/layout.kdl` | `gaps 16`; `center-focused-column "never"`; `background-color "transparent"` (Noctalia draws the wallpaper); preset column widths 1/3, 1/2, 2/3 |
| `cfg/rules.kdl` | Window rules: corner radius 20 with clipping, blur on every window; Noctalia settings window (`dev.noctalia.Noctalia`) floating at 1080x920; Steam windows floating; Noctalia wallpaper layer in the backdrop |
| `cfg/misc.kdl` | `prefer-no-csd`; `screenshot-path null`; environment; cursor `capitaine-cursors` size 24; blur parameters; `honor-xdg-activation-with-invalid-serial`; hotkey overlay skipped at startup |

### Input

| Setting | Value |
|---|---|
| Layout | `us` (ANSI US keyboard; the intl variants make `'` and `` ` `` dead keys) |
| Options | `caps:super,custom:it` |
| `numlock` | on at startup |
| Touchpad | `tap`, `natural-scroll` |
| Focus | `focus-follows-mouse`, `workspace-auto-back-and-forth` |

`caps:super` makes Caps Lock an extra Super, so it acts as niri's `Mod`. `custom:it` is a personal XKB option
defined in `~/.config/xkb`, which this package does not track. It types Italian without a layout switch:

| Keys | Result |
|---|---|
| `AltGr+a/e/i/o/u` | Vowel with grave accent |
| `AltGr+Shift+vowel` | Same, uppercase |
| `AltGr+'`, then vowel | Acute accent (dead key) |
| `AltGr+5` / `AltGr+0` | Euro / degree |

### Environment

`misc.kdl` exports `ELECTRON_OZONE_PLATFORM_HINT=auto`, `QT_QPA_PLATFORM=wayland`, `QT_QPA_PLATFORMTHEME=gtk3`,
`QT_WAYLAND_DISABLE_WINDOWDECORATION=1`, `XDG_CURRENT_DESKTOP=niri`, `XDG_SESSION_TYPE=wayland`. Qt follows GTK
here; quark routes it through qt6ct instead.

### Key bindings

`Mod` is Super (or Caps Lock, via `caps:super`).

**Applications and Noctalia**

| Keys | Action |
|---|---|
| `Mod+Return` | foot |
| `Mod+B` | firefox |
| `Mod+E` | nautilus |
| `Mod+Ctrl+Return` | Noctalia launcher |
| `Mod+S` | Noctalia control center |
| `Mod+Shift+S` | Noctalia settings |
| `Mod+Shift+Return` | Noctalia wallpaper selector |
| `Mod+Alt+L` | Lock screen |
| `Mod+Shift+Q` | Noctalia session menu |
| `Mod+Shift+Escape` | Hotkey overlay |

**Focus and movement**

| Keys | Action |
|---|---|
| `Mod+Q` | Close window |
| `Mod+H/L`, `Mod+Left/Right` | Focus column left / right |
| `Mod+K/J`, `Mod+Up/Down` | Focus window up / down |
| `Mod+Ctrl+H/L`, `Mod+Ctrl+Left/Right` | Move column left / right |
| `Mod+Ctrl+K/J`, `Mod+Ctrl+Up/Down` | Move window up / down |
| `Mod+Home` / `Mod+End` | Focus first / last column |
| `Mod+Ctrl+Home` / `Mod+Ctrl+End` | Move column to first / last |
| `Mod+Shift+Arrows` | Focus monitor in that direction |
| `Mod+Shift+Ctrl+Arrows` | Move column to monitor in that direction |
| `Mod+Shift+V` | Switch focus between floating and tiling |
| `Mod+[` / `Mod+]` | Consume or expel window left / right |
| `Mod+,` / `Mod+.` | Consume window into column / expel from column |

**Workspaces**

| Keys | Action |
|---|---|
| `Mod+1` … `Mod+9` | Focus workspace 1 … 9 |
| `Mod+Ctrl+1` … `Mod+Ctrl+9` | Move column to workspace 1 … 9 |
| `Mod+Tab` | Previous workspace |
| `Mod+WheelDown/Up` | Focus workspace down / up (150 ms cooldown) |
| `Mod+Ctrl+WheelDown/Up` | Move column to workspace down / up |
| `Mod+WheelRight/Left`, `Mod+Shift+WheelDown/Up` | Focus column right / left |
| `Mod+Ctrl+WheelRight/Left`, `Mod+Ctrl+Shift+WheelDown/Up` | Move column right / left |

**Layout and modes**

| Keys | Action |
|---|---|
| `Mod+R` / `Mod+Shift+R` | Next / previous preset column width |
| `Mod+Ctrl+Shift+R` / `Mod+Ctrl+R` | Next preset window height / reset height |
| `Mod+Minus` / `Mod+Equal` | Column width -10% / +10% |
| `Mod+Shift+Minus` / `Mod+Shift+Equal` | Window height -10% / +10% |
| `Mod+Ctrl+F` | Expand column to available width |
| `Mod+C` / `Mod+Ctrl+C` | Center column / center visible columns |
| `Mod+F` | Maximize column |
| `Mod+Shift+F` | Fullscreen window |
| `Mod+M` | Maximize window to edges |
| `Mod+T` | Toggle floating |
| `Mod+W` | Toggle tabbed column display |
| `Mod+O` | Overview |

**System**

| Keys | Action |
|---|---|
| `Ctrl+Shift+1` / `2` / `3` | Screenshot: interactive / screen / window |
| `Mod+Escape` | Toggle the keyboard-shortcut inhibitor (escape from a fullscreen app that grabs the keys) |
| `Mod+Shift+P` | Power off monitors |
| `Ctrl+Alt+Delete` | Quit niri |
| `XF86Audio{RaiseVolume,LowerVolume,Mute,MicMute}` | Volume and mic via Noctalia (also when locked) |
| `XF86Audio{Next,Prev,Play}` | Media next / previous / play via Noctalia |
| `XF86AudioPause` | `noctalia msg media stop` |
| `XF86MonBrightness{Up,Down}` | Brightness via Noctalia |

## foot

astrobit's `foot.ini` is not quark's:

| Setting | astrobit | Why |
|---|---|---|
| Colours | Solarized dark inlined in `[colors-dark]`, `alpha=0.92` | No Noctalia template is enabled here, so there is no generated theme to include |
| `term` | `xterm-256color` | The `foot` terminfo entry is missing on the remote HPC hosts, and an unknown `TERM` breaks curses applications over ssh |
| Font | `monospace:size=12` | No Nerd Font installed |

Other settings: `pad=6x6`, `initial-window-size-chars=100x30`, `selection-target=both`; 10000 scrollback lines,
`multiplier=3.0`; underline cursor, hollow when unfocused, no blink; `hide-when-typing=yes`;
`search-start=Control+Shift+f`. foot 1.26 and later select `[colors-dark]` or `[colors-light]` by
`initial-color-theme`, which defaults to dark; only the dark section is defined.

To use the real `term=foot` instead, install the entry once per remote host and restore the setting:

```bash
infocmp -x foot | ssh <host> -- tic -x -
```

## Sunshine

astrobit runs headless in normal operation. Sunshine is the fallback for faults in the GUI, such as a dialog that
blocks Ekos or a mount wizard, when the automatic rig start fails. Moonlight on quark is the client. The settings
favour text legibility and low CPU use over frame rate, so the stream does not steal CPU from the captures.

| File | Tracked | Content |
|---|---|---|
| `sunshine.conf` | yes | `sunshine_name = astrobit`; `stream_audio = disabled`; `csrf_allowed_origins` |
| `apps.json` | yes | One app, `Desktop`; `PATH` extended with `$(HOME)/.local/bin` |
| `sunshine_state.json`, `credentials/`, `*.log` | no, gitignored | Web-UI credentials, TLS keypair, pairing state: per-machine secrets |

- `capture` and `encoder` are deliberately unset. Forcing `capture = wlgrab` fails the init with "Could not initialize
  display with the given hw device type"; autodetect picks wlgrab (niri exposes `zwlr_screencopy_manager_v1`) and
  VAAPI by itself.
- Resolution, frame rate and bitrate are client choices, negotiated by Moonlight at stream start. `fps`,
  `resolutions` and `min_bitrate` are unrecognised options here and are silently ignored. Set Moonlight on quark to
  1920x1080, 30 fps, about 15 Mbps.
- Audio is off: it removes virtual sinks and desync as a class of problems.
- `csrf_allowed_origins` must list every form of URL used to reach the web UI (port 47990): the `Origin` header is
  the string typed in the address bar, not the resolved IP. A missing form shows up as a login loop: credentials are
  accepted, the session request is rejected, the browser returns to the login page.
- The web UI rewrites `apps.json`, so edits made there show up as a git diff.
- `scripts/.config/systemd/user/sunshine.service` is gitignored: it is the symlink `systemctl --user enable` writes,
  pointing at the distribution unit.

## desktop-astrobit/system

`desktop-astrobit/.stow-local-ignore` excludes `^/system$`. `astrobit-system-install` must run as root and installs:

| Source | Installed to | Sets |
|---|---|---|
| `system/modprobe.d/rtw88-no-deep-ps.conf` | `/etc/modprobe.d/` | `options rtw88_core disable_lps_deep=y` |
| `system/NetworkManager/conf.d/wifi-powersave-off.conf` | `/etc/NetworkManager/conf.d/` | `wifi.powersave = 2` (disable) |
| `system/firmware/edid/astrobit-1920x1080.bin` | `/lib/firmware/edid/` | Virtual 1920x1080 EDID |

**WiFi power save, on two levels.** The RTL8821CE's `rtw88` driver enables Deep Power Save by default; it parks
parts of the radio between beacons, and each wakeup costs tens of milliseconds. On a link measured at -45 dBm with
zero tx retries, that alone caused the Moonlight stutter and drops, and the stalls of idle ssh sessions.
NetworkManager's setting drives mac80211 power save; Deep PS lives in the driver and is reachable only as a module
parameter. Both are needed. The `conf.d` default applies to profiles that leave `802-11-wireless.powersave` at its
default.

**Virtual EDID.** niri has no virtual outputs and no headless mode: with the monitor unplugged it has no output to
draw on and Sunshine has nothing to capture. The script appends two parameters to `KERNEL_CMDLINE[default]` in
`/etc/default/limine` (backup kept) and runs `limine-update`:

| Parameter | Job |
|---|---|
| `drm.edid_firmware=HDMI-A-2:edid/astrobit-1920x1080.bin` | Which EDID to use on HDMI-A-2 |
| `video=HDMI-A-2:e` | Force the connector enabled when nothing is detected; without it the kernel disables the port and never reads the EDID |

1920x1080 is deliberately lower than the physical 3440x1440 ultrawide: it is what gets streamed.

The script ends by printing the current `power_save` of `wlan0` (want `off`), `disable_lps_deep` (want `Y`) and the
niri output mode (want `1920x1080`). It is idempotent and exits 1 if a step failed.

## Things to know

- Module parameters and the kernel command line apply on the next boot.
- The `/etc/default/limine` edit is skipped if `edid_firmware` is already present, so changing the EDID parameters
  means editing that file by hand.
- After creating `~/.config/xkb`, restart niri: libxkbcommon fixes its include path when the context is created and
  drops directories that do not exist, so `custom:it` is otherwise silently ignored.
- niri editing backups (`*.bak`) in `~/.config/niri/` stay untracked.
