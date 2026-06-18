# Chapter 3: Color — White Balance, Calibration & Grading

## Core Idea
Color work splits in two: **primary** (neutralize the illuminant — `color calibration` CAT, working with `white balance`) and **secondary** (creative grading — `color balance rgb`). Doing primary truly neutral makes secondary transferable across a series via styles/presets/copy-paste. Both operate scene-referred, linear.

## Frameworks Introduced

- **Primary vs secondary color-grading** (the organizing split):
  - *Primary* → `color calibration` CAT tab: fix illuminant/cast, neutral starting point.
  - *Secondary* → `color balance rgb`: atmosphere, look, harmonizing a series.

- **color calibration** (8.2.11) — CAT (Chromatic Adaptation Transformation) white balance, channel mixer, saturation, B&W, color-checker calibration:
  - **CAT vs white balance**: white balance only makes grays neutral (R=G=B) — a *partial* adaptation. CAT predicts how all surfaces would look under the monitor's illuminant — full adaptation. The `white balance` module still runs ("camera reference"/D65 flat setting) to feed demosaic + input profile; CAT does the perceptual work on top.
  - Enable via *preferences → processing → auto-apply chromatic adaptation defaults = 'modern'* (vs 'legacy' = all WB in white balance module).
  - **Illuminant detection** (CAT tab):
    - *as shot in camera* — Exif WB (default, usually sufficient).
    - *color picker on neutral patch* — gray-world assumption; fails on artificial/painted scenes.
    - *(AI) detect from surfaces* — finds should-be-gray patches; immune to noise & legit non-gray surfaces; fails on sharp colored textures (grass).
    - *(AI) detect from edges* — gray-edge assumption; good for artificial scenes with no neutrals; noise-sensitive, bad for high-ISO.
  - **adaptation** space: **CAT16 (2016)** = default, robust against imaginary colors; Linear Bradford = ICC-v4-compatible, daylight-accurate; XYZ = debug only.
  - **CCT tags**: `(daylight)`/`(black body)` → CCT meaningful, use D or Planckian illuminant; `(invalid)` → too far from either spectrum, use *custom* illuminant (nothing to worry about, just don't trust the kelvin number).
  - **Masked** (unlike white balance): two instances + inverted raster mask handle mixed light sources in one frame.

- **color balance rgb** (8.2.10) — secondary grading, an improvement on ASC CDL with shadow/mid/highlight alpha masks:
  - `global vibrance` — chroma boost prioritizing low-chroma colors (won't over-saturate already-colorful pixels). Beginner-safe.
  - `global chroma` / `global saturation` — linear chroma grading / perceptual saturation grading, constant hue.
  - `hue shift` — rotate all hues at constant luminance/chroma; best applied with a mask.
  - `contrast` — luminance contrast around the **gray fulcrum** (18.45% default). Increases DR → can void filmic; prefer `tone equalizer` for global contrast, use this with masks for selective fg/bg.
  - "basic colorfulness" preset = good default saturation after filmic.
  - Works in a color-grading linear RGB (uniform perceptual hue, physical luminance); perceptual parts in JzAzBz. Soft-clips out-of-gamut at constant hue at output.

## Key Concepts
- **dimensions of color**: chroma vs saturation have precise CIE definitions here — color balance rgb honors them (unlike older modules).
- **vectorscope**: the scope to use when grading / harmonizing a series.
- **white balance module**: keep enabled, normally don't touch in modern workflow — it's the technical pre-step for CAT.
- **Standard matrix assumption**: color calibration defaults assume the input color profile uses the standard matrix — custom matrices there are discouraged.

## Anti-patterns
- **Custom matrix in input color profile + color calibration CAT**: breaks CAT's assumptions; defaults ignore non-standard settings.
- **Using color balance rgb contrast for global contrast**: voids filmic, inflates DR — use tone equalizer globally, color balance rgb contrast only masked.
- **Trusting CCT when tagged `(invalid)`**: the kelvin is meaningless there — switch to custom illuminant.
- **edge-detection illuminant on high-ISO/noisy event shots**: noise-sensitive — prefer surfaces or as-shot.

## Reference Tables

| Task | Module | Control |
|---|---|---|
| Neutralize cast (most shots) | color calibration | CAT, illuminant = as shot |
| Mixed light sources in frame | color calibration | 2 instances + inverted raster mask |
| Add saturation post-filmic | color balance rgb | global vibrance / saturation, "basic colorfulness" |
| Creative grade / film look | color balance rgb | 4-ways (shadows/mid/highlights) |
| Harmonize a series | color balance rgb | copy style across images; use vectorscope |
| Channel mixer / B&W | color calibration | gray tab / RGB output channels |

## Worked Example — warm, consistent skin across the communion series
1. **color calibration CAT**: leave illuminant *as shot in camera* (D610 Exif WB was Auto1 — usually fine indoors). If skin looks cool, pick a neutral (the white dress edge, if truly neutral) or nudge the temperature warmer.
2. **color balance rgb → master**: small `global vibrance` to lift the teal dress and skin without clipping; "basic colorfulness" preset baseline.
3. **color balance rgb → 4-ways**: faint warm push in mid-tones for skin; keep highlights neutral so the white dress stays white.
4. Once this looks right on the reference frame, **save as a style** and apply to the rest of the series — because primary grading was left neutral (as-shot), the secondary grade transfers cleanly.

## Key Takeaways
1. Primary (color calibration CAT) then secondary (color balance rgb) — neutral primary makes secondary portable across a series.
2. color calibration CAT is the modern, perceptually-accurate WB; the white balance module stays on as its technical pre-step.
3. Default illuminant = as-shot; escalate to AI-surfaces (not edges) for tricky artificial light; ignore `(invalid)` CCT and use custom.
4. color balance rgb global vibrance/saturation is the safe post-filmic saturation; its contrast is for masked selective use only.
5. color calibration can be masked for mixed-light scenes; white balance cannot.
6. A clean neutral primary grade is what makes a one-style batch look work.

## Connects To
- **Ch 2**: color balance rgb saturation/contrast follow filmic; filmic auto-tuners need accurate WB.
- **Ch 6 (masking)**: raster masks for two-instance mixed-light correction; masked hue shift / contrast.
- **Ch 10 (darktable-cli)**: styles carry the secondary grade for batch application across the series.
- **Ch 12 (deprecated)**: the old "color balance" and "channel mixer" modules superseded here.
