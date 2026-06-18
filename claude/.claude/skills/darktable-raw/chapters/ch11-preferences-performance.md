# Chapter 11: Preferences, Color Management & Performance

## Core Idea
Key preferences set the workflow defaults (scene-referred, modern chromatic adaptation), color management governs ICC profiles across the pipeline, and performance tuning (OpenCL, memory, tiling) determines throughput — important for batch export of a full shoot.

## Frameworks Introduced

- **Workflow defaults** (preferences → processing):
  - `auto-apply pixel workflow defaults` = **scene-referred (filmic)** — the correct default (also enables exposure + filmic on new images). 'sigmoid' and 'display-referred' alternatives exist.
  - `auto-apply chromatic adaptation defaults` = **modern** (color calibration CAT) vs legacy (white balance only).
  - `allow_lab_output=TRUE` (darktablerc) to expose Lab output (for chart/profiling).

- **Color management** (12.1): ICC profiles at three points — **input color profile** (camera → working space), **working space** (pipeline, default **Rec 2020**), **output color profile** (export target, e.g. sRGB/AdobeRGB). Rendering intent (perceptual/relative). The display profile should be calibrated.

- **Performance & memory** (12.3):
  - A 20MP image ≈ 300MB (4×32-bit float/pixel); processing needs ≥2 buffers → 600MB–3GB. Minimum 4GB RAM + 4–8GB swap; more is better.
  - **OpenCL** (12.2): GPU acceleration; most modules have OpenCL paths. More GPU memory = better. `--disable-opencl` if a broken driver crashes startup.
  - **Tiling**: when memory is insufficient, images are split into tiles — always slower (up to 10×), impossible for some modules. Mostly hits full-size exports. Give darktable as much RAM/VRAM as possible to avoid it.
  - Tuning lives in preferences → processing → cpu/gpu/memory and in darktablerc.

## Key Concepts
- **darktablerc**: the config file (`$HOME/.config/darktable/darktablerc`); `--conf key=value` overrides per-run without persisting.
- **Working space = Rec 2020** by default — wide gamut keeps color-grading headroom.
- **OpenCL for batch**: the single biggest throughput lever for headless export of many frames.

## Anti-patterns
- **Leaving workflow on display-referred**: you lose the scene-referred pipeline and its modules.
- **Letting tiling kick in on big batches**: 10× slowdown — raise memory headroom / use OpenCL.
- **Uncalibrated display + judging color**: your edits won't match output.

## Reference Tables

| Setting | Recommended |
|---|---|
| pixel workflow | scene-referred (filmic) |
| chromatic adaptation | modern |
| working space | Rec 2020 (default) |
| output profile | sRGB (web) / AdobeRGB (print) |
| OpenCL | on (off only to debug crashes) |

## Key Takeaways
1. Confirm scene-referred + modern chromatic adaptation defaults — they shape every new edit.
2. Color management = input → working (Rec 2020) → output ICC; calibrate the display.
3. OpenCL is the main batch-throughput lever; tiling (memory-starved) is up to 10× slower.
4. `--conf` overrides darktablerc per-run; `--disable-opencl` for driver crashes.

## Connects To
- **Ch 10**: `--core --conf` and `--disable-opencl` come from here; OpenCL governs batch speed.
- **Ch 3**: modern chromatic adaptation = color calibration CAT.
- **Ch 1**: scene-referred default is set here.
