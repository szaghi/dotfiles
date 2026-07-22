// Neutral default — used when the user names NO theme.
// A plain high-contrast dark palette with a conventional accent set. Going
// through the role map (rather than hard-coding) means a named preset can be
// dropped in later without touching any component.

export const T = {
  bg: "#101418", // near-black background
  panel: "#1b2128", // raised panel / card
  muted: "#556070", // borders, dividers, de-emphasised
  body: "#c4ccd6", // body text
  secondary: "#e0e6ec", // secondary text
  headline: "#f4f7fa", // headline / title
  accents: {
    yellow: "#e0b341",
    orange: "#e08a3c",
    red: "#e05561",
    magenta: "#d06bc4",
    violet: "#8b7ce0",
    blue: "#4a9ee0",
    cyan: "#3fb6ad",
    green: "#66bb6a",
  },
} as const;

export const FONTS = {
  sans: '"Inter", system-ui, sans-serif',
  mono: '"JetBrains Mono", monospace',
} as const;
