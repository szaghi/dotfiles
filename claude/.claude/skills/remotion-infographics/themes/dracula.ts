// Dracula — the standard Dracula palette (draculatheme.com), dark.
// Shipped to prove the role map is genuinely palette-agnostic: same component
// code, different preset. Copy into a project as src/theme.ts.

export const T = {
  bg: "#282a36", // background
  panel: "#44475a", // current-line / selection — raised panel
  muted: "#6272a4", // comment — borders, de-emphasised
  body: "#f8f8f2", // foreground — body text
  secondary: "#bd93f9", // purple — secondary text accent
  headline: "#f8f8f2", // foreground — headline (bump weight, not colour)
  accents: {
    yellow: "#f1fa8c",
    orange: "#ffb86c",
    red: "#ff5555",
    magenta: "#ff79c6", // pink
    violet: "#bd93f9", // purple
    blue: "#8be9fd", // cyan-ish blue
    cyan: "#8be9fd",
    green: "#50fa7b",
  },
} as const;

export const FONTS = {
  sans: '"Inter", system-ui, sans-serif',
  mono: '"JetBrains Mono", "Fira Code", monospace',
} as const;
