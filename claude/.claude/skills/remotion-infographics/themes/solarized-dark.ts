// Solarized DARK — Ethan Schoonover's palette, dark mode.
// Role map for remotion-infographics. Copy this file into a project as
// src/theme.ts to render figures in Solarized dark. Components speak in ROLES
// (T.bg, T.headline, T.accent("blue")), so swapping this file for another
// preset re-themes every figure with zero component edits.
//
// Pairs with solarized-light.ts: same accents, base tones flipped (see the
// role-swap table in ../SKILL.md).

export const T = {
  bg: "#002b36", // base03 — darkest background
  panel: "#073642", // base02 — raised panel / card
  muted: "#586e75", // base01 — borders, dividers, de-emphasised
  body: "#839496", // base0  — body text
  secondary: "#93a1a1", // base1  — secondary text
  headline: "#eee8d5", // base2  — headline / title text
  accents: {
    yellow: "#b58900",
    orange: "#cb4b16",
    red: "#dc322f",
    magenta: "#d33682",
    violet: "#6c71c4",
    blue: "#268bd2",
    cyan: "#2aa198",
    green: "#859900",
  },
} as const;

export const FONTS = {
  sans: '"DejaVu Sans", "Inter", system-ui, sans-serif',
  mono: '"JetBrains Mono", "DejaVu Sans Mono", monospace',
} as const;
