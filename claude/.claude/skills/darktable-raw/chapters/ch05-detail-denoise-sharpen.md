# Chapter 5: Detail — Demosaic, Denoise, Sharpen, Diffuse

## Core Idea
Detail rendering starts at `demosaic` (reconstructs color from the Bayer mosaic — the base for everything), then noise is controlled by `denoise (profiled)` (camera-profiled), and acuity by `local contrast`, `sharpen`, and the physics-based `diffuse or sharpen`. In scene-referred workflow, denoise belongs early (before filmic's auto-tuners on noisy files).

## Frameworks Introduced

- **demosaic** (8.2.24) — interpolates the single-color Bayer photosites into full RGB. Choice affects fine-detail quality, moiré, colored edges.
  - **RCD** = default (PPG-quality speed, better results).
  - **AMaZE**: best high-frequency detail/edges/stars, but color overshoots & slowest.
  - **LMMSE**: best for high-ISO/noisy and moiré-prone images (less overshoot).
  - **VNG4**: low-frequency content (sky); loses high-freq detail; no longer recommended.
  - X-Trans sensors: **Markesteijn 1-pass** default, 3-pass for quality.
  - `passthrough (monochrome)` for CFA-removed sensors; `photosite_color` for debug only.

- **denoise (profiled)** (8.2.25) — uses per-camera noise profiles (300+ models) so smoothing tracks luminosity-dependent variance.
  - **wavelets** (default): wavelet-domain, lighter weight, Y0U0V0 (separate luma/chroma) or RGB modes.
  - **non-local means**: spatial-domain patch averaging, resource-intensive.
  - Both have auto + manual modes. Separate **luma vs chroma** control is the key lever (chroma noise = color blotches, luma = grain).

- **local contrast** (8.2.44) — enhances local contrast on the Lab L channel. **local laplacian** (default, halo-robust) or **bilateral grid**. Use to recover the local contrast that filmic compresses.

- **diffuse or sharpen** (8.2.26) — physics-based diffusion model; preset-driven. Reverses/simulates diffusion:
  - *sharpen demosaicing* presets (move before input color profile) — undo demosaic blur.
  - *lens deblur* — reverse static defocus (not motion blur — non-diffusive, unrecoverable).
  - *dehaze* — atmospheric haze.
  - *local contrast / add acutance* — legibility.

## Key Concepts
- **Bayer array**: each photosite records one of R/G/B; demosaic reconstructs the other two by interpolation.
- **Moiré / maze artifacts**: demosaic-algorithm-dependent — VNG4/LMMSE more stable against them.
- **Order on noisy files**: denoise early so filmic's luminance/black readings are accurate.
- **sharpen** (8.2.63): classic unsharp-mask; `diffuse or sharpen` is the modern, more capable alternative.

## Anti-patterns
- **AMaZE on high-ISO noisy images**: overshoot artifacts — use LMMSE.
- **Skipping denoise before filmic auto-tuners on noisy files**: corrupts black-exposure readings.
- **Expecting diffuse-or-sharpen to fix motion blur**: motion blur isn't diffusive; can't be undone.
- **Over-sharpening after filmic without recovering local contrast first**: filmic already compressed it.

## Reference Tables

| Image type | demosaic |
|---|---|
| General | RCD (default) |
| Max fine detail / stars | AMaZE (slow) |
| High-ISO / noisy / moiré | LMMSE |
| Low-contrast (sky-dominant) | (RCD; VNG4 deprecated) |

| Need | Module |
|---|---|
| Reduce grain (luma) | denoise (profiled), wavelets, luma |
| Reduce color blotches (chroma) | denoise (profiled), chroma |
| Recover local contrast post-filmic | local contrast (local laplacian) |
| Acutance / dehaze / deblur | diffuse or sharpen (preset) |

## Key Takeaways
1. RCD is the default demosaic; switch to LMMSE for high-ISO/moiré, AMaZE only when you need max detail and can pay the time.
2. denoise (profiled), wavelets mode, separate luma/chroma — the standard noise tool; run it early on noisy files.
3. local contrast (local laplacian) recovers what filmic compresses — pair them.
4. diffuse or sharpen is preset-driven and physics-based; it can't undo motion blur.

## Connects To
- **Ch 4**: highlight reconstruction runs immediately before demosaic.
- **Ch 2**: local contrast compensates filmic's compression; denoise feeds filmic auto-tuners.
- **Ch 1**: demosaic is fixed early in the pipeline (after highlight reconstruction, before input color profile).
