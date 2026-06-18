#!/usr/bin/env python3
"""dt-xmp-patch.py — set precise darktable module parameter values inside an XMP
sidecar, so Claude can control edit values from the prompt and apply them via
`darktable-cli <raw> <xmp> <out>` (the positional-XMP path: no style/data.db).

darktable XMP `params` come in two encodings:
  - RAW HEX  : plain little-endian C struct as hex (e.g. exposure, flip, demosaic).
               Patched by writing the IEEE-754 float at a known byte offset.
  - gz...    : zlib-compressed C struct, base64-encoded, prefixed "gz<NN>".
               Patched by base64-decode -> zlib-decompress -> edit -> recompress.

Only fields with a verified offset (see FIELDS) are patchable. Adding a module
means decoding one real XMP, mapping its struct, and adding a FIELDS entry.

Usage:
  dt-xmp-patch.py <xmp> get  <module> [field]
  dt-xmp-patch.py <xmp> set  <module> <field> <value>
  dt-xmp-patch.py <xmp> list
"""
from __future__ import annotations

import base64
import re
import struct
import sys
import zlib

# module -> { field -> (kind, offset, fmt) }
#   kind: "raw" (hex struct) or "gz" (zlib+base64 struct)
#   offset: byte offset of the field inside the *uncompressed* struct
#   fmt: struct format char ('f' float, 'i' int)
# VERIFIED offsets only. Exposure mapped from a real darktable 4.6 XMP.
FIELDS: dict[str, dict[str, tuple[str, int, str]]] = {
    "exposure": {
        "mode":       ("raw", 0,  "i"),  # 0 = manual, 1 = automatic
        "black":      ("raw", 4,  "f"),
        "exposure":   ("raw", 8,  "f"),  # EV — the main lever (manual mode)
        "percentile": ("raw", 12, "f"),  # auto mode: histogram percentile to anchor (e.g. 50)
        "target":     ("raw", 16, "f"),  # auto mode: target level EV for that percentile
        "compensate": ("raw", 20, "i"),  # 1 = add camera Exif bias (set 0 for predictability)
    },
    "filmicrgb": {
        # VERIFIED via GUI single-slider diff of .dtstyle bytes (darktable 4.6).
        # gz-encoded struct (dt_iop_filmicrgb_params_t).
        "white_point": ("gz", 8,  "f"),  # white relative exposure (EV) — diff2: ->5.0 exact, render-proven
        "black_point": ("gz", 4,  "f"),  # black relative exposure (EV) — diff3: ->-10.0 exact
        "contrast":    ("gz", 56, "f"),  # diff1: ->2.0 exact. CAUTION: GUI couples derived
                                          # spline word (w12); static patch sets contrast only.
    },
    "colorbalancergb": {
        # VERIFIED via diff3->diff4: w19 global saturation, stored as FRACTION (0.30 = 30%).
        "saturation": ("gz", 76, "f"),  # global saturation, fraction. w19 * 4 = byte 76
    },
    "toneequal": {
        # VERIFIED: raw-hex struct (72B), source dt_iop_toneequalizer_params_t + difftq diff.
        # 9 EV bands, darkest->brightest. To darken a bright window/sky, lower the bright end.
        "noise":             ("raw", 0,  "f"),  # darkest band (~-8 EV) — confirmed by difftq
        "ultra_deep_blacks": ("raw", 4,  "f"),
        "deep_blacks":       ("raw", 8,  "f"),
        "blacks":            ("raw", 12, "f"),
        "shadows":           ("raw", 16, "f"),
        "midtones":          ("raw", 20, "f"),
        "highlights":        ("raw", 24, "f"),
        "whites":            ("raw", 28, "f"),
        "speculars":         ("raw", 32, "f"),  # brightest band (~0 EV) — window/sky
    },
}


def _read(path: str) -> str:
    with open(path, encoding="utf-8") as fh:
        return fh.read()


def _find_params(xmp: str, module: str) -> re.Match[str]:
    # params for a module live in its rdf:li block; match the operation then its params=
    m = re.search(
        rf'operation="{re.escape(module)}".*?params="([0-9a-zA-Z+/=]+)"',
        xmp, re.S,
    )
    if not m:
        # attribute order can vary; try params= preceding operation within one li
        m = re.search(
            rf'params="([0-9a-zA-Z+/=]+)"[^>]*?operation="{re.escape(module)}"',
            xmp, re.S,
        )
    if not m:
        sys.exit(f"ERROR: module '{module}' params not found in XMP")
    return m


def _decode(blob: str) -> tuple[str, bytes]:
    """Return (kind, raw_struct_bytes)."""
    if blob.startswith("gz"):
        b64 = blob[4:]  # strip "gz" + 2-digit factor
        return "gz", zlib.decompress(base64.b64decode(b64))
    return "raw", bytes.fromhex(blob)


def _encode(kind: str, data: bytes, original: str) -> str:
    if kind == "gz":
        prefix = original[:4]  # preserve "gz<NN>"
        return prefix + base64.b64encode(zlib.compress(data, 9)).decode()
    return data.hex()


def cmd_list(xmp_path: str) -> None:
    xmp = _read(xmp_path)
    for op in re.findall(r'operation="([^"]+)"', xmp):
        mark = " (patchable)" if op in FIELDS else ""
        print(f"  {op}{mark}")


def cmd_get(xmp_path: str, module: str, field: str | None) -> None:
    xmp = _read(xmp_path)
    blob = _find_params(xmp, module).group(1)
    kind, data = _decode(blob)
    spec = FIELDS.get(module, {})
    if field:
        k, off, fmt = spec[field]
        (val,) = struct.unpack_from(f"<{fmt}", data, off)
        print(f"{module}.{field} = {val}")
    else:
        for fn, (k, off, fmt) in spec.items():
            (val,) = struct.unpack_from(f"<{fmt}", data, off)
            print(f"{module}.{fn} = {val}")


def cmd_set(xmp_path: str, module: str, field: str, value: str) -> None:
    if module not in FIELDS or field not in FIELDS[module]:
        sys.exit(f"ERROR: {module}.{field} not in verified FIELDS map")
    kind, off, fmt = FIELDS[module][field]
    xmp = _read(xmp_path)
    m = _find_params(xmp, module)
    blob = m.group(1)
    dkind, data = _decode(blob)
    data = bytearray(data)
    packed = int(value) if fmt == "i" else float(value)
    struct.pack_into(f"<{fmt}", data, off, packed)
    new_blob = _encode(dkind, bytes(data), blob)
    new_xmp = xmp[: m.start(1)] + new_blob + xmp[m.end(1) :]
    with open(xmp_path, "w", encoding="utf-8") as fh:
        fh.write(new_xmp)
    # verify round-trip
    _, chk = _decode(new_blob)
    (got,) = struct.unpack_from(f"<{fmt}", chk, off)
    print(f"set {module}.{field} -> {got}")


def main() -> None:
    if len(sys.argv) < 3:
        sys.exit(__doc__)
    xmp, op = sys.argv[1], sys.argv[2]
    if op == "list":
        cmd_list(xmp)
    elif op == "get":
        cmd_get(xmp, sys.argv[3], sys.argv[4] if len(sys.argv) > 4 else None)
    elif op == "set":
        cmd_set(xmp, sys.argv[3], sys.argv[4], sys.argv[5])
    else:
        sys.exit(__doc__)


if __name__ == "__main__":
    main()
