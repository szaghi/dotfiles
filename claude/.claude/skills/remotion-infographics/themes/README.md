# Theme presets

Each file here is a self-contained theme preset for `remotion-infographics`.
They all export the **same shape** — a role map `T` and a `FONTS` object — so
figure components (which speak in roles, never raw hex) are interchangeable
across every preset. Selecting a theme is "copy one file to `src/theme.ts`".

## Shipped presets

| File | Palette | Mode |
|---|---|---|
| `solarized-dark.ts`  | Solarized (Schoonover) | dark |
| `solarized-light.ts` | Solarized (Schoonover) | light |
| `dracula.ts`         | Dracula | dark |
| `nord.ts`            | Nord | dark |
| `neutral.ts`         | Generic high-contrast | dark (the no-theme default) |

## How to use one

```bash
cp <preset>.ts <project>/infographics/src/theme.ts
```

Components import from it:

```ts
import { T, FONTS } from "../theme";
// ... background: T.bg, color: T.headline, border: `2px solid ${T.accents.blue}`
```

Swapping the theme = replacing `src/theme.ts` with a different preset and
re-rendering. No component changes.

## The role map (contract)

Every preset MUST export exactly this shape:

```ts
export const T = {
  bg:        string;   // page / figure background
  panel:     string;   // raised panel / card background
  muted:     string;   // borders, dividers, de-emphasised text
  body:      string;   // body text
  secondary: string;   // secondary text (slightly stronger than body)
  headline:  string;   // headline / title text
  accents:   { yellow; orange; red; magenta; violet; blue; cyan; green };
};
export const FONTS = { sans: string; mono: string };
```

Access accents by direct record lookup: `T.accents.blue`. (No `accent()`
method — that pattern fails `tsc --strict` inside a `const` object.) Every
preset is `as const`, so all eight accent keys must be present.

## Adding a preset

1. Copy the closest existing file (Solarized dark for a base16-style palette).
2. Fill every role from the target palette. Keep all eight accent keys present
   even if two map to the same hue (see Nord's violet≈magenta) — components may
   reference any accent by name, so none may be missing.
3. Ensure contrast: `headline`/`body` must read clearly on `bg` and on `panel`.
   For a LIGHT variant of a symmetric palette, flip the base tones and keep the
   accents (see `solarized-light.ts`).
4. List it in the table above.

## Matching an existing deck instead of a preset

If figures must match a deck's theme, read the deck's palette source (MaTiSSe
`theme-local/theme.yaml`, a Beamer colour theme, a reveal.js theme) and fill the
role map with those values — the presets are the template. This is the
"user palette" mode in `../SKILL.md`.
