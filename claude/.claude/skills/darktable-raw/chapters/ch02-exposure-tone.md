# Chapter 2: Exposure & Tone Mapping

## Core Idea
Tone in scene-referred darktable is set by **exposure** (mid-gray, artistic) followed by exactly **one display transform** — `filmic rgb` (default, full control) **or** `sigmoid` (simpler, film-like) — which compresses scene dynamic range to the display. `tone equalizer` does masked dodge/burn while preserving local contrast. Never stack two display transforms.

## Frameworks Introduced

- **exposure** (8.2.28): overall brightness / mid-gray. Modes:
  - *manual*: `exposure` (EV, ±18 via right-click), `black level correction` (unclip negative RGB — NOT for deepening blacks), `clipping threshold`. *compensate camera exposure* removes Exif bias.
  - *automatic* (RAW only): shifts a chosen `percentile` to a `target level` — for batch-matching exposure / timelapse deflicker.
  - **area exposure mapping**: the batch-consistency tool. Develop one reference image, set a target lightness (L in CIE Lab) on a control sample (gray card / consistent surface), then on each subsequent image pick the same sample → exposure auto-computed to match. Note: needs linear RAW (move after input color profile or use module order v3.0 for JPEG).

- **filmic rgb** (8.2.30): the primary display transform. Five tabs:
  - *scene*: defines scene white/black. `white relative exposure` & `black relative exposure` (set via pickers on brightest/darkest retained tones). `middle-gray luminance` (hidden) acts like brightness — high values protect highlights but fail to recover shadows; low values recover shadows but harshly compress highlights.
  - *reconstruct*: blends/recovers blown highlights (clouds, dress).
  - *look*: artistic S-curve. `contrast` = slope of mid-tone straight section; `latitude` = its length (maximize without clipping extremes); `shadows↔highlights balance` = its position. Give-and-take between mid-tone and shadow/highlight contrast.
  - *display*: output mapping — rarely touched.
  - *options*: `preserve chrominance` modes (fix color shifts); `contrast in shadows/highlights` (soft/hard).
  - When to use: every RAW by default. Compresses local contrast → compensate with `local contrast`, saturation with `color balance rgb`.
  - Near-neutral (not a true no-op): look contrast=1.0, latitude=99%, mid-tones saturation=0%, options contrast soft/soft → pure log tone mapping.

- **sigmoid** (8.2.64): alternative display transform, modified log-logistic curve, pivots around mid-gray. Simpler than filmic.
  - `contrast`: compression aggressiveness (mid-gray fixed). Higher = darker shadows, less DR shown; lower = more DR.
  - `skew`: shift contrast shadows↔highlights. **Keep skew at 0 for portraits** — positive skew causes harsh skin-tone transitions and hue shifts.
  - `color processing`: *per channel* (film-like, smooth highlight roll-off; tune `preserve hue`) or *rgb ratio* (spectral, desaturates bright colors toward gamut). For sunsets/fire, lower hue preservation for a "hotter" look.

- **tone equalizer** (8.2.70): masked dodge & burn in linear RGB, preserves local contrast. Replaces shadows/highlights, tone curve, zone system. Builds a **guided mask** segmenting the image into luminosity zones, then 9 EV-zone sliders (simple tab) or a curve (advanced) raise/lower exposure per zone.
  - *masking tab*: `preserve details` = **eigf** (default, exposure-independent guided filter) — the right default; spread the mask histogram across all control points for max control.

## Key Concepts
- **ETTR** (Expose To The Right): in-camera, expose as bright as possible without clipping — maximizes sensor DR. filmic assumes good input. Clipped data is *irrevocably lost*.
- **One display transform rule**: filmic rgb OR sigmoid OR base curve — never two.
- **Mid-gray = 18%**: filmic always maps scene mid-gray to 18% display (linear).
- **"Less is more"**: do most work in the scene-referred section; don't make the display transform do everything.

## Anti-patterns
- **Two display transforms** (filmic + base curve, or filmic + sigmoid): unpredictable color shifts; chrominance preservation breaks.
- **Positive skew on portraits** (sigmoid): harsh skin-tone transitions + hue drift.
- **base curve / tone curve alongside filmic's chrominance preservation**: defeats it.
- **Overthinking filmic's numbers**: it's a *visual* tool — judge the result, not the GUI quantities.
- **Red/half-circle dots in filmic look view**: red = linear part pushed too far (reduce latitude / recenter with shadows↔highlights balance); half-circle = contrast too low for the DR (increase contrast or scene DR).

## Reference Tables

| Goal | Module + control |
|---|---|
| Set overall brightness | exposure → exposure (EV) |
| Map DR to display | filmic rgb (scene white/black) or sigmoid |
| Recover blown highlights | filmic → reconstruct tab |
| Mid-tone contrast | filmic → look → contrast |
| Selectively darken sky/window | tone equalizer (mask that region) |
| Batch-match exposure across a series | exposure → area exposure mapping (or automatic mode) |
| Faded/analog blacks | color balance rgb global offset (not sigmoid target black) |

## Worked Example — taming the communion frame's blown background
1. **exposure**: raise mid-gray until faces read well (artistic). Background garden blows — fine.
2. **filmic rgb → scene**: `white relative exposure` picker on the brightest cloud/dress highlight you want to *keep*; `black relative exposure` picker on the deepest shadow. This pulls the blown garden back toward displayable white-with-detail.
3. **filmic rgb → reconstruct**: if the window is genuinely clipped, enable reconstruction to blend it smoothly.
4. **filmic rgb → look**: moderate contrast; shadows↔highlights balance nudged toward highlights to protect the white dress.
5. **tone equalizer**: build an eigf mask; pull down the brightest zone(s) (the window/sky) by ~1 EV to recover the exterior without touching the faces.
6. **color balance rgb**: restore saturation; warm the skin slightly.

## Key Takeaways
1. exposure sets mid-gray (artistic); filmic/sigmoid maps DR to display (technical) — in that order.
2. Exactly one display transform. filmic for control, sigmoid for simplicity, skew=0 for portraits.
3. filmic is visual — set white/black with pickers, then contrast/latitude by eye; ignore red/half-circle warnings by adjusting latitude/contrast.
4. tone equalizer (eigf mask) is the modern, local-contrast-safe dodge/burn — ideal for selectively pulling down a bright window/sky.
5. area exposure mapping makes a whole series exposure-consistent from one reference image — directly useful for batch event processing.
6. filmic compresses local contrast — recover with `local contrast`; recover saturation with `color balance rgb`.

## Connects To
- **Ch 1**: the "3 modules" recipe and scene-referred rationale.
- **Ch 4 (highlights)**: filmic reconstruct tab + the pre-demosaic highlight reconstruction module.
- **Ch 3 (color)**: color balance rgb for saturation after filmic; color calibration for WB filmic's auto-tuners rely on.
- **Ch 5 (detail)**: local contrast to recover what filmic compressed; denoise before filmic auto-tuners on noisy files.
