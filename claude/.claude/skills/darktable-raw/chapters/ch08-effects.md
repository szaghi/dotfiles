# Chapter 8: Creative Effects & Finishing

## Core Idea
After basics + corrections, optional creative/finishing modules add atmosphere: `retouch` (frequency-separation healing), `liquify`, `color zones` (selective HSL), `graduated density`, `vignetting` via `framing`/effects, `monochrome`/B&W, `grain`, `split-toning`, `velvia`/`color balance rgb` saturation. Apply last.

## Frameworks Introduced

- **retouch** (8.2.55): heal/clone/blur/fill with **wavelet frequency separation** — operate on detail scales independently (e.g. smooth skin texture at one scale while keeping pores at another). Sources from anywhere in the (uncropped) image.
- **color zones** (8.2.17): selectively adjust lightness/chroma/hue based on current lightness/chroma/hue — the HSL-style targeted color tool (e.g. shift only the foliage green, desaturate only skin).
- **liquify** (8.2.43): push/warp pixels (points, curves, strokes).
- **graduated density** (8.2.33): ND-grad simulation (darken sky).
- **monochrome** / **color calibration gray tab**: B&W conversion (calibration's channel mixer is the better path).
- **grain** (8.2.34), **split-toning** (8.2.66), **soften**/**bloom** (dreamy glow), **vignetting** (via framing/effects).
- **censorize** (8.2.6): pixelate/blur for privacy (faces, plates).
- **watermark**, **framing** (8.2.31): borders/overlays for output.

## Key Concepts
- **Finishing order**: creative effects come after exposure/color/corrections — they assume a developed image.
- **frequency separation** (retouch): the professional skin-retouching technique, built in.
- **color zones vs color balance rgb**: color zones = targeted HSL by existing color; color balance rgb = tonal-range (shadow/mid/highlight) grading.

## Anti-patterns
- **Heavy creative effects before tone/color basics**: you're decorating an undeveloped image; redo later.
- **Skin smoothing with blur instead of retouch frequency separation**: kills texture; use the wavelet scales.
- **Global saturation to fix one color**: use color zones for targeted hue/chroma.

## Reference Tables

| Effect | Module |
|---|---|
| Heal blemishes / skin | retouch (frequency separation) |
| Targeted color (one hue) | color zones |
| Darken sky gradient | graduated density |
| B&W | color calibration (gray) / monochrome |
| Film grain / toning | grain / split-toning |
| Privacy blur | censorize |
| Border / watermark | framing / watermark |

## Key Takeaways
1. Creative effects apply last, on a developed image.
2. retouch does frequency-separation healing — the right tool for skin and blemishes.
3. color zones for targeted HSL; color balance rgb for tonal-range grading.
4. B&W via color calibration's gray channel mixer beats the monochrome module.

## Connects To
- **Ch 3**: color balance rgb / color zones for color work; calibration gray tab for B&W.
- **Ch 6 (masking)**: most effects benefit from masks to localize them.
- **Ch 2**: effects assume tone is already set by exposure + filmic.
