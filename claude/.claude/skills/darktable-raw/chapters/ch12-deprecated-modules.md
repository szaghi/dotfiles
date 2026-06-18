# Chapter 12: Deprecated Modules — Index & Replacements

## Core Idea
These modules exist for backward compatibility (old edits keep working) but **must not be used on new scene-referred edits**. Most belong to the legacy display-referred era and conflict with the modern pipeline. This chapter is a *warn-off index*, not a how-to: if tempted to reach for one, use its replacement.

## Deprecated Modules → Use Instead

| Deprecated (8.2.x) | Use instead |
|---|---|
| basic adjustments | exposure + filmic rgb + color balance rgb |
| channel mixer | color calibration (channel mixer tabs) |
| contrast brightness saturation | color balance rgb / tone equalizer |
| crop and rotate | rotate and perspective + crop |
| defringe | chromatic aberrations / raw chromatic aberrations |
| fill light | tone equalizer (dodge shadows) |
| global tonemap | filmic rgb / sigmoid |
| invert | negadoctor (for film negatives) |
| levels | exposure + filmic rgb (scene-referred) |
| spot removal | retouch |
| tone mapping | filmic rgb / sigmoid / tone equalizer |
| vibrance | color balance rgb (global vibrance) |
| zone system | tone equalizer |

## Key Concepts
- **Why deprecated**: nearly all assume display-referred, non-linear data and produce artifacts (hue shifts, the "HDR look") in the scene-referred pipeline.
- **Still present**: to render historical edits faithfully — not removed, just hidden from the default scene-referred workflow preset.
- **base curve** (not formally deprecated but legacy): the display-referred tone mapper; replaced by filmic rgb / sigmoid. Auto-enabled only under the display-referred workflow.

## Anti-patterns
- **Reaching for `levels` / `tone curve` out of Lightroom habit**: scene-referred invalidates their black/white/gray assumptions — use exposure + filmic.
- **`global tonemap` / `tone mapping` for HDR**: filmic rgb is the modern DR-compression tool.
- **`spot removal`**: superseded by retouch (frequency separation, more capable).

## Key Takeaways
1. Treat every `(deprecated)` module as off-limits for new edits; the table gives the modern replacement.
2. Most are legacy display-referred tools that fight the scene-referred pipeline.
3. They remain only to render old history stacks.

## Connects To
- **Ch 1**: the scene-referred vs display-referred split is *why* these are deprecated.
- **Ch 2 / 3 / 8**: filmic, color balance rgb, tone equalizer, retouch are the replacements.
