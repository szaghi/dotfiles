---
name: remotion-infographics
description: >-
  Author still-image infographics and figures for slide decks, talks, tutorials
  and papers with Remotion — the still-first, deck-matched workflow distilled
  from Stefano's talks (hpc-webinar, pilot-tutorial) and the mosaic reel. Use
  this whenever the task is "make a figure / infographic / diagram for a slide"
  in a Remotion project, or scaffolding a new `infographics/` directory for a
  deck. This skill owns the WORKFLOW and CONVENTIONS (still-first, role-semantic
  components, per-figure sizing, render-to-deck, pluggable themes); it does NOT
  re-teach Remotion mechanics — for animation/timing/composition/render APIs,
  defer to the official `remotion-best-practices` skill and its siblings
  (`remotion-markup`, `remotion-render`, `remotion-create`, `remotion-docs`).
  Themes (Solarized dark/light, Dracula, Nord, ...) are OPTIONAL and SELECTABLE,
  never mandatory — the user may name one, supply their own palette, or ask for
  none.
metadata:
  tags: remotion, infographics, stills, slides, figures, themes, react
---

# Remotion infographics

A thin convention layer on top of the official Remotion skills. It captures how
Stefano actually builds figures for decks — verified against three real
projects — and deliberately leaves all Remotion *mechanics* to the official
`remotion-best-practices` skill.

## When to use vs. defer

USE this skill when the task is: "make an infographic / figure / diagram for a
slide", "add a figure to the deck", "scaffold an `infographics/` project for
this talk", "re-render the figures", or any deck-figure work in Remotion.

DEFER to the official skills for the underlying API:
- animation, timing, springs, `interpolate`, easing → `remotion-markup` / `remotion-best-practices`
- composition/still registration API details → `remotion-markup`
- rendering flags, `renderStill`, transparency → `remotion-render`
- scaffolding a brand-new Remotion project from zero → `remotion-create`
- looking up any current Remotion doc → `remotion-docs`

This skill sits ON TOP of those. When a rule here and a rule there disagree on
mechanics, the official skill wins; this skill only owns *the infographics
convention*.

## The core convention: still-first, not video

For deck figures the deliverable is a **PNG**, not a video. So:

- Register each figure as a **`<Still>`** (not `<Composition>`) in `src/Root.tsx`.
  A `<Still>` is a single frame — no `fps`, no `durationInFrames`, no timeline.
- Author components as **plain static React** — layout with fl*ex/grid, size in
  px. Do NOT reach for `useCurrentFrame`, `spring`, or `interpolate`; a still
  has one frame, so animation hooks are dead weight. (They are correct for the
  *reel* case below — not for deck figures.)
- Render to the deck's figures directory and let the deck reference the PNG.

Two form-factor families appear in practice, both fine:
- **Talks (dominant): stills.** `hpc-webinar`, `pilot-tutorial` — every figure a `<Still>`.
- **Social reel (exception): video.** `mosaic` — scenes, motion, audio. When the
  ask is a reel/animation, this convention does NOT apply; use the official
  skills' animation rules directly.

## Project layout (convention, verified across projects)

```
infographics/
  package.json          # pinned: remotion + @remotion/cli + react (see PIN below)
  remotion.config.ts    # PNG image format for stills
  tsconfig.json
  src/
    index.ts            # registerRoot(RemotionRoot)
    Root.tsx            # one <Still> per figure, per-figure width/height
    theme.ts            # OPTIONAL — a selected theme preset (see Themes)
    infographics/       # one .tsx component per figure
      <FigureName>.tsx
```

`index.ts` is always exactly:

```ts
import { registerRoot } from "remotion";
import { RemotionRoot } from "./Root";
registerRoot(RemotionRoot);
```

`remotion.config.ts` for a still-only project:

```ts
import { Config } from "@remotion/cli/config";
Config.setVideoImageFormat("png");
```

### PIN

Match the Remotion version already used by the surrounding projects rather than
pulling `latest` blindly — mismatched majors across a machine's decks cause
subtle API drift. As of the last audit (Jul 2026) the pinned set is:

```
remotion            4.0.438
@remotion/cli       4.0.438
react / react-dom   19.2.3
typescript          5.9.3
@types/react        19.2.7
```

When starting a NEW infographics project, copy the pin from an existing deck
(`~/talks/*/infographics/package.json`) unless the user asks to upgrade — then
use the `remotion-upgrade` skill.

## Root.tsx: per-figure sizing is the whole trick

Each figure gets its own canvas dimensions, chosen to fit the slide slot it
lives in. Do NOT force one global canvas. Portrait for a figure column, wide
banner for a full-width strip, square for a cycle diagram, landscape for a
stacked pair. Document the slot in a one-line comment.

```tsx
import React from "react";
import { Still } from "remotion";
import { ThreeAnswers } from "./infographics/ThreeAnswers";
import { PilotLoop } from "./infographics/PilotLoop";

export const RemotionRoot: React.FC = () => {
  return (
    <>
      {/* slide-6 bottom-left — three partial answers + the gap. Landscape. */}
      <Still id="ThreeAnswers" component={ThreeAnswers} width={1200} height={680} />
      {/* PILOT-table slide — five habits as a re-entrant loop. Square. */}
      <Still id="PilotLoop"    component={PilotLoop}    width={800}  height={800} />
    </>
  );
};
```

Parameterised figures (one component, many stills) use `defaultProps` — e.g. a
`DemoTerminal` component rendered at several sizes with a `stage` prop:

```tsx
<Still id="TermSetup"  component={DemoTerminal} width={1180} height={560}
       defaultProps={{ stage: "setup" }} />
<Still id="TermPrompt" component={DemoTerminal} width={1180} height={640}
       defaultProps={{ stage: "prompt" }} />
```

For the props-schema (Zod) mechanics behind `defaultProps`, see the official
`parameters` rule.

## Components: role-semantic, not colour-literal

The single most important convention — it is what makes themes swappable. **Write
components against SEMANTIC ROLES, never hard-coded hex.** A component asks the
theme for `bg`, `panel`, `headline`, `body`, `muted`, and a named accent
(`accents.blue`), and knows nothing about which palette answers.

```tsx
import React from "react";
import { T, FONTS } from "../theme";   // T = the selected theme's role map

export const ThreeAnswers: React.FC = () => (
  <div style={{
    width: 1200, height: 680,
    background: T.bg,                    // role, not "#002b36"
    fontFamily: FONTS.sans,
    display: "flex", flexDirection: "column",
    boxSizing: "border-box", padding: "38px 44px", gap: 24,
    overflow: "hidden",
  }}>
    <div style={{ fontSize: 38, fontWeight: 800, color: T.headline }}>
      Three partial answers
    </div>
    <div style={{
      background: T.panel,
      border: `2px solid ${T.accents.blue}`,
      color: T.body,
    }}>
      ...
    </div>
  </div>
);
```

Rules for portable components:
- Every colour is a role (`T.bg`, `T.panel`, `T.headline`, `T.body`, `T.muted`)
  or a named accent (`T.accents.blue`). No raw hex in a component. Ever.
- `box-sizing: border-box` + a fixed `width/height` matching the `<Still>` +
  `overflow: hidden` — the figure must never bleed past its declared canvas.
- Size type in px against that fixed canvas; these render at exact pixel size.
- Mono font (`FONTS.mono`) for code/tags/counters, sans (`FONTS.sans`) for prose.
- No CSS transitions/animations (they will not render) — irrelevant for stills
  anyway, but stated so the habit carries to the reel case.

The point: the SAME component renders in Solarized-dark, Solarized-light,
Dracula or a user palette with zero edits — only `theme.ts` changes.

## Themes: OPTIONAL and SELECTABLE

Theming is a convenience, not a requirement. Three valid modes:

1. **Named preset.** "do it in Solarized dark" / "...light" / "Dracula" / "Nord".
   Copy the matching preset from `themes/` into the project as `src/theme.ts`.
2. **User palette.** The user hands you colours (or a deck theme to match). Fill
   the same role map with their values; the shipped presets are the template.
3. **No theme.** Use a neutral built-in default (dark, high-contrast). Still go
   through the role map so a theme can be dropped in later without touching
   components.

Always ASK or INFER the theme; never hard-code one. If the figure must match an
existing deck, read the deck's theme (e.g. MaTiSSe `theme-local/theme.yaml`, or
a Beamer/reveal theme) and map its tones onto the roles.

### The role map

`themes/` ships presets. Every preset exports the same shape so components are
interchangeable:

```ts
export const T = {
  bg:       "...",   // page / figure background
  panel:    "...",   // raised panel / card background
  muted:    "...",   // borders, dividers, de-emphasised text
  body:     "...",   // body text
  secondary:"...",   // secondary text (slightly stronger than body)
  headline: "...",   // headline / title text
  accents: { yellow:"", orange:"", red:"", magenta:"", violet:"", blue:"", cyan:"", green:"" },
} as const;

export const FONTS = {
  sans: '...',
  mono: '...',
} as const;
```

Access a named accent by direct record lookup — `T.accents.blue`. (An earlier
draft wrapped this in an `accent()` method; that pattern fails `tsc --strict`
inside a `const` object, so accents are a plain record instead.) For a *dynamic*
accent name, `T.accents[name as keyof typeof T.accents]` type-checks cleanly.

### The light/dark role-swap (why roles beat literals)

Solarized is symmetric: light mode is the dark palette with the base tones
flipped and the accents unchanged. Because components speak in *roles*, a
light theme is just a different role→value mapping — the component code is
untouched. The same trick generalises to any palette that ships a light and a
dark variant. This is the mechanism, distilled from the pilot-tutorial theme:

```
role         Solarized DARK      Solarized LIGHT
bg           base03 #002b36  ->  base3  #fdf6e3
panel        base02 #073642  ->  base2  #eee8d5
muted        base01 #586e75  ->  base1  #93a1a1
body         base0  #839496  ->  base00 #657b83
secondary    base1  #93a1a1  ->  base01 #586e75
headline     base2  #eee8d5  ->  base02 #073642
accents      (yellow..green) UNCHANGED between modes
```

Ship both as separate presets (`solarized-dark.ts`, `solarized-light.ts`) so
selection is "pick a file", not "flip a boolean" — simpler to reason about and
to diff. See `themes/` for the shipped set and `themes/README.md` for how to
add one.

## Render workflow: still → deck figure

Render a single still straight into the deck's figures directory, overwriting:

```bash
cd infographics
npx remotion still <StillId> ../figures/<slide-name>.png --overwrite
```

- `<StillId>` is the `id` from `<Still>` in `Root.tsx`.
- Target the deck's own figures dir so the deck references the PNG directly.
- `--overwrite` because figures are regenerated in place, not versioned copies.
- Keep the re-render command in a comment next to where the figure is used in
  the deck source, so any figure is one copy-paste to regenerate. (This is the
  established habit in `talk.md`.)

`remotion studio` is the live preview while authoring; `remotion still` is the
export. For batch/programmatic rendering of many stills, or transparency, see
the official `remotion-render` skill.

## Scaffolding a new infographics project

When asked to start figures for a new deck:

1. Prefer copying the skeleton from an existing deck's `infographics/`
   (`package.json`, `remotion.config.ts`, `tsconfig.json`, `src/index.ts`) — it
   carries the correct PIN and PNG config. Alternatively use `remotion-create`
   and then strip it to the still-first shape.
2. Drop the selected theme preset in as `src/theme.ts` (or the neutral default).
3. Write `Root.tsx` with one `<Still>` per planned figure, sized to its slot.
4. Author each figure as a role-semantic component under `src/infographics/`.
5. Render into the deck's figures dir.

## Anti-patterns (do not do these)

- Hard-coding hex in a component instead of using a role → breaks theme-swap.
- Using `<Composition>` + `durationInFrames` for a static figure → use `<Still>`.
- One global canvas size forced on every figure → size per slide slot instead.
- Pulling Remotion `latest` for a new deck when sibling decks are pinned → match
  the PIN, upgrade deliberately via `remotion-upgrade`.
- Re-teaching Remotion animation/timing here → that is the official skills' job.
- Mandating a theme → themes are selectable; ask or infer, default neutral.
