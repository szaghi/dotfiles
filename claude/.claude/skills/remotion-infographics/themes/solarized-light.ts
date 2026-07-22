// Solarized LIGHT — Schoonover's palette, light mode.
// Solarized is symmetric: light mode = dark mode with the base tones flipped,
// accents unchanged. Because remotion-infographics components speak in ROLES,
// this preset re-themes every figure light with zero component edits — the
// role→value mapping below is the only thing that differs from solarized-dark.ts.
// (See the role-swap table in ../SKILL.md.)

export const T = {
  bg: "#fdf6e3", // base3  — lightest background (was darkest in dark mode)
  panel: "#eee8d5", // base2  — raised panel / card
  muted: "#93a1a1", // base1  — borders, dividers, de-emphasised
  body: "#657b83", // base00 — body text
  secondary: "#586e75", // base01 — secondary text (darker for contrast on light)
  headline: "#073642", // base02 — headline / title text (dark on light)
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
