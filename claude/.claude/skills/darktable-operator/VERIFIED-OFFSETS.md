# Verified filmic struct offsets (dt_iop_filmicrgb_params_t, darktable 4.6)
# Method: GUI single-slider change -> diff .dtstyle bytes. word index * 4 = byte offset.

w14 (byte 56) = contrast  [VERIFIED via diff1: 1.0 -> 2.0]
  CAUTION: changing contrast in GUI also recomputed w2 and w12 (auto-derived spline params).
  => contrast is NOT safely patchable in isolation by static byte-edit. Skip as promptable.

# pending: white_point_source, black_point_source, saturation

w2  (byte 8)  = white_point_source (EV)  [VERIFIED via diff2: ->5.0 exactly]
  side effect: w12 (derived spline param) recomputes; w2 itself patches cleanly.

PROOF: patched white_point 3.0 vs 6.0 in event-base.xmp, rendered DSC_5004 ->
  visibly different (3.0 recovers background, 6.0 opens subjects). w2 patches
  cleanly end-to-end; apply-time spline recompute handles derived w12. PROMPTABLE.

w1  (byte 4)  = black_point_source (EV)  [VERIFIED via diff3: ->-10.0 exactly]
w12 (byte 48) = DERIVED spline param (reacts to white/black/contrast) — NEVER patch directly.

== colorbalancergb ==
w19 (byte 76) = global saturation, stored as FRACTION (0.30 = 30%) [VERIFIED diff3->diff4]
PROBLEM: darktable-cli DROPS colorbalancergb from the applied history when materializing
an XMP from a style (tested twice, diff4 too). So saturation is NOT reachable via the
normal `ref` path. Requires INJECTING a colorbalancergb <rdf:li> into the XMP directly
(translate style <plugin> -> xmp li: num/operation/enabled/modversion/params(<-op_params)/
blendop_params/multi_*). Offset is mapped and ready; only delivery is pending.

SOLVED: dt-xmp-inject.py injects colorbalancergb <plugin> -> XMP <rdf:li>.
PROVEN: saturation 0.0 vs 0.6 render visibly different. PROMPTABLE via inject+patch.

== toneequal (tone equalizer) — RAW HEX struct, 72 bytes / 18 words ==
Source: dt_iop_toneequalizer_params_t (darktable 4.6.0), confirmed by difftq diff
(my -2.0 GUI edit landed in noise@byte0, proving struct order == source order;
NOTE the GUI simple-tab slider order is darkest->brightest, same as struct).
  byte 0  noise              (darkest ~-8 EV band)
  byte 4  ultra_deep_blacks
  byte 8  deep_blacks
  byte 12 blacks
  byte 16 shadows
  byte 20 midtones
  byte 24 highlights
  byte 28 whites
  byte 32 speculars          (brightest ~0 EV band)
  byte 36 blending  40 smoothing  44 feathering  48 quantization
  byte 52 contrast_boost  56 exposure_boost  60 details(int) 64 method(int) 68 iterations(int)
PROVEN: whites -1.5 + speculars -2.0 + highlights -0.8 on 5004 darkened the bright
window/garden while leaving faces & shirts untouched (default eigf mask isolated it).
Delivery: inject toneequal block (dt-xmp-inject.py) into the look XMP, then patch bands.
