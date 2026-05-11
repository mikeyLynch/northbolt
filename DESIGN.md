# Design System

Reference for all UI decisions. Follow this before writing any view or component.

---

## Colours

Three colours only. No exceptions without a discussion.

| Role | Tailwind token | Hex |
|---|---|---|
| Background | `white` / `gray-50` | #ffffff / #f9fafb |
| Primary text & actions | `gray-900` | #111827 |
| Secondary text & borders | `gray-400` / `gray-200` | #9ca3af / #e5e7eb |

`gray-50` is used as a subtle section break against white — not as a standalone background colour.

No blue. No indigo. No brand accent colour at this stage.

---

## Typography

- Font: system sans-serif (Tailwind default — no custom font loaded yet)
- Headings: `font-bold` or `font-extrabold`, `tracking-tight`
- Body: `text-gray-500` for supporting copy, `text-gray-900` for primary content
- Small labels / metadata: `text-sm text-gray-400`

---

## Buttons & Links

**Primary button** — used for the main CTA on a page:
```
bg-gray-900 text-white hover:bg-gray-700 px-5 py-2.5 rounded-lg text-sm font-semibold transition-colors
```

**Secondary / ghost button** — used for lower-priority actions:
```
text-gray-700 hover:text-gray-900 text-sm font-semibold
```

**Destructive button** — sign out, delete:
```
bg-white text-gray-900 border border-gray-200 hover:bg-gray-50 px-5 py-2.5 rounded-lg text-sm font-semibold transition-colors
```

One primary CTA per page. Do not use multiple filled buttons side by side.

---

## Components

- Corners: `rounded-lg` on buttons and inputs, `rounded-xl` on cards and panels
- Borders: `border border-gray-200` — subtle, not heavy
- Shadows: avoid unless necessary. Prefer borders over shadows.
- Dividers: `border-t border-gray-100`
- No emojis anywhere in the UI

---

## Layout

- Max content width: `max-w-6xl mx-auto` for full-width sections, `max-w-3xl` for centred prose
- Horizontal padding: `px-6` on all sections
- Section vertical rhythm: `py-20` between major sections

---

## Tone

Clean, professional, minimal. The product is a security device for business operators — the UI should reflect that. No decorative flourishes, no playful copy, no emojis.
