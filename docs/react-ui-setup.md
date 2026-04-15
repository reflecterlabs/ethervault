# React UI Setup (shadcn + Tailwind + TypeScript)

This repository is currently Worker-first. It does not include a full React app runtime by default.

The components are integrated at:
- `components/ui/etheral-shadow.tsx`
- `components/ui/demo.tsx`
- `components/ui/beams-background.tsx`

## Why `components/ui` matters

shadcn/ui generators and team conventions expect reusable primitives in `components/ui`.
Keeping this path makes generated components predictable, easier to import, and easier to maintain.

## Default paths in this repository

- Components path: `components/ui`
- Styles path in current Worker landing: `public/index.html` (inline CSS)

This repo is not a full React app by default, so there is no global Tailwind stylesheet yet.

## Why keeping `components/ui` is important

`components/ui` aligns with shadcn conventions and avoids import drift. If teams place reusable UI in random folders, generated component updates and shared imports become inconsistent.

## Required dependencies installed

- `react`
- `react-dom`
- `framer-motion`
- `motion`
- `lucide-react`

The `BeamsBackground` component already uses the active hero palette from `public/index.html`:
- Base gradient: `#120722` -> `#1f0f39` -> `#2a1450`
- Accent glow: pink-magenta (`rgba(255, 95, 166, ...)`)

## Option A: Add React app in this repo with Vite + Tailwind + shadcn

1. Create a UI app folder:

```bash
npm create vite@latest web -- --template react-ts
cd web
npm install
```

2. Install Tailwind:

```bash
npm install -D tailwindcss postcss autoprefixer
npx tailwindcss init -p
```

3. Configure `tailwind.config.ts` content globs:

```ts
content: [
  './index.html',
  './src/**/*.{js,ts,jsx,tsx}',
  '../components/**/*.{js,ts,jsx,tsx}'
]
```

4. Add Tailwind directives in `web/src/index.css`:

```css
@tailwind base;
@tailwind components;
@tailwind utilities;
```

5. Initialize shadcn/ui:

```bash
npx shadcn@latest init
```

6. Copy integrated component into the app (or import from `../components/ui`):
- `../components/ui/etheral-shadow.tsx`
- `../components/ui/demo.tsx`

7. Render demo in `web/src/App.tsx`.

## Option B: Next.js + shadcn

```bash
npx create-next-app@latest web --ts --tailwind --eslint --app
cd web
npx shadcn@latest init
```

Then copy files to `web/components/ui` and render `DemoOne` in `web/app/page.tsx`.

## Assets note

The component already uses Unsplash assets directly for background and noise textures.
