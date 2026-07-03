# DEADZONE — Desktop Wrapper

Electron shell that packages the game into a standalone desktop app. The game itself is still the single `../index.html` file — this directory just wraps a Chromium window around it and produces installer-ready `.exe` / `.app` / `.AppImage` builds for Windows, macOS, and Linux.

## Prerequisites

- **Node.js 20 or newer** — install from <https://nodejs.org> (LTS is fine).
- ~500 MB free disk for `node_modules` and the Chromium runtime.

## Run in dev

```sh
cd desktop
npm install       # first time only — pulls Electron + electron-builder
npm start         # opens the game in a real desktop window
```

`main.js` looks for `./index.html` first, then falls back to `../index.html`, so during dev it loads the same file that ships to the web version. Edits to `../index.html` show up on next launch (or `Ctrl+R` inside the app).

Press `F11` for fullscreen. Press `F12` for dev tools (only in unpackaged builds).

## Produce a shippable build

Each command below produces installers in `desktop/dist/`. You can only build for a platform *from* that platform (Windows builds need Windows, etc.) unless you set up cross-build tooling.

```sh
npm run build:win     # Windows: NSIS installer + portable .exe
npm run build:mac     # macOS: DMG + zip (universal arch — Intel + Apple Silicon)
npm run build:linux   # Linux: AppImage + tar.gz
npm run build         # current platform only
```

Outputs live in `dist/`. Names follow `DEADZONE-0.1.0-<platform>-<arch>.<ext>`. Bump `version` in `package.json` before each release.

## Icons

Drop a `desktop/resources/icon.png` (**at least 512×512**, PNG with transparency) before running a build. electron-builder converts it to the right format per platform automatically (`.ico` for Windows, `.icns` for macOS). Without an icon you get Electron's default — fine for testing, not for a store page.

## Path to itch.io

itch.io is the fastest place to ship. Two upload variants:

**1. Browser-playable HTML5 (no wrapper needed):**

```sh
cd ..
zip -j deadzone-html5.zip index.html
```

Upload the zip on itch.io, set kind to "HTML", check "This file will be played in the browser", set embed size to `1200×680`, enable fullscreen button. Done — anyone can play from any browser.

**2. Downloadable desktop builds (uses this wrapper):**

Run `npm run build:win` / `build:mac` / `build:linux` for each platform you can build on, upload each output to itch.io with kind "Windows executable" / "macOS application" / "Linux executable". Users download and run natively — same code, less browser tab.

Ship both. Browser reach + downloadable convenience covers everyone.

## Path to Steam

Rough order — each step gates the next:

1. **Wrap the game** (this directory). ✅
2. **Polish for desktop expectations:**
   - Fullscreen + resolution scaling (F11 exists; internal 1200×680 stays constant with letterboxing).
   - Keyboard remapping UI (Steam users expect this).
   - Controller support via Steam Input, or in-game gamepad mapping.
   - Save slot management (currently one save via localStorage — expected on browser, less so on desktop).
   - Menu polish: credits screen, "Quit to menu" vs "Quit to desktop", settings persistence.
3. **Sign up on Steamworks Direct** at <https://partner.steamgames.com>. Pay the **$100 USD one-time app fee** and complete tax + banking paperwork (allow 2–3 weeks).
4. **Build store assets:** capsule images (main / vertical / small / hero), 5+ screenshots, 30-second trailer, short + long description, tags, genres, content warnings.
5. **Upload builds** via `steamcmd` / `steampipe`. Each platform ships as a separate depot; you configure the launch executable per depot.
6. **Submit for review.** Valve mainly checks that the app launches cleanly and doesn't behave maliciously. Turnaround is usually a few business days.
7. **Set a release date + collect wishlists.** Wishlist count pre-launch drives the "New & Trending" tab, which is Steam's discovery engine. Consider running the wishlist page for 4-8 weeks before release.
8. **(Later)** Add Steamworks features: achievements, cloud saves, Steam overlay integration. These live in `preload.js` via a native addon like [`greenworks`](https://github.com/greenheartgames/greenworks) or [`steamworks.js`](https://github.com/ceifa/steamworks.js).

## Notes on the wrapper

- **contextIsolation: true** and **sandbox: true** are Electron security best practices. The game code runs isolated from the Node integration; the only bridge is `preload.js` (currently empty — future Steam SDK hooks live there).
- **No dev tools in packaged builds** — F12 is gated on `!app.isPackaged`.
- **Menu bar hidden by default** so the app feels native. Alt momentarily shows it.
- **Backup color** `#0a0a12` matches the arena floor tint, so there's no white flash before the canvas paints.
- **Universal Mac arch** — one binary works on Intel + Apple Silicon (larger download, cleaner distribution).
