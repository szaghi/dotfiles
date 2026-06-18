# Chapter 1: Scene-Referred Workflow & the Pixelpipe

## Core Idea
darktable 4.6 processes images **scene-referred** by default: it keeps RAW data on an unbounded linear scale proportional to scene light, doing nearly all edits in linear RGB, and only compresses to the display's dynamic range at the very end (via filmic rgb / sigmoid). This is more physically realistic and artifact-resistant than the legacy display-referred approach, but it requires discarding old habits (tone curves, levels operate on now-invalid black/white/gray definitions).

## Frameworks Introduced

- **Scene-referred vs display-referred**: the single most important distinction in modern darktable.
  - Display-referred (legacy): RAW is compressed early to [0=black, 1=white, 0.5=gray]; a tone curve is applied irreversibly and all later edits build on already-mangled data. Cause of the "HDR look" — early loss of the luminosity↔saturation relationship plus hue shifts.
  - Scene-referred (default since 3.6): data stays linear & unbounded; tone mapping happens late. Enables `exposure` + `filmic rgb` by default on new images.
  - When to use: always, for RAW. Display-referred is legacy-only.

- **"Image processing in 3 modules"** — the canonical scene-referred starting recipe:
  1. **Set mid-gray brightness** with `exposure` slider — purely artistic intent. Don't worry if highlights blow here; recovered next.
  2. **Set white & black points** in `filmic rgb` *scene* tab (white/black relative exposure) — technical, relative to the mid-gray from step 1. Use the pickers on max/min brightness.
  3. **Set contrast** in `filmic rgb` *look* tab — contrast slider = slope of the straight mid-tone section; latitude = its length; shadows/highlights balance = its position. Give-and-take: more mid-tone contrast costs shadow/highlight contrast.
  - Then: **color preservation** (filmic *options* → preserve chrominance) and **saturation** (`color balance rgb`, "basic colorfulness" preset).
  - When to use: every RAW, as the foundation before corrections and creative work.

- **Order of work**: basics (3 modules) → corrections (lens, CA, color calibration, denoise) → creative adjustments. Always this sequence.

## Key Concepts
- **Pixelpipe**: the ordered module sequence. Executes **bottom→top** of the right-hand module list (RAW at the bottom). UI order = execution order.
- **Module order (iop_order)**: `v3.0` is the scene-referred default; `legacy` is display-referred. Set via the *module order* module; custom presets possible. `v3.0` for JPEG/non-RAW.
- **History stack**: records edits in the order *amended* (NOT execution order). Persisted to library DB **and the XMP sidecar**. `Ctrl+Z`/`Ctrl+Y` undo/redo (unlimited per-image, reset on image switch).
- **Color assessment mode** (`Ctrl+B`): surrounds image with a white frame on mid-gray background — the controlled environment for judging tone/color. Use a grey theme.
- **Why RAW ≠ JPEG**: darkroom shows the (mostly unprocessed) linear RAW; lighttable initially shows the in-camera JPEG preview. darktable defaults give a *neutral starting point*, by design — it will not mimic camera JPEGs.

## Mental Models
- Think of modules as a **stack of building blocks**, each building on the output of the one below (analogous to Photoshop adjustment layers).
- Think scene-referred as **"edit the light, then map to the display last"** — keep operations linear as long as possible (everything up to & including filmic rgb).
- The pixelpipe order is **load-bearing and pre-tuned**; reordering usually *worsens* output. Some early modules (highlight reconstruction → demosaic → input color profile) are physically constrained and cannot be moved.

## Anti-patterns
- **Using tone curve / levels in scene-referred mode**: they assume display-referred black/white/gray and are no longer the right tool. Use exposure + filmic instead.
- **Reordering the pixelpipe casually**: only experienced users, only specific cases (`Ctrl+Shift`+drag). Highlight reconstruction *must* precede demosaic; can't be moved.
- **Using black level correction to deepen blacks**: clips near-black out of gamut (negative RGB) and breaks downstream modules. Add black density via filmic's *relative black exposure* or a tone-curve toe instead.

## Reference Tables

| Pipeline section | Data | Modules (examples) |
|---|---|---|
| Scene-referred (linear) | proportional to scene light, unbounded DR | exposure, color calibration, denoise, lens, **filmic rgb** |
| Tone-mapping boundary | non-linear compression to display DR | filmic rgb / sigmoid / base curve |
| Display-referred (after) | bounded, perceptual | output color profile, some effects |

## Worked Example — developing a high-DR event frame (the communion case)
Scene: subjects indoors, bright sunlit garden through a window → highlights at risk, faces well-lit, shadows have headroom.
1. `Ctrl+B` color assessment on. Zoom out.
2. **exposure**: set mid-gray for the faces (artistic). Accept that the garden/white dress blow — recover next.
3. **filmic rgb → scene**: pick *white relative exposure* on the brightest retained highlight (dress/cloud), *black relative exposure* on deepest shadow. This pulls the blown background back into displayable range.
4. **filmic rgb → look**: modest contrast; nudge *shadows/highlights balance* toward highlights to protect the dress detail.
5. **filmic rgb → options**: if skin hue drifts, change *preserve chrominance*.
6. **color balance rgb**: "basic colorfulness" for saturation; slight warmth for skin.
7. Optionally **tone equalizer** to pull down only the window/sky region.
`Ctrl+B` off. Export.

## Key Takeaways
1. Scene-referred is the default and the right choice for RAW — keep edits linear up to filmic rgb.
2. The "3 modules" (exposure → filmic white/black → filmic contrast) get you 80% there on most images.
3. Pixelpipe executes bottom→top; UI order *is* execution order; don't reorder without reason.
4. Highlights blown after exposure are *expected* — filmic recovers them. Don't fix exposure to protect highlights.
5. The history stack lives in the XMP sidecar — edits are non-destructive and portable.
6. Use color assessment mode (`Ctrl+B`) + a grey theme to judge tone honestly.

## Connects To
- **Ch 2 (exposure & tone)**: exposure, filmic rgb, sigmoid, tone equalizer — the modules this workflow drives.
- **Ch 4 (highlights & raw recovery)**: highlight reconstruction (pre-demosaic) + filmic's reconstruct tab.
- **Ch 3 (color)**: color calibration (CAT white balance), color balance rgb (saturation).
- **Ch 10 (darktable-cli)**: the XMP history stack is exactly what `--style` and sidecar-copy manipulate for batch work.
