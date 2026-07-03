# Publishing DEADZONE on Steam

Step-by-step playbook. Companion to `ITCH.md`. Steam is a bigger lift (fee, review, marketing, tax paperwork) — expect 3-6 months from signup to launch if you're doing it end-to-end. This doc is a reference, not a linear checklist you'd finish in one sitting.

## Reality check

| | Steam | itch.io |
|---|---|---|
| **Cost to publish** | $100 USD one-time (refunded at $1000 lifetime revenue) | Free |
| **Sign-up review** | ~1-2 weeks (tax + banking verification) | Instant |
| **Time to first upload** | ~2-4 weeks from signup | Same day |
| **Store review per build** | 3-5 business days | Instant (no review) |
| **Revenue split** | 70/30 (30% to Valve, less after $10M lifetime) | 90/10 default (100/0 possible) |
| **Discovery model** | Wishlists → New & Trending → algorithmic | Tags + search + browse |
| **Player expectations** | Higher: keybind remap, controllers, cloud saves, achievements | Lower: as-is browser play is fine |

**Realistic timeline for a solo indie:**

- Week 0: sign up, pay fee, submit paperwork
- Week 1-2: paperwork clears, banking verified
- Week 3: App ID granted, start building store page
- Week 4-6: polish + assets + wishlist campaign starts
- Week 7: upload builds, submit for review
- Week 8: review passes, release date set
- Week 8-16: wishlist campaign
- Week 16: launch

For DEADZONE specifically: the game itself is close to shippable. The gap is polish (keybind remap, controller support, credits) and marketing (art, trailer, wishlists). Both are non-trivial.

## Prerequisites checklist

Before spending the $100:

- [ ] You're **18+** (Steamworks contract requires it — legal restriction)
- [ ] You have a **Steam account** with $5+ purchase history (Steam Guard requires this)
- [ ] You have **USD banking info** ready (US: routing/account, international: IBAN + SWIFT). Non-US devs also need local tax ID (e.g., ABN, VAT number)
- [ ] You have **tax forms** on hand (W-9 for US, W-8BEN for international)
- [ ] You've **tested the game on Windows + macOS** as native builds, not just in a browser
- [ ] You're prepared to make **store page assets**: capsule images (multiple sizes), 5+ screenshots, ideally a trailer
- [ ] You have **1-2 weeks of buffer time** for Steam's initial account review

If any of these are "no" — sort them first. The $100 isn't refundable if you back out mid-signup.

## 1. Sign up for Steamworks Direct

1. Go to <https://partner.steamgames.com>
2. Log in with your Steam account
3. Read the Steam Distribution Agreement carefully — it's the actual contract you're signing
4. Complete the tax interview:
   - **US devs:** W-9, requires SSN
   - **International:** W-8BEN, requires local tax residency proof
5. Complete banking info (currency, account details)
6. Pay $100 USD via credit card
7. **Wait 1-2 weeks** for Valve to verify tax + banking. You'll get email confirmation when approved.

## 2. Create your app

Once approved:

1. Steamworks Home → **"Create New App"**
2. App name: `DEADZONE`
3. App type: **Game**
4. You'll receive an **App ID** (e.g., `1234567`) — this is the load-bearing identifier for every subsequent step. Write it down.
5. From App Landing Page, generate a **Publisher Key** (Steamworks → Users & Permissions → Manage Groups → Owner) — this is what SteamPipe uses to authenticate build uploads.

You now have:
- **App ID:** the game
- **Depot IDs:** typically `App ID + 1` for each platform depot Steam auto-creates (`AppID+1` = base, `AppID+2` = Windows, `AppID+3` = macOS, `AppID+4` = Linux). Check under **App Admin → Depots**.

## 3. Build shippable binaries

Same script as itch:

```sh
cd desktop
npm install                    # first time only
bash scripts/build-all.sh      # produces native app for current OS
```

**Cross-platform note:** SteamPipe requires a build for each platform you claim to support. Practical solutions:

- Build on each OS you have access to (Mac at home, Windows VM or friend's PC, Linux Docker)
- Use GitHub Actions matrix workflow to build all three from CI (there's a `electron-builder` action)
- Ship Windows-only for launch, add Mac + Linux later

### Code signing — the real gotcha

**Windows:** unsigned `.exe` files trigger SmartScreen warnings ("Windows protected your PC"). Users can bypass but many won't. To avoid:
- Get an **EV Code Signing Certificate** (~$400-600/year from SSL.com, DigiCert, Sectigo)
- Or an **OV certificate** (~$200-300/year, cheaper but takes 30-60 days to build reputation)
- Sign via `electron-builder`'s built-in signing config in `package.json`

**macOS:** unsigned `.dmg` and `.app` fail Gatekeeper entirely — users see "cannot be opened because the developer cannot be verified." To avoid:
- Join **Apple Developer Program** ($99/year)
- Get a Developer ID Application certificate
- Sign + notarize via `electron-builder`'s built-in support

**Linux:** signing not required, works out of the box.

**For DEADZONE at v0.1 / first ship:** you can technically upload unsigned builds to Steam. Steam's own launcher bypasses OS security warnings when it runs your game, so signed vs. unsigned matters less on Steam than for direct itch downloads. **But** if a user launches the .exe directly (not via Steam), they'll see warnings. Sign for a professional launch; skip for a soft beta.

## 4. Upload via SteamPipe

SteamPipe is Steam's build upload tool. It reads VDF config files that tell it which files ship in which depot.

### Install steamcmd

- **macOS:** `brew install steamcmd` (via a homebrew tap) or download from <https://developer.valvesoftware.com/wiki/SteamCMD>
- **Windows:** download from the same URL
- **Linux:** `apt install steamcmd` on Debian/Ubuntu

### Create the VDF config files

Create `desktop/steampipe/` and add three files. Replace `1234567` with your actual App ID.

**`desktop/steampipe/app_build.vdf`** — top-level build config:

```vdf
"appbuild"
{
  "appid" "1234567"
  "desc"  "DEADZONE v0.1.0"
  "buildoutput" "../dist/steampipe_output"
  "contentroot" "../dist"
  "setlive"     ""
  "preview"     "0"
  "local"       ""

  "depots"
  {
    "1234568" "depot_win.vdf"
    "1234569" "depot_mac.vdf"
    "1234570" "depot_linux.vdf"
  }
}
```

**`desktop/steampipe/depot_win.vdf`** — Windows depot:

```vdf
"DepotBuildConfig"
{
  "DepotID" "1234568"
  "FileMapping"
  {
    "LocalPath" "win-unpacked\\*"
    "DepotPath" "."
    "recursive" "1"
  }
  "FileExclusion" "*.pdb"
  "InstallScript" ""
}
```

**`desktop/steampipe/depot_mac.vdf`** — macOS depot:

```vdf
"DepotBuildConfig"
{
  "DepotID" "1234569"
  "FileMapping"
  {
    "LocalPath" "mac-universal/DEADZONE.app/*"
    "DepotPath" "DEADZONE.app"
    "recursive" "1"
  }
}
```

**`desktop/steampipe/depot_linux.vdf`** — Linux depot:

```vdf
"DepotBuildConfig"
{
  "DepotID" "1234570"
  "FileMapping"
  {
    "LocalPath" "linux-unpacked/*"
    "DepotPath" "."
    "recursive" "1"
  }
}
```

**Setting launch options** happens through the Steamworks web UI (App Admin → Installation → Launch Options), not via VDF. Point each platform at the executable path relative to the depot root:

- Windows: `DEADZONE.exe`
- macOS: `DEADZONE.app`
- Linux: `DEADZONE`

### Upload

```sh
# From desktop/steampipe/
steamcmd +login <your_steam_username> +run_app_build app_build.vdf +quit
```

Steam will prompt for the password + Steam Guard code on first run. Upload takes minutes for a small app (DEADZONE is ~200 MB packed per platform).

Track progress at Steamworks → App Admin → **Builds**. New builds start in "Non-live" state — they're uploaded but not what players get.

### Push to a branch

Builds live in **branches**. `default` is what players see. To ship a build:

1. Steamworks → App Admin → Builds
2. Find your uploaded build
3. Set live on branch **default** (or any test branch you've configured)
4. Confirm the app version number

Or set `"setlive" "default"` in `app_build.vdf` to auto-live on upload (risky for production, fine for beta branches).

## 5. Store page

The store page is where Steam sells your game. Everything below is configured through **Steamworks → Store Presence**.

### Capsule images

Steam uses **five** capsule sizes, all required for full store visibility. The sizes are strict — Steam rejects images that don't match exactly.

| Slot | Dimensions | Where it shows |
|---|---|---|
| **Main capsule** | 616 × 353 | Store front, sales, category pages |
| **Small capsule** | 231 × 87 | Search results, sidebar recommendations |
| **Vertical capsule** | 374 × 448 | Featured & Recommended on the home page |
| **Header capsule** | 460 × 215 | Wishlist emails, library, discovery queue |
| **Page background** | 1438 × 810 | Behind your store page above the fold |
| **Library hero** | 3840 × 1240 | User's Library banner (huge — most games skip this initially) |
| **Library logo** | 1280 × 720 with 100 px transparent padding | Overlaid on the hero, so title reads over the art |

Steam has a great [Capsule Image Requirements](https://partner.steamgames.com/doc/store/assets/graphics) doc — bookmark it. If you're commissioning art, brief the artist with these sizes upfront.

### Screenshots

Minimum 5. Recommended 8-12. **1920 × 1080 or higher.** The mock in `desktop/ITCH.md` describes six good scenes to capture — same scenes work for Steam.

Steam auto-generates thumbnails but the source images should be full-res.

### Trailer

Steam wants a video, and it's a big conversion factor. Two options:

- **YouTube link** — Steam embeds it. Fastest option.
- **Upload direct** — MP4 or MOV, 1080p+. Steam serves it as the primary trailer.

For DEADZONE: 30-60 seconds of frantic gameplay. Start with the most visually punchy 3 seconds (boss fight, Absolute Chaos event, or the Dragon firing its laser stream). Cover major game features in the middle. End with the title card + itch.io URL or "Coming to Steam" + wishlist button.

### Long description

Steam's description supports a subset of BBCode. Use `[b]`, `[i]`, `[url=...][/url]`, `[img]`, `[h1]`, `[list]`. Copy-paste-ready template based on the itch description:

```bbcode
[h1]DEADZONE[/h1]

[b]Top-down, wave-based zombie survival shooter.[/b] Written in vanilla JavaScript and HTML5 Canvas — no engine, no dependencies. Runs in any browser AND as a native desktop app.

[h2]Features[/h2]
[list]
[*][b]30+ weapons[/b] across basic, special, gag, and trader tiers
[*][b]10 secondaries[/b] — melee, thrown, decoy, utility
[*][b]6 boss archetypes[/b] cycling every 20 waves + rare Boss Rush event
[*][b]Absolute Chaos[/b] arena effect: every event firing at once
[*][b]Two independent traders[/b] with rotating stock
[*][b]5 hireable pets[/b] including a Dragon that breathes a laser stream
[*][b]Build mode[/b] with prebuilt templates + save/load your own layouts
[*][b]Upgrade tree[/b] with per-wave perk card picks
[*][b]Local co-op[/b] — arrow-key sidekick, one keyboard
[*][b]Sprite editor[/b] — repaint everything
[/list]

[h2]Controls[/h2]
[list]
[*]Keyboard + Mouse: WASD to move, click to fire, F for secondary, B for build mode
[*]Controller (Steam Input): fully supported
[*]Rebind any key from Settings
[/list]

[h2]Made with[/h2]
Vanilla JavaScript, HTML5 Canvas, Web Audio API. No engine, no build step, no dependencies. One HTML file. Source available on GitHub.
```

Steam counts words differently from itch — aim for 200-400 words in the long description.

### Short description

150 characters max. Shows above the fold on the store page. Steam-flavoured version:

> Top-down zombie survival shooter. Waves, upgrades, boss rotations, build mode, co-op. Vanilla JavaScript, single-file. Made for Steam Deck.

### Age rating + content warnings

Steamworks → Store Presence → **Content Survey**. Mandatory. Multi-page questionnaire. For DEADZONE:

- **Violence:** Yes → cartoon/stylized (not photorealistic gore)
- **Blood:** Yes → red blood decals
- **Language:** No
- **Adult content:** No
- **Gambling:** No (weapon RNG isn't gambling per Steam's definition)

Steam uses the survey to assign the equivalent of an ESRB / PEGI rating and to gate the page in certain regions.

### Tags

Steam has its own tag system — user-driven, not developer-driven. You **suggest** tags but the community adds/removes them over time. Suggest these on submission:

- Action, Shooter, Top-Down Shooter, Survival, Zombies, Wave-based, Arcade, Difficult, Indie, Casual, Local Co-Op, Great Soundtrack, Pixel Graphics

### System requirements

Minimal for DEADZONE:

- **Windows:** Windows 10, 4 GB RAM, DirectX 11-capable GPU, 300 MB storage
- **macOS:** macOS 10.15+, 4 GB RAM, 300 MB storage
- **Linux:** Ubuntu 20.04+, 4 GB RAM, 300 MB storage
- **Web:** Chrome/Firefox/Safari current version

## 6. Submit for review

Steamworks → Store Presence → **Publish**.

Steam checks:

1. **Executable actually launches** — the #1 review failure
2. **App name matches store name** — trivial but sometimes off
3. **No malware / trojans** — automated scan
4. **Content matches your rating** — spot check

Turnaround: **3-5 business days** for a first review, faster for updates.

If rejected, you get an email with the reason. Fix, resubmit, wait again. Common rejections:

- Missing Steamworks SDK initialization (you don't need the full SDK, but the app must at least launch cleanly under Steam)
- Wrong launch options (e.g., pointing at a file that doesn't exist in the depot)
- Broken screenshots or capsule images

## 7. Release strategy

### Wishlist campaign

The single most important thing pre-launch. Steam's discovery algorithm rewards games with high wishlist counts on release day — a small wishlist push before launch converts into significant "New & Trending" placement.

- Set the release date **4-8 weeks out** and mark the page **Coming Soon**
- Announce on any channel you use (Twitter/X, Discord, Reddit indie subs)
- Post regular devlogs to Steam Community — Community posts count as your marketing budget
- Ask friends + your itch.io followers (if you shipped there first) to wishlist

Wishlists ≠ purchases, but they signal Steam's algorithm that people care.

### Launch day

1. **Release the build** — flip your default branch build to Live
2. **Publish the release trailer** if you have one
3. **Cross-post** to Twitter, itch.io devlog, Discord
4. **Watch the Community hub** for early bug reports
5. **Hotfix within 24 hours** if a launch-blocking bug shows up (Steam is forgiving of quick patches)

### Sales

- Steam sales happen **~4 times a year** (Summer, Autumn, Winter, Spring)
- You can discount up to 90% but Steam requires a **6-week gap** between sale prices
- Publisher weeks + genre-specific sales come around too

## 8. Post-launch: adding Steamworks features

None of these are required to launch, but they're expected within a few months of release.

### Steam achievements

Requires the Steamworks SDK, but only lightly. In DEADZONE's case:

1. Install a native addon like `steamworks.js` or `greenworks` in `desktop/`:
   ```sh
   npm install steamworks.js
   ```
2. Load it in `preload.js` (already scaffolded for this)
3. Define achievements in Steamworks → App Admin → Achievements
4. Emit unlock calls from the game via the preload bridge

Example additions to `preload.js`:

```js
const { contextBridge } = require('electron');
const steamworks = require('steamworks.js');

// Init Steamworks against your App ID
const client = steamworks.init(1234567);

contextBridge.exposeInMainWorld('steam', {
  unlockAchievement: (id) => client.achievement.activate(id),
  isAchievementUnlocked: (id) => client.achievement.isActivated(id),
  storeStats: () => client.stats.store(),
});
```

Then in the game (`index.html`), call `window.steam?.unlockAchievement('FIRST_WAVE')` at the right moment.

### Cloud saves

Steamworks handles cloud sync **automatically** if you follow their save file convention (put saves in a designated user directory). Or use their Steam Cloud API from `preload.js` for explicit control.

For DEADZONE: the current save uses `localStorage` which Electron persists per user profile. To sync via Steam Cloud, migrate saves to a file in `app.getPath('userData')` and mark that path in Steamworks → App Admin → Cloud.

### Steam Overlay

Works with any Electron app without integration — Steam injects the overlay into any process it launches. Just make sure your fullscreen mode doesn't block the overlay hotkey (default Shift+Tab).

### Trading cards

- Automatic once you cross a revenue threshold
- Design 5-10 card art assets (specs in Steamworks)
- Fully passive: players earn cards by playing, and Steam sells booster packs

## Cost breakdown

| Item | Cost |
|---|---|
| Steamworks Direct fee | $100 USD (refunded at $1000 lifetime revenue) |
| Windows code signing cert (optional but recommended) | $200-600/year |
| Apple Developer Program (for Mac signing + notarization) | $99/year |
| Trailer production (if outsourced) | $200-2000 |
| Capsule art (if commissioned) | $200-1500 |
| **Realistic minimum spend** | **$100** |
| **Realistic launch-ready spend** | **$500-2000** |

## Quick reference: the whole flow

1. Sign up + pay $100 → wait ~2 weeks for approval
2. Get App ID → note it down, use it everywhere
3. Build binaries with `bash scripts/build-all.sh` on each target OS
4. (Optionally) code-sign the Windows + macOS binaries
5. Write `app_build.vdf` + `depot_*.vdf` under `desktop/steampipe/`
6. Upload with `steamcmd +login <user> +run_app_build app_build.vdf`
7. Set the build live on `default` branch via Steamworks web UI
8. Create the store page — capsules, screenshots, trailer, description, tags
9. Submit for review → wait 3-5 business days
10. Set release date 4-8 weeks out, run wishlist campaign
11. Ship
12. Iterate: patches, achievements, cloud saves, sales

## Related docs

- `README.md` — Electron wrapper how-to
- `ITCH.md` — itch.io publishing playbook (recommended stepping stone before Steam)
- Steamworks docs: <https://partner.steamgames.com/doc/home>
- SteamCMD reference: <https://developer.valvesoftware.com/wiki/SteamCMD>
- Capsule image spec: <https://partner.steamgames.com/doc/store/assets/graphics>
- Steam Direct FAQ: <https://partner.steamgames.com/doc/gettingstarted/appfee>
