# Publishing DEADZONE on itch.io

Step-by-step playbook. Everything below assumes the current version is what's in `package.json` (`0.1.0` on first pass — bump before each release, and update `GAME_VERSION` in `../index.html` to match).

## 1. Prep the itch.io side (one-time)

1. Sign up at <https://itch.io/register> if you haven't.
2. Create the game page: <https://itch.io/game/new>
   - **Title:** `DEADZONE`
   - **Project URL:** `deadzone` (final URL: `lxreyes.itch.io/deadzone`)
   - **Classification:** Games
   - **Kind of project:** HTML (you'll add downloadable native builds later — HTML unlocks browser-play, which downloadable-only doesn't)
   - **Pricing:** Free (or "Pay what you want" with $0 minimum — lets people tip)
   - **Visibility:** Draft while you're setting up. Flip to Public when the store page is ready.
3. Install butler CLI (used by `scripts/upload-itch.sh` later):
   - Download from <https://itch.io/docs/butler/installing.html>
   - `butler login` — opens a browser to grab an API key, stores it locally
   - Verify: `butler status lxreyes/deadzone`

## 2. Build all shippable artifacts

```sh
cd desktop
npm install                    # first time only
bash scripts/build-all.sh      # produces HTML5 zip + native app for THIS OS
```

Outputs land in `desktop/dist/`. Filenames follow the pattern `DEADZONE-<version>-<platform>-<arch>.<ext>`.

**Cross-platform note:** electron-builder can't cross-compile from macOS → Windows out of the box (needs Wine + additional deps). Simplest flow: run `bash scripts/build-all.sh` once on each OS you have access to. If you only have macOS, ship Mac + browser-playable HTML5 first — Windows/Linux later.

## 3. Upload

**Option A — one command (recommended once butler is set up):**

```sh
bash scripts/upload-itch.sh
```

Pushes every artifact in `dist/` to the matching itch.io channel (`html5`, `mac`, `win`, `linux`). Version stamps come from `package.json`.

**Option B — manual:**

Drag-drop each file at `https://itch.io/game/edit/<gameid>/uploads`. For the HTML5 zip specifically:

- **Kind of file:** HTML
- **This file will be played in the browser:** ✅ check
- **Embed options:**
  - Embed viewport: `1200 × 680`
  - Frame options: `Click to launch in fullscreen` ✅
  - Enable scrollbars: ❌ off
  - Mobile friendly: your call (the game auto-detects touch and swaps to on-screen controls, so ON works well)

## 4. Store page setup

Fill these in on the game page. Recommended values below — tweak to taste.

### Cover image
- **910 × 428 PNG or JPG** — the main hero banner.
- Alternate: `315 × 250` mini-thumbnail (auto-crops from the hero if not set).
- If you don't have art, drop a rendered screenshot of the game at wave 5+ with a big boss on screen and overlay the DEADZONE logo. Any painting app.

### Screenshots
- **5+ screenshots** — bare minimum. Suggested shots:
  1. Player firing into a horde (title-screen-adjacent — action shot)
  2. Boss fight (a Warlord or Berserker mid-charge)
  3. Shop UI with the trader visible
  4. Build mode with a completed base (Turret Nest template or a hand-placed layout)
  5. Absolute Chaos event with the banner + multiple sub-events firing
  6. Upgrade tree with several perks unlocked (shows depth)
- **Format:** `1200 × 680` PNG (matches the game's internal canvas — no scaling artefacts)

### Trailer (optional but drives conversion)
- **30–60 second clip.** Simple: OBS record 90 seconds of frantic gameplay, cut to the best 30. Upload to YouTube unlisted, paste the link into itch.

### Short description (140-char TL;DR)
```
Top-down zombie survival shooter. Wave-based. Two traders, six boss archetypes, procedural music, sprite editor, co-op. Single-file HTML5.
```

### Long description (markdown supported on itch)
Template — edit before pasting:

```markdown
**DEADZONE** is a top-down wave-based zombie survival shooter, written in vanilla JavaScript and Canvas 2D — no engine, no dependencies, one HTML file.

## Features
- **30+ weapons** across basic, special, gag, trader-exclusive, and food-themed tiers
- **10 secondaries** — melee, thrown, decoy, and utility
- **6 boss archetypes** cycling every 20 waves + a rare **Boss Rush** meta-event
- **Absolute Chaos** arena event where every other event spams at once
- **Two independent traders** with rotating stock — the pink Food Trader visits more often but sells cheaper wares
- **5 pets** you can hire from the shop — the apex Dragon breathes a sustained laser stream
- **Build mode** with walls, turrets, spike traps, mortars, heal pylons + **prebuilt base templates** + a Save/Load layout system
- **Upgrade tree + perk card picks** every wave
- **Local co-op** — one keyboard, arrow-key second player
- **Sprite editor** — repaint the player, zombies, guns, bullets, and both traders
- **Guided in-game tutorial** for first-timers
- Runs in any browser, or as a native Windows/macOS/Linux app

Made with vanilla JS + Canvas 2D + Web Audio. No engines, no dependencies, no build step.

## Controls
- `WASD` or arrow keys — move
- Mouse — aim, LMB fires, RMB uses secondary
- `Shift` — dash
- `E` — pick up gun · `F` — pick up secondary
- `B` — build mode · `T` — upgrade tree
- `Z X C V G H` — abilities (once unlocked)
- `Escape` — pause · `F11` — fullscreen · `M` — mute

Try the browser build above, or download a native app.
```

### Tags (up to 10)
```
action, arcade, canvas, casual, difficult, javascript, top-down, wave-based, zombies, shooter
```

Pick 8-10; itch tags drive search discovery.

### Genre + Classification
- **Genre:** Action / Shooter
- **Made with:** JavaScript
- **Average session:** A few minutes
- **Languages:** English
- **Inputs:** Keyboard, Mouse, Touchscreen
- **Accessibility:** Color-blind friendly (you built it that way — mostly), subtitles N/A

### Community & links
- **Community:** Comments (default) — good enough. Disqus if you already use it.
- **Trailer / video:** YouTube URL from step 3 above
- **External link:** Link back to `https://lxreyes.github.io/deadzone/` if you want to preserve the Portfolio version too. Not required.

## 5. Publish + share

1. Set page **Visibility → Public** at the top of the edit page.
2. Grab the direct link (e.g. `https://lxreyes.itch.io/deadzone`) — this is your share URL.
3. Announce on any channel you already use: Discord, Twitter/X, Reddit's `/r/webgames` or `/r/incrementalGames` (mind their rules), the Portfolio site, etc.
4. Watch analytics: `https://itch.io/game/edit/<gameid>/analytics` shows visits + downloads. Free.

## 6. Iterate

Every time you ship a new version:

1. Bump `desktop/package.json` `version` field.
2. Bump `GAME_VERSION` in `../index.html` to match.
3. Update the "History of major features" in `../CLAUDE.md` (per its own directive).
4. `bash scripts/build-all.sh` → `bash scripts/upload-itch.sh`
5. Update the store page "Development log" — a short devlog on each release is what turns casual players into followers.

## Common pitfalls

- **HTML5 upload keeps loading forever.** The zip must have `index.html` at the ROOT — check with `unzip -l desktop/dist/deadzone-v<v>-html5.zip`. `build-html5.sh` handles this via `zip -j`.
- **Embed viewport looks cropped on mobile.** itch's mobile view respects the embed size but wraps in browser chrome; the game auto-detects touch and reflows internally. Test on a phone before wide release.
- **butler push says "no channel matching name".** Channels are just labels — the first push to `<user>/<game>:<label>` creates it. Typos silently create new empty channels; delete them from the itch.io uploads page if you fat-finger one.
- **butler push complains "userversion required".** The script passes `--userversion` from `package.json`; if you're pushing manually, add `--userversion 0.1.0` or itch enforces channel-only versioning which is fiddlier.
