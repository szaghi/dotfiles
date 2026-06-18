#!/usr/bin/env python3
"""dt-xmp-inject.py — inject a module's edit block from a .dtstyle into an XMP
history stack as a new rdf:li entry.

Why: darktable-cli silently drops some modules (e.g. colorbalancergb applied via
a preset) when materializing an XMP from a style. To make such a module's params
reachable for patching/applying, copy its <plugin> block out of the .dtstyle and
splice it into the XMP's <darktable:history> rdf:Seq, fixing num + history_end.

Idempotent: if the module's operation already exists in the XMP history, refuses
(use the existing entry instead).

Usage:
  dt-xmp-inject.py <xmp> <style.dtstyle> <operation>
"""
from __future__ import annotations

import html
import re
import sys

# style <plugin> tag  ->  xmp rdf:li attribute name
TAG_TO_ATTR = {
    "operation": "operation",
    "op_params": "params",
    "enabled": "enabled",
    "blendop_params": "blendop_params",
    "blendop_version": "blendop_version",
    "multi_priority": "multi_priority",
    "multi_name": "multi_name",
    "multi_name_hand_edited": "multi_name_hand_edited",
    "module": "modversion",  # style 'module' field carries the module/param version
}


def _plugin_block(style: str, op: str) -> str:
    for m in re.finditer(r"<plugin>.*?</plugin>", style, re.S):
        if f"<operation>{op}</operation>" in m.group(0):
            return m.group(0)
    sys.exit(f"ERROR: operation '{op}' not found in style")


def _field(block: str, tag: str) -> str:
    m = re.search(rf"<{tag}>(.*?)</{tag}>", block, re.S)
    return m.group(1) if m else ""


def main() -> None:
    if len(sys.argv) != 4:
        sys.exit(__doc__)
    xmp_path, style_path, op = sys.argv[1:4]
    xmp = open(xmp_path, encoding="utf-8").read()
    style = open(style_path, encoding="utf-8").read()

    if re.search(rf'darktable:operation="{re.escape(op)}"', xmp):
        sys.exit(f"ERROR: '{op}' already in XMP history — patch the existing entry instead")

    block = _plugin_block(style, op)

    # next history index = max(num)+1
    nums = [int(n) for n in re.findall(r'darktable:num="(\d+)"', xmp)]
    new_num = max(nums) + 1 if nums else 0

    # build the rdf:li from style fields
    attrs = [f'darktable:num="{new_num}"']
    # operation/modversion/enabled first for readability, then the rest
    order = ["operation", "enabled", "module", "op_params",
             "multi_name", "multi_name_hand_edited", "multi_priority",
             "blendop_version", "blendop_params"]
    for tag in order:
        attr = TAG_TO_ATTR[tag]
        val = html.escape(_field(block, tag), quote=True)
        attrs.append(f'darktable:{attr}="{val}"')
    li = "     <rdf:li\n      " + "\n      ".join(attrs) + "/>"

    # splice before the closing </rdf:Seq> of the history block
    hist = re.search(r"(<darktable:history>\s*<rdf:Seq>)(.*?)(</rdf:Seq>)", xmp, re.S)
    if not hist:
        sys.exit("ERROR: could not locate <darktable:history> rdf:Seq")
    new_seq = hist.group(1) + hist.group(2).rstrip() + "\n" + li + "\n    " + hist.group(3)
    xmp = xmp[: hist.start()] + new_seq + xmp[hist.end():]

    # bump history_end to include the new entry
    xmp = re.sub(r'(darktable:history_end=")(\d+)(")',
                 lambda m: f'{m.group(1)}{int(m.group(2)) + 1}{m.group(3)}', xmp, count=1)

    open(xmp_path, "w", encoding="utf-8").write(xmp)
    print(f"injected '{op}' as history num {new_num}; history_end bumped")


if __name__ == "__main__":
    main()
