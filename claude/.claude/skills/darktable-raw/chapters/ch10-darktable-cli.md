# Chapter 10: darktable-cli, Variables & Batch Operation

## Core Idea
`darktable-cli` is the headless export engine: it applies a history stack (from an XMP sidecar or a named style) to RAW input and writes an output image, with no GUI. It shares config/library with the GUI and **locks the library**, so headless runs must use an isolated `--configdir`/`--library` to coexist with an open GUI. This is the chapter the *operator* drives.

## Frameworks Introduced

- **Invocation grammar**:
  ```
  darktable-cli <input file|folder> [<xmp file>] <output file|folder> [OPTIONS] [--core <darktable options>]
  ```
  - `<xmp file>` (positional, optional): the history stack to apply. **This is the cleanest batch primitive** — develop one reference NEF, then apply its `.xmp` to every other frame. If omitted, darktable looks for the input's own sidecar.
  - `--style <name>` / `--style-overwrite`: apply a named style (from data.db). `--apply-custom-presets false` needed to NOT auto-apply user presets (and lets multiple instances run, but then `--style` is unavailable since it needs data.db).
  - `--width` / `--height`: max pixels (0 = full res). `--hq <bool>` high-quality resampling (default true). `--upscale`.
  - `--out-ext <.ext>`: output format (overrides destination ext); required when output is a folder.
  - `--import <file|dir>`: repeatable, for multiple inputs/folders.
  - `--icc-type/--icc-file/--icc-intent`: output color management.

- **Export-format config** (per-run, not persisted):
  ```
  --core --conf plugins/imageio/format/<FORMAT>/<OPTION>=<VALUE>
  ```
  - jpeg: `quality` (5–100). exr: `bpp` (16/32), `compression` (0–8). j2k, pdf, etc.

- **Library isolation (critical for coexistence)**: darktable locks `<library>.lock` to the running PID; a second instance on the same library terminates immediately. For headless work alongside a GUI:
  ```
  --core --configdir /path/to/tmp-config --library /path/to/tmp-config/lib.db
  ```
  `:memory:` library = ephemeral, discarded on exit (fast, but writes no sidecar).

## Key Concepts
- **XMP sidecar = the edit, as data**: `<NEF>.xmp` holds `darktable:history` as an `rdf:Seq` of modules. Each has legible attributes (`operation`, `enabled`, `modversion`, `multi_priority`) BUT `params=` is a **packed hex blob** and `blendop_params=` is **gzip+base64**. → You cannot safely hand-edit arbitrary module parameters. Robust edit primitives: (a) GUI-authored `.dtstyle`, (b) copy a known-good sidecar between similar frames, (c) the legible attributes + `xmp:Rating`.
- **Sidecar writing**: default is `write_sidecar_files=on import`; a fresh temp/`:memory:` library may not trigger it — force with `--conf write_sidecar_files=TRUE`.
- **`.dtstyle`**: XML, but its `<plugin>` params carry the same packed blobs → author styles in the GUI, don't free-hand them.
- **Output variables**: the output filename supports `$(...)` variables (file name, sequence, Exif fields) — mandatory to use a variable or `--out-ext` when outputting a folder.

## Anti-patterns
- **Running darktable-cli on the default config while the GUI is open**: library lock → immediate termination. Always isolate.
- **Hand-editing `params=`/`blendop_params=` in XMP**: they're packed/compressed binary — you'll corrupt the history. Use styles or sidecar-copy.
- **`--style` with `--apply-custom-presets false` and no data.db**: style lookup needs data.db; disabling it removes `--style`.
- **Folder output without `--out-ext` or a filename variable**: ambiguous format / overwrite collisions.
- **`>100×` "speedups" or instant batches that produced nothing**: check exit code AND that files exist; a silent no-op looks like success.

## Reference Tables

| Goal | Command shape |
|---|---|
| Single export, see result | `darktable-cli in.NEF out.jpg --width 1600 --core --configdir TMP --library :memory:` |
| Apply reference edit to one frame | `darktable-cli in.NEF ref.NEF.xmp out.jpg --core --configdir TMP --library TMP/l.db` |
| Apply a GUI style | `darktable-cli in.NEF out.jpg --style "event-portrait" --core --configdir ~/.config/darktable` |
| Batch a folder | `darktable-cli RAWDIR OUTDIR --out-ext .jpg --style "event-portrait" --core --configdir TMP --library TMP/l.db` |
| Set JPEG quality 92 | `... --core --conf plugins/imageio/format/jpeg/quality=92` |
| Parallel batch | `ls *.NEF \| xargs -P4 -I{} darktable-cli {} out/ --out-ext .jpg --core --configdir TMP{#} --library :memory:` (separate config per worker) |

## Worked Example — batch the communion series from one reference
1. Develop `DSC_4998.NEF` in the GUI (or apply a style) → produces `DSC_4998.NEF.xmp`.
2. Save the look as a style `comunione` (GUI: history stack → create style).
3. Batch all frames:
   ```
   darktable-cli raw/ out/ --out-ext .jpg --width 3000 \
     --style comunione --apply-custom-presets true \
     --core --configdir ~/.config/darktable \
     --conf plugins/imageio/format/jpeg/quality=92
   ```
4. Verify: `ls out/*.jpg | wc -l` matches input count; spot-check one with a visual read.
   Alternative without a style: copy `DSC_4998.NEF.xmp` → `DSC_5004.NEF.xmp` (similar frame, 1/250 vs 1/125) and export each with its sidecar.

## Key Takeaways
1. `<xmp file>` positional arg and `--style` are the two batch primitives — both apply a full history stack.
2. Always isolate `--configdir`/`--library` when a GUI might be open; the library lock is unforgiving.
3. XMP params are packed/compressed — edit via GUI styles or sidecar-copy, never by typing blobs.
4. Per-run format options via `--core --conf plugins/imageio/format/<fmt>/<opt>=<val>`.
5. For folder output, always give `--out-ext` or a filename variable.
6. Verify outputs exist + exit code 0 + a visual spot-check — never trust silent success.

## Connects To
- **Ch 1**: the history stack (in the sidecar) is the scene-referred pixelpipe, serialized.
- **Ch 2 & 3**: a style bundles the exposure/filmic/color decisions for one-shot batch application.
- **Ch 11 (preferences)**: OpenCL and performance config affect batch throughput; `--disable-opencl` to debug.
- **Operator skill**: this chapter is the mechanism the darktable-operator workflow skill calls.
