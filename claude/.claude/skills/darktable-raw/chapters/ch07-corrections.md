# Chapter 7: Geometric & Optical Corrections

## Core Idea
Optical/geometric fixes: `lens correction` (distortion, TCA, vignetting — automatic via lensfun or embedded metadata), `rotate and perspective` (leveling + converging-line correction), and `crop` (final creative framing, late in pipeline). Corrections come *after* basics, *before* creative work.

## Frameworks Introduced

- **lens correction** (8.2.41): corrects (or simulates) distortion, transverse CA (TCA), vignetting.
  - *correction method*: **Lensfun database** (lens profiles) / **embedded metadata** (if present in RAW) / **only manual vignette**.
  - If lensfun lacks your camera+lens combo → warning; search manually, or fix lens ID via exiv2 then re-import. Adapted lenses need `lensfun-add-adapter`; update with `lensfun-update-data`.
  - **Warning**: enabling TCA correction here AND `raw chromatic aberrations` → overcorrection artifacts. Pick one.
  - Note (Ch 1): lens correction can change brightness — enable it *before* setting exposure.

- **rotate and perspective** (8.2.59): leveling + converging-line (keystone) correction (ShiftN-inspired). Perspective controls hidden by default (click "perspective" header). Right-click+drag a line on the image → auto-sets rotation to make it horizontal/vertical. Auto structure detection or manually drawn perspective rectangle / lines, then a fitting procedure. **Use this for rotation, then crop separately.**

- **crop** (8.2.21): final creative crop, on-screen handles. Late in pipeline (so the full image stays available as source for `retouch` spot removal). `Ctrl`/`Shift` constrain drag to axes; commit by focusing another module.

## Key Concepts
- **Correction order**: rotate & perspective (geometry) → crop (framing). The deprecated *crop and rotate* module did both early; the split is intentional and better.
- **raw chromatic aberrations** (8.2.53) / **chromatic aberrations** (8.2.8): CA fixes — don't double up with lens-correction TCA.
- **lensfun**: external library; profile availability is camera+lens-specific.

## Anti-patterns
- **lens-correction TCA + raw chromatic aberrations together**: overcorrection.
- **Setting exposure before lens correction**: lens correction shifts brightness — enable it first.
- **Using deprecated crop-and-rotate**: use rotate-and-perspective + crop instead.

## Reference Tables

| Need | Module |
|---|---|
| Distortion / vignette / TCA | lens correction (lensfun or embedded) |
| Level horizon / fix keystone | rotate and perspective |
| Final framing | crop |
| Lateral CA only | raw chromatic aberrations (not alongside lens TCA) |

## Key Takeaways
1. lens correction = automatic distortion/TCA/vignette; lensfun or embedded metadata; don't combine its TCA with raw CA.
2. Enable lens correction before exposure (it changes brightness).
3. rotate-and-perspective for leveling/keystone (right-click-drag a reference line), then crop for framing.
4. crop is late so retouch can still source from outside the crop.

## Connects To
- **Ch 1**: lens correction before exposure; correction stage sits between basics and creative.
- **Ch 12 (deprecated)**: crop-and-rotate, basic adjustments superseded here.
