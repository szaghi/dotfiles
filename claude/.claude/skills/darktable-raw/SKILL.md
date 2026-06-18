---
name: darktable-raw
description: "Knowledge base from the darktable 4.6 user manual. Use when developing RAW photos (NEF/CR2/etc.) in darktable, driving darktable-cli for headless/batch export, reasoning about the scene-referred pixelpipe, modules (exposure, filmic rgb, color calibration, highlight reconstruction, tone equalizer), masking/blending, styles & XMP sidecars, or color management. Version-matched to darktable 4.6."
allowed-tools:
  - Read
  - Grep
  - Bash
argument-hint: [module name, topic, or chapter number]
---

# darktable 4.6 RAW Processing
**Source**: darktable 4.6 user manual (~318 pp) | **Chapters**: 12 (curated functional) | **Generated**: 2026-06-16

## How to Use This Skill
- **No args** — load the core frameworks below.
- **Topic/module** — ask about `filmic`, `highlight reconstruction`, `darktable-cli`, `masking`; I read the relevant chapter.
- **Chapter** — ask for `ch02`; I load it.
- Chapters are loaded on demand; only this file is always in context.

---

## Core Frameworks & Mental Models

**Scene-referred is the default and the right choice for RAW.** Keep edits in linear, unbounded scene-light space as long as possible; compress to the display only at the end via *one* display transform (filmic rgb or sigmoid). Tone curves/levels assume the legacy display-referred model and are deprecated here. (Ch 1)

**The pixelpipe executes bottom→top of the right-hand module list; UI order = execution order.** Some early modules are position-locked: highlight reconstruction → demosaic → input color profile. Don't reorder without a specific reason. (Ch 1)

**The "3 modules" basic develop** gets ~80% of most images:
1. **exposure** → set mid-gray (artistic; let highlights blow, recovered next).
2. **filmic rgb** scene tab → white/black relative exposure (pickers on brightest/darkest retained tones).
3. **filmic rgb** look tab → contrast + latitude.
Then **color balance rgb** ("basic colorfulness") for saturation. Develop order overall: **basics → corrections → creative → crop**. (Ch 1, 2)

**Tone**: exposure sets mid-gray; filmic/sigmoid maps dynamic range to the display. Exactly one display transform. For portraits with sigmoid, keep skew = 0. **tone equalizer** (eigf guided mask) is the modern, local-contrast-safe dodge/burn — the tool for pulling down a bright window/sky. (Ch 2)

**Color** splits primary (neutralize illuminant — **color calibration** CAT, illuminant = as-shot) vs secondary (creative — **color balance rgb**). A neutral primary grade makes the secondary grade portable across a whole series via styles. (Ch 3)

**Highlights**: clipped data is estimated/disguised, never restored. **highlight reconstruction** (pre-demosaic) method by subject — inpaint opposed (default), clip/LCh (clouds), reconstruct color (skin), guided laplacians (spotlights). filmic's reconstruct tab is the late-stage partner. (Ch 4)

**Edits are data, with a hard boundary.** The history stack lives in the XMP sidecar (`<file>.NEF.xmp`). Legible/scriptable: `enabled`, `operation`, module order, `xmp:Rating`. **Packed and NOT hand-editable**: `params=` (hex), `blendop_params=` (gzip+base64). Apply edits via GUI-authored **`.dtstyle`** (`darktable-cli --style`), by copying a known-good sidecar, or lighttable copy-paste. (Ch 9, 10)

**Headless batch** via `darktable-cli`: applies a style or `<xmp>` sidecar to RAW input, no GUI. **Always isolate `--core --configdir`/`--library` when a GUI might be open** — the library lock terminates a second instance instantly. Verify outputs exist + exit 0 + a visual spot-check; silent no-ops look like success. (Ch 10)

**Verify by looking.** Export a small JPEG and read it; never tune blind. This is the core iteration loop. (patterns.md)

---

## Chapter Index

| # | Title | Key topics |
|---|-------|-----------|
| [ch01](chapters/ch01-workflow-pipeline.md) | Workflow & Pixelpipe | scene-referred, 3-modules, history stack, module order |
| [ch02](chapters/ch02-exposure-tone.md) | Exposure & Tone | exposure, filmic rgb, sigmoid, tone equalizer, area mapping |
| [ch03](chapters/ch03-color.md) | Color | color calibration CAT, color balance rgb, primary/secondary |
| [ch04](chapters/ch04-highlights-recovery.md) | Highlights & Recovery | highlight reconstruction, color reconstruction |
| [ch05](chapters/ch05-detail-denoise-sharpen.md) | Detail | demosaic, denoise profiled, local contrast, diffuse/sharpen |
| [ch06](chapters/ch06-masking-blending.md) | Masking & Blending | drawn/parametric/raster masks, blend modes |
| [ch07](chapters/ch07-corrections.md) | Corrections | lens correction, rotate & perspective, crop |
| [ch08](chapters/ch08-effects.md) | Creative Effects | retouch, color zones, grain, B&W, framing |
| [ch09](chapters/ch09-lighttable-culling.md) | Lighttable | culling, rating, styles, history copy-paste |
| [ch10](chapters/ch10-darktable-cli.md) | darktable-cli & Batch | invocation, variables, XMP, library lock |
| [ch11](chapters/ch11-preferences-performance.md) | Preferences & Performance | color management, OpenCL, tiling, defaults |
| [ch12](chapters/ch12-deprecated-modules.md) | Deprecated Modules | warn-off index + replacements |

## Topic Index
- **area exposure mapping** → ch02
- **batch / series** → ch02, ch09, ch10
- **color balance rgb** → ch03
- **color calibration / white balance** → ch03
- **darktable-cli** → ch10
- **demosaic** → ch05
- **denoise** → ch05
- **deprecated modules** → ch12
- **exposure** → ch02
- **filmic rgb** → ch02
- **highlight reconstruction / clipping** → ch04
- **lens correction / crop / perspective** → ch07
- **local contrast** → ch02, ch05
- **masking / blending** → ch06
- **OpenCL / performance / memory** → ch11
- **pixelpipe / module order** → ch01
- **rating / culling** → ch09
- **retouch / color zones / effects** → ch08
- **scene-referred** → ch01
- **sigmoid** → ch02
- **styles / .dtstyle** → ch09, ch10
- **tone equalizer** → ch02
- **XMP sidecar / history stack** → ch01, ch10

## Supporting Files
- [glossary.md](glossary.md) — terms with chapter refs
- [patterns.md](patterns.md) — reusable workflows (basic develop, high-DR recovery, batch, mixed-light)
- [cheatsheet.md](cheatsheet.md) — decision rules, darktable-cli refs, XMP boundary, defaults

---

## Scope & Limits
Covers the darktable 4.6 manual. Version-pinned: module names/params match 4.6 — verify before assuming for other versions. This is the **knowledge layer**; an operator/workflow skill (the export-and-look loop, shoot-specific tuning, batch scripts) is a separate companion. For RAW capture metadata, use `exiftool`. The skill can run `darktable-cli` (Bash) but must isolate config/library per ch10.
