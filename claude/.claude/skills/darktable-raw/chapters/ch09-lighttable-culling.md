# Chapter 9: Lighttable — Culling, Rating & Organization

## Core Idea
The lighttable view manages the library: import, cull (rate/reject/color-label), filter/sort/group, tag, and apply styles/history across selections — the front end to batch development. The darkroom develops one image; the lighttable orchestrates many.

## Frameworks Introduced

- **Rating & rejection** (keyboard): `0`–`5` set star rating; `R` rejects; color labels via `F1`–`F5`. The core culling vocabulary for a shoot.
- **Collections / filtering**: build collections by folder, date, rating, tag, camera, lens, etc.; filter + sort the current view.
- **Grouping**: stack related images (e.g. bracketed/duplicate shots) under one thumbnail.
- **History stack operations** (lighttable): **copy** the full or partial history from one image and **paste** to a selection — the GUI batch-edit path (mirror of `darktable-cli --style`/sidecar-copy).
- **Styles**: create a style from an image's history (`create style`), then apply to any selection. This is the artifact `darktable-cli --style` consumes.
- **Export module** (lighttable right panel): format, size, path with `$(...)` variables, ICC — the GUI equivalent of darktable-cli flags; its last-used settings are what `darktable-cli` reuses.

## Key Concepts
- **Cull → develop → batch-apply**: rate to select keepers, develop a reference, propagate via copy-paste/style.
- **thumbnail overlays**: show rating/label/metadata on hover or always.
- **Selection**: most operations (rating, copy-paste, style, export) act on the current selection.
- **Duplicates**: create virtual copies to try alternate edits non-destructively.

## Anti-patterns
- **Developing before culling**: wasted effort on rejects — rate first.
- **Re-developing each frame from scratch**: develop one reference, copy-paste history / apply a style.
- **Folder-output export without a filename variable**: collisions.

## Reference Tables

| Action | How |
|---|---|
| Rate / reject | `0`–`5` / `R` |
| Color label | `F1`–`F5` |
| Copy edit to others | copy history → select → paste |
| Reusable look | create style → apply to selection |
| Try alternate edit | create duplicate |
| Batch export | export module (or darktable-cli) |

## Key Takeaways
1. Lighttable = cull, rate (`0`–`5`/`R`), organize, and propagate edits across many images.
2. Develop one reference, then copy-paste history or apply a style to the rest — same model as darktable-cli batch.
3. Styles created here are exactly what `--style` consumes headless.
4. The export module's last settings are reused by darktable-cli.

## Connects To
- **Ch 10 (darktable-cli)**: styles and the history stack created here drive headless batch.
- **Ch 1**: the history stack is the serialized pixelpipe, copyable across images.
