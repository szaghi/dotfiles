---
name: darktable-operator
description: "Operator workflow for post-processing a RAW shoot in darktable with Claude as the operator. Use when the user wants to develop/process/batch their RAW photos (NEF/CR2/ARW), cull a shoot, apply a consistent look across a series, control edit values (exposure etc.) from the prompt, or run darktable-cli batches. Drives the four-stage pipeline (ingest/diagnose -> cull -> look -> export) and the edit-and-look QA loop. References the darktable-raw skill for module specifics. Architecture: the user builds a base LOOK once in the GUI; Claude captures it as a reference XMP and then controls precise per-module values from the prompt by patching the XMP (dt-xmp-patch.py), applying it headlessly via darktable-cli's positional-xmp arg."
allowed-tools:
  - Read
  - Grep
  - Bash
argument-hint: [shoot folder path, or stage name]
---

# darktable Operator — RAW shoot post-processing

**Companion**: read [darktable-raw](../darktable-raw/SKILL.md) for any module/parameter/CLI specifics. This skill is the *workflow*; that skill is the *knowledge*.
**Helpers**: `scripts/dt-batch.sh` (diagnose / render / ref / apply / verify) and `scripts/dt-xmp-patch.py` (get/set precise param values in an XMP).

## The architecture (read first) — reference XMP, value-controlled from the prompt
darktable edits live in an XMP sidecar as module `params`. Two encodings:
- **raw hex** (exposure, flip, demosaic) — a plain little-endian C struct; Claude edits a float/int at a known byte offset directly.
- **gz...** (filmicrgb, colorbalancergb, channelmixerrgb) — zlib-compressed + base64 C struct; Claude can still edit by decompress → patch offset → recompress.

So Claude **can** set precise values. The patcher (`dt-xmp-patch.py`) only edits fields with a *verified* offset (its `FIELDS` map) — extend it one module at a time by decoding a real XMP. The user still builds the *look's shape* once in the GUI (filmic curve, color grade) because mapping every offset is work; but the **tuning values the user calls out in the prompt are patched here, no GUI round-trip.**

**Delivery is the positional-XMP path, NOT styles.** `darktable-cli <raw> <ref.xmp> <out>` applies a history stack directly — no `data.db`, no style registration, `:memory:` library, GUI-safe. (Styles require import into data.db and collide with the GUI lock — avoid them for application.)

So this is a **hybrid** workflow: user builds the base look ONCE (captured as a reference XMP); Claude diagnoses, culls, and then **controls values from the prompt by patching the XMP**, applies headlessly, and QAs by looking — every shoot, forever.

---

## The four-stage pipeline

### Stage 0 — Ingest & Diagnose  *(Claude, autonomous)*
1. `bash scripts/dt-batch.sh diagnose <raw_dir>` — inventories all RAW files, **clusters by camera|lens|ISO|exposure-program**, and renders ONE neutral baseline JPEG per cluster.
2. **Read every baseline JPEG** (visually — this is mandatory, never diagnose blind).
3. Write a per-cluster diagnosis: exposure (under/over), highlights (clipped? where?), white balance (cast?), geometry (level? keystone?), noise (ISO-driven). Be specific and image-derived, e.g. "indoor backlit, white garments near clip, faces ~1EV under" — not generic.
4. Map each cluster to a likely style + adjustments (Stage 2 input).

### Stage 1 — Cull  *(Claude proposes, user ratifies)*
- Render thumbnails/baselines, propose keep/reject + star ratings (darktable vocabulary: `0`–`5`, `R` reject — see darktable-raw ch09).
- Judge on: focus/sharpness, eyes open, expression, motion blur, beyond-recovery clipping.
- **User holds veto** — expression and "which subject to favor" are theirs. Rejects skip all further processing.

### Stage 2 — Look & tune  *(user builds the look ONCE; Claude controls values from here)*
1. **Get a base look once.** If no reference XMP exists, guide the user to build a base look in the GUI (see "Guiding style creation") and save it as a style; then capture it as an editable XMP — GUI CLOSED:
   `bash scripts/dt-batch.sh ref <ref.NEF> <style_name> <shoot>/look.xmp`
   The XMP is now the artifact; the style is no longer needed.
2. **Normalize for predictability:** `dt-xmp-patch.py look.xmp set exposure compensate 0` (so the EV you set is the EV applied — no hidden Exif bias).
3. **Tune from the prompt.** When the user says "exposure 0.8", "a touch darker", etc., patch the XMP:
   `dt-xmp-patch.py look.xmp set exposure exposure 0.80`
   Inspect current values with `... get <module>`; list patchable modules with `... list`. For a `gz` field with no verified offset yet, decode a real XMP, map it, add it to `FIELDS` (don't guess offsets).
4. **QA loop:** `dt-batch.sh render <ref.NEF> /tmp/qa.jpg 1600 look.xmp` → **read the JPEG** → adjust the patch → re-render. Iterate until right.
5. For per-frame brightness spread (different shutter across a series), either copy+patch a per-frame XMP, or use exposure area-mapping (darktable-raw ch02).

### Stage 3 — Export  *(Claude, autonomous)*
- `bash scripts/dt-batch.sh apply <raw_dir> <out_dir> <look.xmp> [width] [quality]` — applies the tuned XMP to every RAW via the positional-xmp path (GUI-safe, :memory:).
- Then **verify**: count matches, and **read one sample output** to confirm it looks right. Never report "done" on an unverified or silent-no-op batch.

---

## Edit-and-look loop (the core discipline)
Every value change is judged by rendering and **looking**, not by reasoning about parameters. Patch the XMP (`dt-xmp-patch.py set ...`) → `dt-batch.sh render <ref.NEF> /tmp/qa.jpg 1600 <look.xmp>` → read the JPEG → adjust the patch → repeat. A tuning step that ends without a visual check is incomplete.

## Guiding style creation (what to tell the user, by cluster type)
Use darktable-raw chapters for exact controls. Typical starter library:

| Style | Build in GUI (modules) | darktable-raw ref |
|---|---|---|
| `event-base` | exposure (mid-gray) → filmic rgb (scene white/black via pickers, look contrast) → color balance rgb "basic colorfulness" → color calibration CAT as-shot | ch01, ch02, ch03 |
| `highlight-recover` | filmic reconstruct tab + tone equalizer (eigf mask, pull bright zone −1EV) + highlight reconstruction non-clip method | ch02, ch04, ch06 |
| `skin-warm` | color balance rgb 4-ways: warm mid-tones, neutral highlights (keep whites white) | ch03 |

Guidance phrasing example: *"In filmic scene tab, click the white-relative-exposure picker on the brightest cloud you want to keep; in tone equalizer, display the mask, build an eigf mask, then pull the top (brightest) zone down ~1 EV."* Then verify by rendering.

**Saving a style (exact 4.6 GUI location — do not under-specify this):** the **history stack** module is in the darkroom **LEFT panel** (the right panel holds processing modules; left holds utility modules). Expand its header if collapsed (press `L` to reveal the left panel). At the **bottom** of the module are two buttons: *"compress history stack"* and — **immediately to its right** — the **create-style** button. Click the right one → popup → name the style → leave modules checked → create. Confirm with `ls ~/.config/darktable/styles/<name>.dtstyle`.

## Hard rules (operator discipline)
- **Application is via positional XMP, never `--style`.** `darktable-cli <raw> <xmp> <out>` with `:memory:` lib — GUI-safe, no data.db. The ONLY step needing the real config is `ref` (one-time style→XMP capture), which requires the **GUI CLOSED** (library lock).
- **Headless/WSL note:** OpenCL is absent here; a render that dies at ~0.4s with `imageio_storage_disk: could not export` is the OpenCL/storage path failing — the helper falls back to CPU. If a bare invocation fails, that's why; the helper's `:memory:`+CPU path works.
- **Patch only verified offsets.** `dt-xmp-patch.py` edits fields in its `FIELDS` map (exposure mapped). For a new field, decode a real XMP and map the struct — never guess an offset (a wrong offset silently corrupts the edit).
- **Set `exposure.compensate 0`** in the reference XMP so the prompt's EV == applied EV.
- **One display transform** per look (filmic OR sigmoid). Portraits with sigmoid: skew=0. (darktable-raw ch02)
- **Develop order**: basics → corrections → creative → crop. (ch01)
- **Never claim a result you didn't look at.** Render + read, every time.
- **Cull before developing** — don't process rejects.
- **The look's shape is the user's taste**; value tuning, selection, sequencing is Claude's; final approval is the user's.

## Scope & limits
- The user builds the base look's *shape* once in the GUI; Claude captures it as an XMP and controls *values* from the prompt via dt-xmp-patch.py.
- `gz` modules (filmic, colorbalancergb) need their struct offsets mapped before their values are promptable — exposure (raw hex) is mapped and working; extend incrementally.
- Cull and look-selection are assistive, not authoritative.
- Supported RAW in the helper: NEF/CR2/ARW/RAF (extend as needed).
- For module/CLI detail, always defer to darktable-raw rather than memory.
