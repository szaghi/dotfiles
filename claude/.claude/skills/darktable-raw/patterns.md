# Patterns — darktable 4.6 RAW Workflow

## The Scene-Referred Basic Develop ("3 modules")
**When to use**: every RAW, as the foundation.
**How**: 1) exposure → set mid-gray (artistic). 2) filmic rgb scene tab → white/black relative exposure (pickers on brightest/darkest retained tones). 3) filmic look tab → contrast/latitude. Then color balance rgb "basic colorfulness" for saturation.
**Trade-offs**: filmic compresses local contrast (recover with local contrast); never pair with a second display transform.

## High-DR Recovery (bright background, dim subjects)
**When to use**: blown windows/sky behind well-lit subjects (the communion case).
**How**: exposure for the subject (let bg blow) → filmic scene white-point on the brightest *retained* highlight → filmic reconstruct tab to blend clipped areas → tone equalizer (eigf mask) to pull down only the bright region.
**Trade-offs**: detail in fully-blown areas is fabricated, not recovered; accept clean white.

## Consistent Series Look (batch event)
**When to use**: many frames from one shoot needing a uniform look.
**How**: develop one reference image → save as a style (or keep its `.xmp`) → apply via lighttable copy-paste, `--style`, or sidecar-copy. Use exposure area-mapping (or automatic mode) to equalize brightness across frames.
**Trade-offs**: light varies shot-to-shot; expect per-image exposure fine-tuning even with a shared style.

## Headless Batch Export (darktable-cli)
**When to use**: render a whole folder without the GUI.
**How**: `darktable-cli RAWDIR OUTDIR --out-ext .jpg --width N --style NAME --core --configdir ISOLATED --library ISOLATED/l.db --conf plugins/imageio/format/jpeg/quality=92`.
**Trade-offs**: must isolate config/library if a GUI is open (library lock); verify outputs exist + exit 0 + visual spot-check.

## Edit-and-Look Iteration Loop
**When to use**: any time precise visual judgment is needed (i.e. always).
**How**: export a small JPEG (`--width 1600`, `:memory:` library) → read it visually → adjust → re-export. Don't tune blind.
**Trade-offs**: `:memory:` writes no sidecar; use a temp library if you need the XMP.

## Mixed-Light White Balance
**When to use**: two light sources in one frame.
**How**: color calibration instance #1 (global), masked to exclude region B; instance #2 reusing the inverted raster mask, set for region B's illuminant.
**Trade-offs**: requires identifiable neutral references per region.

## Local Tonal Adjustment
**When to use**: darken/brighten one region (sky, window, face).
**How**: tone equalizer with eigf guided mask (zone-based), or any module + drawn/parametric mask.
**Trade-offs**: spread the mask histogram across control points for independent control.

## Edit-as-Data Manipulation (the honest boundary)
**When to use**: programmatic/batch edit application.
**How**: legible XMP attributes (`enabled`, `operation`, ordering, `xmp:Rating`) are safe to read/script. Module `params`/`blendop_params` are packed (hex / gzip+base64) — NEVER hand-edit. Apply edits via GUI-authored `.dtstyle` or by copying a known-good sidecar.
**Trade-offs**: full programmatic control of arbitrary params is not available; styles + sidecar-copy are the robust primitives.

## Noisy / High-ISO Pipeline
**When to use**: high-ISO files.
**How**: demosaic = LMMSE → denoise (profiled, wavelets, separate luma/chroma) early → then filmic (auto-tuners now read clean blacks).
**Trade-offs**: AMaZE overshoots on noise; denoise before filmic auto-tuners is required.
