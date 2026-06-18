# Chapter 4: Highlights & RAW Recovery

## Core Idea
Clipped highlights lose color (and possibly luminance) information; darktable recovers them at two stages: `highlight reconstruction` (early, pre-demosaic, RAW-level) and `color reconstruction` / filmic's reconstruct tab (later, color-level). Clipped data is *estimated/disguised*, never magically restored — capture (ETTR without clipping) matters most.

## Frameworks Introduced

- **highlight reconstruction** (8.2.36) — operates on RAW data *before demosaic* (cannot be moved). Uses the camera **white point** to decide what's clipped; a wrong white point clips valid pixels. Methods:
  - **inpaint opposed** (default): averages adjacent unclipped pixels. Good general default; can fail where clipped areas border a different color.
  - **segmentation based**: treats each clipped region as a segment, estimates from adjacent color ratios; can rebuild large all-channel-clipped areas by gradient analysis. Think "plausibly disguise," not "repair."
  - **guided laplacians**: diffusion-based, replicates detail from valid channels; for spotlights/specular reflections; Bayer only; compute-heavy. Tune `iterations` up if magenta remains; `diameter` ≈ 2× largest clipped area; `noise level` to blend with high-ISO grain; `inpaint a flat color` as a magenta-recovery booster (use cautiously — can bleed sky/leaves into clouds).
  - **clip highlights**: clamp all channels to white. Best for naturally desaturated clipped objects (clouds).
  - **reconstruct in LCh**: monochrome but brighter/more detailed than clip; good for desaturated objects.
  - **reconstruct color**: transfers color from unclipped surroundings; excellent on homogeneous areas and **skin tones with fading highlights**; can produce maze artifacts behind high-contrast edges.
  - `clipping threshold`: pixels above = clipped; the eye icon shows the clipping mask — match it to the RAW overexposed warning.

- **color reconstruction** (8.2.16) — later module, heals blown highlights by borrowing neighbor colors above a luminance `threshold`:
  - `threshold` has a sweet spot: too high = no effect, too low = no replacement pool.
  - `spatial extent` / `range extent`: how far (space / luminance) source pixels may be — higher = more candidates but riskier fit.
  - `precedence` = off / saturated colors / **hue** — set a preferred hue (e.g. skin) so adjacent textiles/hair don't bleed in.
  - Display-only artifacts when zoomed in (magenta shift); tune at full zoom-out — output is unaffected.
  - Note: similar functionality lives in filmic rgb's reconstruct tab.

## Key Concepts
- **Clipping**: photosite saturation OR digital clipping (RAW storage limit) — these often differ per camera; the white point bridges them.
- **Pink/magenta highlights**: caused by white balance amplifying a partially-clipped channel (e.g. only G clipped) — the canonical thing reconstruction fixes.
- **Two-stage recovery**: highlight reconstruction (RAW, pre-demosaic) → filmic reconstruct / color reconstruction (color, late).
- **Order is fixed**: highlight reconstruction → demosaic → input color profile. None can be reordered.

## Anti-patterns
- **clip highlights mode + filmic's own reconstruction**: starves filmic of data — prefer a non-clip method so filmic has more to work with.
- **Tuning color reconstruction zoomed in**: you'll chase display-only magenta artifacts that aren't in the output.
- **Expecting reconstruction to "repair" large blown areas**: it disguises plausibly; segmentation/laplacians fabricate, they don't recover lost data.
- **Wrong camera white point**: silently clips valid pixels and undermines every method.

## Reference Tables

| Clipped subject | Best method |
|---|---|
| General / mixed | inpaint opposed (default) |
| Clouds, desaturated objects | clip highlights or reconstruct in LCh |
| Skin tones, smooth highlights | reconstruct color (or color reconstruction, precedence=hue on skin) |
| Spotlights, specular reflections | guided laplacians (Bayer) |
| Large all-channel-blown regions | segmentation based |

## Worked Example — the communion frame's blown window/garden
The garden behind the subjects is blown (pure white, top-right). Strategy:
1. **highlight reconstruction**: keep default *inpaint opposed* (the window is large but bordered by varied color — segmentation may over-fabricate). Toggle the clipping-mask eye to confirm the threshold matches the overexposed warning.
2. The white dress edges risk pink-highlight artifacts — *inpaint opposed* or *reconstruct color* keeps them white rather than magenta.
3. **filmic rgb → reconstruct tab**: blend the recovered window smoothly into the displayable range (rather than clip-mode, so filmic keeps the data).
4. Don't expect garden *detail* back — accept a clean white-with-gradient window; the subjects are the point.

## Key Takeaways
1. Highlight reconstruction is RAW-level (pre-demosaic, fixed position); color/ filmic reconstruct is color-level and later.
2. inpaint opposed is the right default; switch method by subject (clouds→clip/LCh, skin→reconstruct color, spotlights→laplacians).
3. Verify the clipping mask matches the overexposed warning — a wrong white point breaks everything.
4. Recovery disguises, it doesn't restore — ETTR-without-clipping in-camera beats any module.
5. Avoid clip-highlights when filmic will also reconstruct — give filmic the data.
6. Tune color reconstruction at full zoom-out; zoomed-in magenta is display-only.

## Connects To
- **Ch 1**: highlight reconstruction's fixed position in the pre-demosaic pipeline.
- **Ch 2**: filmic rgb reconstruct tab — the late-stage partner to this module.
- **Ch 5 (detail)**: demosaic immediately follows highlight reconstruction.
- **Ch 3 (color)**: white balance amplifying partial clips is what produces the magenta this fixes.
