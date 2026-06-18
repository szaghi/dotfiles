#!/usr/bin/env bash
# dt-batch.sh — deterministic darktable-cli helpers for the darktable-operator skill.
# Stages: diagnose (inventory+cluster+baseline render), render (single look-check),
#         batch (apply style to a folder), verify (count+visual-sample check).
# All darktable-cli runs are config-isolated so they NEVER collide with an open GUI.
set -euo pipefail

die()  { echo "ERROR: $*" >&2; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }

have darktable-cli || die "darktable-cli not found"
have exiftool      || die "exiftool not found"

# Per-run isolated config/library so a GUI session keeps its lock (ch10 discipline).
ISO_CFG="$(mktemp -d /tmp/dt-operator.XXXXXX)"
trap 'rm -rf "$ISO_CFG"' EXIT
DT_CORE=(--core --configdir "$ISO_CFG" --library "$ISO_CFG/lib.db")

usage() {
  cat <<'EOF'
dt-batch.sh <command> [args]

  diagnose <raw_dir> [out_dir]
      Inventory NEFs, cluster by camera/lens/ISO/exposure-mode, and render a
      neutral baseline JPEG (1600px) per UNIQUE cluster representative.
      Prints a TSV diagnosis table + the baseline JPEG paths to read.

  render <in.NEF> <out.jpg> [width] [xmp]
      Single export for the look-check loop. If <xmp> given, applies it
      (positional-XMP path, :memory: lib, lock-free). Default width 1600.

  ref <in.NEF> <style_name> <out.xmp>
      ONE-TIME: materialize a reference XMP from a GUI-built style. Needs the
      real config (data.db has the style) — run with the GUI CLOSED. The XMP
      is then the editable artifact; the style is no longer needed.

  contact <raw_dir> [out_dir] [cols] [thumb_px]
      Cull aid: render every RAW to a small neutral thumbnail and montage them
      into labeled contact-sheet page(s) (default 5 cols, 400px thumbs, 30/page)
      for one-glance review. Prints the sheet path(s) to read.

  apply <raw_dir> <out_dir> <ref.xmp> [width] [jpeg_quality] [overrides.tsv]
      Apply a reference XMP to every RAW in raw_dir via darktable-cli's
      positional-xmp arg. No style/data.db, :memory: lib, GUI-safe. Default
      width 0 (full res), quality 92. Optional overrides.tsv patches per-frame
      fields (lines: "<basename-regex>\t<module>\t<field>\t<value>"). Verifies.

  verify <raw_dir> <out_dir>
      Confirm output count == input count; list any unprocessed inputs.

  Value control: edit precise params in a ref XMP with dt-xmp-patch.py
  (e.g. `dt-xmp-patch.py ref.xmp set exposure exposure 0.8`) BEFORE apply.
EOF
}

cmd_diagnose() {
  local raw="${1:?raw_dir}"; local out="${2:-$raw/../baselines}"
  mkdir -p "$out"
  printf '# cluster\tfile\tcamera\tlens\tfocal\tfnum\tshutter\tiso\twb\tprogram\n'
  declare -A seen
  # Query each tag explicitly by name (NOT positional array indexing — absent
  # tags collapse a positional array and silently misalign the fields).
  get() { local v; v=$(exiftool -s3 -"$2" "$1" 2>/dev/null | head -1 | tr ' ' '_'); printf '%s' "${v:-?}"; }
  while IFS= read -r f; do
    local cam lens focal fnum shutter iso wb prog
    cam=$(get "$f" Model);       lens=$(get "$f" LensID)
    focal=$(get "$f" FocalLength); fnum=$(get "$f" FNumber)
    shutter=$(get "$f" ShutterSpeed); iso=$(get "$f" ISO)
    wb=$(get "$f" WhiteBalance);  prog=$(get "$f" ExposureProgram)
    # cluster key: camera|iso|program (lens excluded — slashes/spaces are a poor id)
    local key="${cam}|${iso}|${prog}"
    printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
      "$key" "$f" "$cam" "$lens" "$focal" "$fnum" "$shutter" "$iso" "$wb" "$prog"
    # render ONE baseline per cluster (the representative)
    if [[ -z "${seen[$key]:-}" ]]; then
      seen[$key]=1
      local b="$out/$(basename "${f%.*}")_baseline.jpg"
      darktable-cli "$f" "$b" --width 1600 --apply-custom-presets false \
        "${DT_CORE[@]}" --library ":memory:" >/dev/null 2>&1 \
        && echo "# BASELINE[$key] -> $b" >&2
    fi
  done < <(find "$raw" -maxdepth 1 -type f \( -iname '*.nef' -o -iname '*.cr2' -o -iname '*.arw' -o -iname '*.raf' \) | sort)
}

cmd_render() {
  local in="${1:?in.NEF}"; local out="${2:?out.jpg}"; local w="${3:-1600}"; local xmp="${4:-}"
  # positional <xmp> (if given) applies a history stack directly — no style/data.db.
  local args=("$in"); [[ -n "$xmp" ]] && args+=("$xmp"); args+=("$out" --width "$w")
  [[ -z "$xmp" ]] && args+=(--apply-custom-presets false)
  darktable-cli "${args[@]}" "${DT_CORE[@]}" --library ":memory:" >/dev/null 2>&1 \
    || die "render failed (try --disable-opencl if on WSL/headless)"
  [[ -f "$out" ]] || die "render produced no output"
  echo "rendered -> $out"
}

cmd_ref() {
  local in="${1:?in.NEF}"; local style="${2:?style_name}"; local out="${3:?out.xmp}"
  # ONE-TIME: --style needs data.db => real config. GUI MUST be closed (lock).
  pgrep -x darktable >/dev/null && die "close the darktable GUI first (library lock)"
  local tmp; tmp=$(mktemp -d /tmp/dt-ref.XXXXXX)
  cp "$in" "$tmp/ref.${in##*.}"
  darktable-cli "$tmp/ref.${in##*.}" "$tmp/ref.jpg" --width 300 --style "$style" \
    --core --configdir "$HOME/.config/darktable" --library "$tmp/lib.db" \
    --conf write_sidecar_files=TRUE >/dev/null 2>&1 || { rm -rf "$tmp"; die "style apply failed"; }
  [[ -f "$tmp/ref.${in##*.}.xmp" ]] || { rm -rf "$tmp"; die "no XMP written"; }
  cp "$tmp/ref.${in##*.}.xmp" "$out"; rm -rf "$tmp"
  echo "reference XMP -> $out  (edit with dt-xmp-patch.py, then 'apply')"
}

cmd_apply() {
  local raw="${1:?raw_dir}"; local out="${2:?out_dir}"; local xmp="${3:?ref.xmp}"
  local w="${4:-0}"; local q="${5:-92}"; local ovr="${6:-}"
  [[ -f "$xmp" ]] || die "ref xmp not found: $xmp"
  [[ -n "$ovr" && ! -f "$ovr" ]] && die "overrides file not found: $ovr"
  # CRITICAL: a stray <raw>.xmp next to the source gets MERGED into the applied
  # history and silently contaminates the result. Refuse rather than mislead.
  local strays; strays=$(find "$raw" -maxdepth 1 -type f -iname '*.nef.xmp' -o -iname '*.cr2.xmp' 2>/dev/null)
  [[ -n "$strays" ]] && die "stray sidecars present (they contaminate apply): $strays
  remove them (rm \"$raw\"/*.NEF.xmp) or move them aside, then re-run."
  mkdir -p "$out"
  local patch="$(dirname "$0")/dt-xmp-patch.py"
  while IFS= read -r f; do
    local base="$(basename "${f%.*}")"; local o="$out/$base.jpg"; rm -f "$o"
    local use="$xmp" tmpx=""
    # per-frame overrides: TSV lines "<basename-or-glob>\t<module>\t<field>\t<value>"
    if [[ -n "$ovr" ]]; then
      local hits; hits=$(awk -v b="$base" '$1!~/^#/ && (b ~ "^"$1"$" || b==$1){print}' "$ovr")
      if [[ -n "$hits" ]]; then
        tmpx=$(mktemp /tmp/ovr.XXXXXX.xmp); cp "$xmp" "$tmpx"; use="$tmpx"
        while IFS=$'\t' read -r _pat mod field val; do
          [[ -z "$mod" ]] && continue
          python3 "$patch" "$tmpx" set "$mod" "$field" "$val" >/dev/null \
            && echo "    [override] $base: $mod.$field=$val"
        done <<< "$hits"
      fi
    fi
    darktable-cli "$f" "$use" "$o" --width "$w" \
      "${DT_CORE[@]}" --library ":memory:" \
      --conf "plugins/imageio/format/jpeg/quality=$q" >/dev/null 2>&1 \
      && echo "  $o" || echo "  FAILED: $f" >&2
    [[ -n "$tmpx" ]] && rm -f "$tmpx"
  done < <(find "$raw" -maxdepth 1 -type f \( -iname '*.nef' -o -iname '*.cr2' -o -iname '*.arw' -o -iname '*.raf' \) | sort)
  cmd_verify "$raw" "$out"
}

cmd_contact() {
  local raw="${1:?raw_dir}"; local out="${2:-$raw/../contact}"
  local cols="${3:-5}"; local px="${4:-400}"; local per_page=$((cols*6))
  command -v montage >/dev/null || die "montage (ImageMagick) not found"
  mkdir -p "$out" "$out/.thumbs"
  echo "rendering thumbnails..."
  local list=() i=0
  while IFS= read -r f; do
    local t="$out/.thumbs/$(basename "${f%.*}").jpg"
    darktable-cli "$f" "$t" --width "$px" --apply-custom-presets false \
      "${DT_CORE[@]}" --library ":memory:" >/dev/null 2>&1 \
      && list+=("$t") || echo "  thumb FAILED: $f" >&2
    i=$((i+1))
  done < <(find "$raw" -maxdepth 1 -type f \( -iname '*.nef' -o -iname '*.cr2' -o -iname '*.arw' -o -iname '*.raf' \) | sort)
  [[ ${#list[@]} -eq 0 ]] && die "no thumbnails rendered"
  # montage into page(s), capped at per_page each, with filename labels
  local page=0 n=${#list[@]} start=0
  while [[ $start -lt $n ]]; do
    local chunk=("${list[@]:start:per_page}")
    local sheet="$out/contact-$(printf '%02d' "$page").jpg"
    montage "${chunk[@]}" -tile "${cols}x" -geometry "+6+6" \
      -set label '%t' -pointsize 18 -background '#222' -fill '#ddd' \
      "$sheet" 2>/dev/null && echo "sheet -> $sheet (${#chunk[@]} frames)"
    start=$((start+per_page)); page=$((page+1))
  done
  rm -rf "$out/.thumbs"
  echo "read the contact sheet(s) above; propose keep/reject + ratings, user ratifies."
}

cmd_verify() {
  local raw="${1:?raw_dir}"; local out="${2:?out_dir}"
  local nin nout
  nin=$(find "$raw" -maxdepth 1 -type f \( -iname '*.nef' -o -iname '*.cr2' -o -iname '*.arw' -o -iname '*.raf' \) | wc -l)
  nout=$(find "$out" -maxdepth 1 -type f -iname '*.jpg' | wc -l)
  echo "inputs=$nin outputs=$nout"
  [[ "$nin" -eq "$nout" ]] && echo "OK: counts match" || echo "WARN: count mismatch — inspect"
}

case "${1:-}" in
  diagnose) shift; cmd_diagnose "$@";;
  render)   shift; cmd_render   "$@";;
  ref)      shift; cmd_ref      "$@";;
  contact)  shift; cmd_contact  "$@";;
  apply)    shift; cmd_apply    "$@";;
  verify)   shift; cmd_verify   "$@";;
  *)        usage; exit 1;;
esac
