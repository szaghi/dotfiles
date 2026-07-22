// Nord — the Nord palette (nordtheme.com), dark.
// A third preset, to make the point that any palette drops into the same role
// map. Copy into a project as src/theme.ts.

export const T = {
  bg: "#2e3440", // nord0  — polar night, background
  panel: "#3b4252", // nord1  — raised panel
  muted: "#4c566a", // nord3  — borders, de-emphasised
  body: "#d8dee9", // nord4  — body text
  secondary: "#e5e9f0", // nord5  — secondary text
  headline: "#eceff4", // nord6  — headline / title
  accents: {
    yellow: "#ebcb8b", // nord13
    orange: "#d08770", // nord12
    red: "#bf616a", // nord11
    magenta: "#b48ead", // nord15
    violet: "#b48ead", // nord15 (Nord has no distinct violet)
    blue: "#5e81ac", // nord10
    cyan: "#88c0d0", // nord8
    green: "#a3be8c", // nord14
  },
} as const;

export const FONTS = {
  sans: '"Inter", system-ui, sans-serif',
  mono: '"JetBrains Mono", "Fira Code", monospace',
} as const;
