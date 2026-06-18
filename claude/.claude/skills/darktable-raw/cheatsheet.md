# Cheatsheet — darktable 4.6 Decisions

## Develop order (always)
basics (exposure → filmic → color balance rgb saturation) → corrections (lens, CA, color calibration, denoise) → creative (retouch, color zones, effects) → crop.

## Decision rules
- **Tone too flat / wrong brightness?** → exposure (mid-gray), NOT levels/tone curve (deprecated in scene-referred).
- **Blown highlights?** → filmic scene white-point + reconstruct tab; for clouds use highlight-reconstruction `clip`/`LCh`; for skin use `reconstruct color`; for spotlights `guided laplacians`.
- **One bright region to pull down?** → tone equalizer (eigf mask) or any module + mask.
- **Color cast / WB?** → color calibration CAT (illuminant = as-shot; escalate to AI-surfaces). NOT the white balance module.
- **Need saturation?** → color balance rgb global vibrance/saturation ("basic colorfulness").
- **Need one specific color changed?** → color zones (targeted HSL), not global saturation.
- **Global contrast?** → tone equalizer. color balance rgb contrast only with a mask.
- **Noisy file?** → demosaic LMMSE + denoise (profiled) early, before filmic.
- **Portrait + sigmoid?** → keep skew = 0 (avoids harsh skin transitions).
- **Two display transforms?** → never. filmic OR sigmoid OR base curve, one only.

## Demosaic picker
| Situation | Algorithm |
|---|---|
| general | RCD (default) |
| max detail / stars | AMaZE (slow) |
| high-ISO / moiré | LMMSE |

## darktable-cli quick refs
- Single look-check: `darktable-cli in.NEF out.jpg --width 1600 --core --configdir TMP --library :memory:`
- Batch w/ style: `darktable-cli RAWDIR OUTDIR --out-ext .jpg --style NAME --core --configdir TMP --library TMP/l.db`
- JPEG quality: append `--core --conf plugins/imageio/format/jpeg/quality=92`
- **ALWAYS isolate `--configdir`/`--library` if a GUI may be open** (library lock = instant exit).
- Force sidecar write: `--conf write_sidecar_files=TRUE`.

## XMP edit boundary (tells & smells)
- Safe to script: `enabled`, `operation`, module order, `xmp:Rating`.
- DO NOT touch: `params=` (hex blob), `blendop_params=` (gzip+base64) → use `.dtstyle` or sidecar-copy.
- Apply edits 3 ways: GUI style (`--style`), copy a good `.NEF.xmp`, or copy-paste history in lighttable.

## Defaults to verify (preferences → processing)
- pixel workflow = **scene-referred (filmic)**
- chromatic adaptation = **modern**
- working space = Rec 2020; output = sRGB (web) / AdobeRGB (print)
- OpenCL on (off only to debug crashes)

## Performance tells
- Export crawling? → tiling (memory-starved), up to 10× slower → free RAM / enable OpenCL.
- Crash at startup? → `--disable-opencl` (broken driver).

## filmic look-view warnings
- Red dot → linear part too far → reduce latitude / recenter shadows↔highlights balance.
- Half-circle dot → contrast too low for DR → raise contrast or scene DR.

## Culling keys (lighttable)
`0`–`5` rating · `R` reject · `F1`–`F5` color label · copy history → select → paste · create style → apply.
