/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    "./src/app/**/*.{js,jsx}",
    "./src/components/**/*.{js,jsx}",
    "./src/lib/**/*.{js,jsx}"
  ],
  theme: {
    extend: {
      colors: {
        background: "rgb(var(--bg) / <alpha-value>)",
        surface: "rgb(var(--surface) / <alpha-value>)",
        text: "rgb(var(--text) / <alpha-value>)",
        muted: "rgb(var(--muted) / <alpha-value>)",
        border: "rgb(var(--border) / <alpha-value>)",
        primary: "rgb(var(--primary) / <alpha-value>)",
        "primary-foreground": "rgb(var(--primary-foreground) / <alpha-value>)",
        accent: "rgb(var(--accent) / <alpha-value>)",
        "accent-foreground": "rgb(var(--accent-foreground) / <alpha-value>)",
        "badge-drafted": "rgb(var(--badge-drafted) / <alpha-value>)",
        "badge-drafted-foreground": "rgb(var(--badge-drafted-foreground) / <alpha-value>)",
        "badge-submitted": "rgb(var(--badge-submitted) / <alpha-value>)",
        "badge-submitted-foreground": "rgb(var(--badge-submitted-foreground) / <alpha-value>)",
        "badge-approved": "rgb(var(--badge-approved) / <alpha-value>)",
        "badge-approved-foreground": "rgb(var(--badge-approved-foreground) / <alpha-value>)",
        "badge-rejected": "rgb(var(--badge-rejected) / <alpha-value>)",
        "badge-rejected-foreground": "rgb(var(--badge-rejected-foreground) / <alpha-value>)"
      }
    }
  },
  plugins: []
};
