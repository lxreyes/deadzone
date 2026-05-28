# DEADZONE

Top-down, wave-based zombie survival shooter. Single self-contained HTML file. Vanilla JS + Canvas 2D + Web Audio API (procedural SFX only — no audio files). No build step, no dependencies.

## Run

Open `index.html` in any modern browser (double-click, or `open index.html` on macOS). No server needed. Hosted on GitHub Pages from `main`.

## Files

- `index.html` — **everything**: HTML scaffold, CSS, and one inline `<script>` block (~11.6k lines). Treat this as the entire project.
- `CLAUDE.md` — this file. Treated as a **living doc** — update it after shipping non-trivial features (see "Keeping this file current" at the bottom).

There are no other source files, configs, or dependencies. The user prefers it stay that way — keep new features in the same file unless they explicitly ask to split.

## Controls (player-facing)

Desktop keyboard / mouse:

- `WASD` / arrows — move (arrows are P2 once co-op is on)
- mouse — aim · hold LMB — fire (auto). RMB fires the equipped secondary.
- `Shift` — dash (default ability; ~1.4s cooldown, 0.45s i-frames)
- `Q` — release the bow (when held)
- `E` — equip the gun pickup you're hovering · `F` — equip the secondary crate you're hovering
- `Space` — manually begin the next wave (no auto-advance) / dismiss banner
- `1`–`9` — buy upgrade row (only while standing inside the shop rect)
- `B` — toggle build mode (wall / turret / spike trap; click to place on grid)
- `T` — open the upgrade tree (perk picks driven by `player.exp`)
- `Z` / `X` / `C` / `V` / `G` / `H` — abilities: `bulletTime` / `rage` / `phase` / `homing` / `pull` / `storm` (each must be unlocked first; cooldown via `abilityLast`)
- `R` — opens a "Reset?" confirmation modal (then `Enter` / `Y` confirms, `Escape` / `N` cancels)
- `M` — toggle mute · `Tab` — toggle stats panel (not in shop / card pick)
- `Escape` — pause / back / close menus (eats reset-confirm first)

Touch / iOS: `isTouch` detects mobile and adds `body.touch` (strips desktop chrome). UI: left-side virtual joystick, right-side `2ND` / `ABIL` / `SWAP` buttons, top-right `☰` pause. `fitCanvas()` rescales on resize/orientation. `autoShoot` defaults true on touch.

**Cheats panel** (top-left): hidden until the player types `1 2 3 4` outside the shop (rolling 4-char buffer). Once unlocked, the panel is grouped into collapsible sections. Toggles (god mode, mute, co-op enable, auto-shoot) live in Settings now; cheats keeps spawn / loadout / boss / arena buttons.

## Audio

`AudioContext` is lazy-init'd on the first user gesture (`ensureAudio()` + `resumeAudio()` in the keydown/mousedown handlers). Two primitives — `tone(...)` and `noise(...)` — feed `masterGain` (0.32). The `SFX` dispatch dict has one entry per game event (shoot/zombieHit/zombieDie/playerHurt/explosion/coin/pickup/crate/swap/swing/throwBlade/chestOpen/perkPick/waveStart/bossSpawn/uiClick/unlock/death). Rapid-fire events call `sfxThrottle(name, gapMs)` to avoid crackle. `soundMuted` is a global gate.

## Mental model

State is **all top-level**, no classes. The game loop `tick()` lives at the bottom of the script, wraps `tickBody()` in a try/catch (see "Error capture"), and calls `updateX(dt)` functions followed by `render()`. Coords are screen-space pixels; world == viewport (canvas fixed at 1200×680).

### Entity arrays (iterate backwards when splicing)

`bullets`, `zombieBullets`, `zombies`, `coins`, `guns`, `crates`, `bladeCrates`, `pickups`, `particles`, `decals`, `floaters`, `hazards`, `slicks`, `healFields`, `healPulses`, `buildings`, `pets`, `storage`.

### Players (co-op)

`player` is `players[0]`. When `coopEnabled`, `player2` joins as `players[1]`. P2 uses arrow keys, auto-fires at the nearest zombie within 380px, **shares** P1's weapon / money / perks, but has own HP / invuln / lastShot. P2 down → respawn next to P1 with 2.5s invuln. Movement: `updateP2(dt)`. Shooting: `tryShootFor(p, ang, nowSec)` (also used by P1 auto-shoot). Toggle lives in **Settings** (not Cheats).

### Weapons (`WEAPONS` dict, line ~754)

- **Basic** — pistol, shotgun, smg, rifle, rocket
- **Special** — plus, tesla, orbit, rail, twin, crossbow, flame
- **Gag** — chicken, banana, duck
- **Regular trader** (purple, non-food) — confetti, mower, bubble, harpoon, discoball, boomerang, vacuum
- **Food trader** (pink) — burger, bagel, donut, kebab, soda + fish, pizza, toaster, noodle
- **Cheat-only / god-tier** — death, apocalypse, omni, voidstar

Each entry has `shots`, `spread`, multipliers (`damage`/`fireRate`/`bulletSpeed`), `pierce`, `life`, `color`, `tag`, optional `bulletKind` (drives `drawBullet`), and on-hit / shape flags (see "Bullet hooks"). Effective stat = `player.X * weapon.X` at fire time. `drawGun(weapon, r)` draws the held silhouette per weapon — **every new weapon needs its own `case` here**, or it falls back to the pistol silhouette. `shouldDropOldWeapon()` is the single gate that decides if a weapon drops on swap / death — excludes pistol (infinite default), `traderOnly` (vanishes), and `cheatOnly`.

### Secondaries (`SECONDARIES` dict, line ~927)

One slot, triggered by `F` (or RMB / `2ND` button). Each has `kind` (melee / thrown / utility / heal / decoy / area / bomb / potion / area-laser-like) and its own cooldown. Catalog: `katana`, `warhammer`, `kunai`, `chakram`, `bow`, `medkit`, `decoy`, `emp` (renamed "Ice Bomb" — keep the id), `potion`, `bomb`. `bladeCrates[]` are pickup crates that swap `player.secondary` on `F`.

### Bullet on-hit hooks (applied in `updateBullets` after a hit lands)

`bulletKnock` (positive = away, negative = pull toward player), `clearHitsInterval` (re-hit timer for pizza / boomerang), `spawnToasts` (toast shrapnel), `dropsHazard` (e.g. `'grass'`), `randomEffect` + `effectDur` + `effectDps` (confetti rolls one of burn/slow/stun/knockback/poison per shot), `explodesIntoSauce`, `slowOnHit`, `stunOnHit` (capped for bosses).

### Waves

State: `wave`, `isBossWave`, `waveZombiesToSpawn`, `waveSpawnTimer`, `intermission`. `wave === 0 && intermission > 0` is pre-game prep. `updateWave(dt)` is the state machine: countdown → `beginNextWave()` → trickle spawns → all dead + no queue → `endCurrentWave()` (money bonus + start intermission). `beginNextWave` also spawns a money crate + a random pickup + rolls an arena event (non-boss waves only).

Mini-bosses spawn alongside the queue every 5th non-boss wave (`spawnMiniBoss`). Boss waves are every 20th (`wave % 20 === 0`) — single boss by default. **Boss Rush**: 5% chance from wave 60+ spawns **5 bosses at once** via `spawnBossRush()`; the wave-banner HP bar collapses to a combined "BOSS RUSH · N REMAINING" readout and a pulsing red "BOSS RUSH" overlay shows for ~4.5s (`bossRushBanner`).

Boss archetypes (`BOSS_TYPES`, cycled by `(bossNum - 1) % 5`): Warlord, Necromancer, Charger, Hex Mage, Berserker. Each has its own behavior in the boss branch of `updateZombies`.

Scaling: zombie hp `*= 1 + wave*0.09`, damage `*= 1 + wave*0.025`, money `*= 1 + wave*0.04`. `rollType()` biases tank/fast/exploder/etc. higher with wave.

### Arena events

`scheduleArenaEvent()` rolls one per non-boss wave. State machine: `pendingEvent` (windup with telegraph) → `fireArenaEvent(type)` → `activeEvent` (effect ticks). Types: supplyDrop, hordePush, blackout, healZone, etc. Boss waves clear any in-flight event so the fight stays focused.

### Shop

`shop` rect at top-right. Zombies cannot enter (`zombieCanEnter` is called per-axis in `updateZombies` so they slide along the boundary). Tabs (pushed conditionally in `drawShop()`):

- `upgrades` — 5 permanent rows + 4 temporary (Heal / Triple / Rapid / Nuke). Digit keys route to `tryBuy(idx)` only when `inShop()` is true.
- `arsenal` — buy any non-trader / non-cheat weapon or secondary for high $$.
- `pets` — immortal companions (one of each).
- `trader` — only when `trader` present.
- `foodtrader` — only when `foodTrader` present.
- `storage` — claim items + banked money.

### Traders

Two independent NPCs that can coexist in the shop.

- **Regular Trader** (purple cloak, **right** side): non-food gags. Stays 3 waves. ~30% arrival, 5-wave cooldown. Stock in `TRADER_STOCK`.
- **Food Trader** (pink chef, **left** side): all food-themed weapons + 5 cheaper gag guns. Stays 5 waves. ~55% arrival, 2-wave cooldown. Stock in `FOOD_TRADER_STOCK`.

Lifecycle in `processTraderForWaveEnd()` (called from `endCurrentWave`). Buy path is shared via `buyFromStock(id, stock, traderPresent)`. Trader weapons are `traderOnly` — they **vanish on swap**, never drop, never enter storage, never appear in Arsenal.

### Pets

`pets[]`. Types: dog (melee), owl (flying ranged), bot (slow heavy laser), ghost (translucent contact), drone (orbits + auto-fires). Bought once each in the Pets tab. Immortal — persist for the run. `updatePets(dt)`.

### Pickups

`pickups[]`. Spawn one per wave start + drop chance from kills (`tryDropPickup` — higher on tanks / bosses). Types in `PICKUP_TYPES`: health, shield, triple, rapid, speed, bomb. Auto-collect on contact. Cheat: `+Pickup` spawns one near the player.

### Storage + banked money

`storage[]` holds expired weapon / secondary crate items (cap 12, oldest evicted). Uncollected coins decay into `storedMoney` (not lost). Both claimable via the Storage tab. `storageChest` rect is rendered inside the shop for visual feedback.

### Build mode

`B` toggles. `buildings[]` holds walls / turrets / spikes placed on a grid (`drawBuildToolbar` shows active tool). Click while in build mode places the selected tool.

### Upgrade tree + EXP

`T` opens `gameState === 'tree'`. Kills grant `player.exp`. Level-up triggers `pendingCards` — `drawCardPicker()` shows 3 options, click one to apply via `player.special[...]`. `specialLevels` tracks pick counts for display.

### Abilities

`player.abilities` is the unlock set. Each is invoked via `tryAbility(id)` which checks `abilityLast[id]` against `gameTime` for cooldown. Effects: `bulletTime` (global zombie slow), `rage` (damage multiplier window via `rageTimer`), `phase` (invuln + walk-through via `phaseTimer`), `homing` (turns bullets homing via `homingBulletsTimer`), `pull` (magnetic suck), `storm` (lightning bolts). Dash is unlocked by default.

### Death (`checkDeath`)

At hp ≤ 0:

1. Drop current weapon (if `shouldDropOldWeapon`) at the corpse, 60s lifespan.
2. Drop money as a shower of 4–20 coins, 60s lifespan.
3. Reset weapon → pistol, money → 0, buffs cleared, 2s invuln.
4. Restart the **current** wave (clear zombies/bullets, re-queue spawn count or respawn boss).
5. Permanent upgrades + perks + pets + abilities persist. Screen shake + red flash.

### Visuals

- **Screen shake**: `shake(amt)` raises `shakeAmt`; `render()` wraps the world layer in `ctx.translate(sx, sy)` before drawing entities, then `restore()` before HUD so the HUD stays steady.
- **Red flash**: `flashRed` 0..1 decays each frame, drawn as a translucent red overlay between world and HUD.
- **Blood decals**: `addBlood` on zombie death, drawn between grid and entities so zombies cover them.
- **Vignette**: radial gradient drawn after the world layer, before HUD.
- **Muzzle flash**: `muzzleFlash(x,y,ang)` per shot batch.
- **Player + zombie graphics**: player has shadow, eyes tracking the mouse, and a per-weapon silhouette. Zombies are intentionally simple — colored circle with two small dark eye-dots + HP bar when wounded. (Earlier they had arms / faces / swaying; the user explicitly asked to revert to plain. Don't re-add detail without asking.)
- **Player invuln flicker**: ghost-alpha between 0.35 ↔ 0.85. **Never use skip-frame flicker** — the player looks like they vanish.
- **Floor cache**: the metal-sheet floor is cached to an offscreen canvas (`floorCache`) and blitted each frame.

## Render order (top to bottom in `render()`)

Inside the shake transform:
1. Grid floor (from `floorCache`)
2. Blood decals · hazards · slicks · heal fields
3. Shop zone
4. Coins
5. Particles
6. Zombies (boss branch is separate and more elaborate)
7. Bullets / zombie bullets
8. Crates · pickups · blade crates · gun pickups
9. Buildings · pets · players (P1 + P2 if active)

After `ctx.restore()`:
10. Vignette
11. Red flash
12. HUD (`drawHud`, `drawStats`, `drawWaveBanner`, `drawBossRushBanner`, `drawGuidedTutorialBanner`, `drawPauseButton`, `drawCheats`)
13. Swap prompts (gun + blade)
14. Shop menu (if `inShop()`)
15. Build toolbar · tooltips · card picker · reset-confirm modal · error overlay

## Tutorials

Two layers, both opened from the main menu:

- **Written tutorial** — `TUTORIAL_PAGES` array of pages with `title` / `accent` / `sections`. Browsed in `gameState === 'tutorial'`.
- **Guided (physical) tutorial** — `GUIDED_STEPS` array of step objects with `text` / `setup(s)` / `done(s)`. `guidedActive` flag drives `updateGuidedTutorial(dt)`. `trainingMode` flag pauses wave spawning while running.

## Sprite editor

Drawn UI accessible from the main menu. Players paint a 16×16 sprite into a named slot (e.g. `gunShotgun`, `bulletPizza`, `secondaryKatana`). `hasCustomSprite(slot)` + `drawCustomSprite(slot, x, y, size)` are checked from every `drawGun` / `drawBullet` / `drawSecondaryIcon` branch — **custom sprites silently override the procedural draw**.

## Error capture (no DevTools)

The user runs the game on iOS / file:// where DevTools aren't easily reachable. Defensive infra:

- `tick()` wraps `tickBody()` in try/catch; `ctx.setTransform(1,0,0,1,0,0)` + `ctx.globalAlpha = 1` reset each frame.
- Window-level `error` + `unhandledrejection` listeners feed `recentErrors[]`.
- `drawErrorOverlay()` shows a red panel top-right with the last few stacks.
- `copyErrors()` opens an HTML `<textarea>` overlay with selectable text (file:// blocks `navigator.clipboard`).
- `isHexColor(v)` validates `addColorStop` color args — gradient code paths that touched bug regressions (bladeCrate, healfield) are now hardened to skip on invalid color.

## Reset UX

`R` doesn't wipe immediately — it sets `resetConfirm = true` and shows a modal with Yes / No (`resetConfirmYesRect` / `resetConfirmNoRect`). `Enter` / `Y` confirms, `Escape` / `N` cancels. Escape is eaten by the modal **first**.

## Pause

Desktop only (`!isTouch`). `drawPauseButton()` puts a 36×30 `⏸` button top-right when `gameState === 'playing'`; `pauseBtnRect` is the hit-target.

## Pitfalls and conventions

- **Splice-while-iterating**: every entity-update loop iterates **backwards** so `splice(i, 1)` doesn't skip the next entry. Match this style — there are ~17 entity arrays now.
- **Mousedown chain**: handler tries in order — reset-confirm modal → cheats panel → pause button → skip-wave button → swap-gun / swap-blade buttons → build placement → fall through to firing. Each early branch `return`s. Add new UI clicks at the right place in this chain.
- **Adding a weapon or secondary**: update `WEAPONS` (or `SECONDARIES`) AND the matching `PRIMARY_GROUPS` / `SECONDARY_GROUPS` cheats taxonomy AND the trader stock list if it belongs there. Also add a `case` in `drawGun()` (or `drawShopSecondaryIcon`) so the silhouette isn't the pistol default. If it's `traderOnly` / `cheatOnly`, double-check `shouldDropOldWeapon()` is doing the right thing.
- **`hardReset`** restores upgrade costs from a hardcoded `base` array keyed by index in `upgrades`. **If you add/remove/reorder upgrades, update that array too.** Also resets: trader / foodTrader / cooldowns, storedMoney, pickups, pets, buildings, hazards, etc.
- **Forward references**: function declarations are hoisted; the `cheats` array literal contains arrow-less methods that reference functions/arrays defined later. That works because method bodies resolve at call time. Don't convert these to top-level `const` arrows without re-checking.
- **`addColorStop` requires a valid hex color** — use `isHexColor(v)` if the color comes from data. Past blank-screen bugs (healField, bladeCrate) traced to this.
- **Custom sprites silently override** procedural draws — when a visual regresses, check whether a sprite slot might be intercepting.
- **Canvas size is fixed (1200×680).** If you change it, also recheck `SPAWN`, `shop` rect, HUD layout numbers, panel positions, and the touch UI overlay.
- **Pistol is the infinite default**: never drops on swap or death. Keep this invariant.
- **iOS** has no easy DevTools — when debugging visual / crash issues, route diagnostics through the in-game error log, not `console.log`.

## Tuning quick-reference

- Difficulty: `hpMul` / `dmgMul` / `moneyMul` formulas in `spawnZombie`; chance curves in `rollType`.
- Spawn pacing: `Math.max(0.16, 0.85 - wave * 0.013)` in `updateWave`.
- Boss scale: `hp` / `speed` / `damage` / `money` formulas in `spawnBoss` (driven by `bossNum = floor(wave / 20)`, with a `1.25^(bossNum-1)` per-boss multiplier).
- Boss Rush: 5% roll, only on `wave >= 60` boss waves.
- Player power: starting values on the `player` literal at the top of the script.
- Weapon balance: `WEAPONS` dict.
- Drop rates: `tryDropGun`, `tryDropPickup`, `tryDropBlade`.
- Shop prices: each upgrade's `cost`; cost-scaling factors (`*1.5`, `*1.8`) live in each `buy()`.
- Trader cadences: `TRADER_STAY_WAVES` / `TRADER_ARRIVAL_CHANCE` / `TRADER_COOLDOWN_WAVES` (and the `FOOD_*` equivalents).
- Visual punch: `shake(N)` calls scattered in damage / explosion / death sites.

## User preferences (carry over)

- Single-file, no build step, no dependencies. Don't add a `package.json` or split files.
- Terse responses. State results directly; no trailing recap.
- Default to no code comments unless the *why* is non-obvious.
- For multi-step features, use a todo list to track progress.
- The user is comfortable iterating — ship a working version with sensible defaults and let them ask for tuning rather than asking many up-front questions.
- The user runs on a mix of desktop browser and iOS, and **can't open DevTools** — favor in-game error capture over `console.log`.

## Keeping this file current

**This file is a directive for future agent sessions.** Stale CLAUDE.md leads Explore / Plan subagents to recommend the wrong things. After shipping a non-trivial feature:

1. Scan whether any of these went stale: **Controls / Entity arrays / WEAPONS / SECONDARIES / Pitfalls / History**.
2. Edit the relevant section. Incremental edits are fine — don't rewrite the whole file every commit.
3. Every ~5 commits or when a system is renamed / restructured, do a full skim.

## Mirroring releases to the Portfolio site

The user features DEADZONE on their GitHub Pages portfolio at `https://lxreyes.github.io/deadzone/`. The portfolio repo lives at `/Users/lachlanreyes/Documents/projects/Githubpage/` (origin: `lxreyes/lxreyes.github.io`) and the game lives at `Githubpage/deadzone/index.html` — a copy of this repo's `index.html`. **After every push that updates the game**, mirror the change and push the portfolio too:

```sh
cp /Users/lachlanreyes/Documents/projects/deadzone/index.html \
   /Users/lachlanreyes/Documents/projects/Githubpage/deadzone/index.html
cd /Users/lachlanreyes/Documents/projects/Githubpage
git add deadzone/index.html
git commit -m "Sync DEADZONE: <one-line summary of what changed>"
git push
```

Single-file project — no other assets need to come along (no `CLAUDE.md`, no node_modules, etc.). The portfolio's own `index.html` already links to `deadzone/index.html` so a fresh `cp` is enough; only edit the portfolio's `index.html` when adding new projects or restructuring the page.

Do this **on every game commit**, not in batches — a one-commit lag between deadzone and the portfolio is fine, but a multi-commit lag means the live site silently fails to match what the user just shipped.

## History of major features (most recent first)

Rebuild as needed from `git log --oneline`. Most recent:

1. **Food Trader** — new pink chef NPC, food-themed weapons + 5 cheaper food gag guns; older trader pivoted to non-food gags (bubble / harpoon / discoball / boomerang / vacuum) and dropped fish/pizza/toaster/noodle.
2. **Boss Rush** — 5% chance from wave 60+ spawns 5 bosses at once; combined HP bar + big red banner.
3. **Coins bank into storage** + chakram tracks cursor reliably.
4. **Reset confirm modal** + desktop pause button.
5. **Main menu sizing** — buttons size to fit after Guided Tutorial was added.
6. **Guided Tutorial** — step-by-step interactive walkthrough under How to Play.
7. **iOS / touch compatibility** — viewport meta, joystick, on-screen buttons, autoShoot default true on touch.
8. **Local co-op P2** + Auto-Shoot toggle (Settings, not Cheats).
9. **In-game error log** + HTML overlay copy path.
10. **Trader system** — roaming NPC + exclusive gag weapons (later split into two traders).
11. **Pets** — immortal companions.
12. **Storage box** — items + later money.
13. **Secondary weapons** — katana, warhammer, kunai, chakram, bow, medkit, decoy, Ice Bomb, potion, bomb.
14. **Boss archetypes** — Warlord / Necromancer / Charger / Hex Mage / Berserker.
15. **Build mode** — walls, turrets, spike traps on a grid.
16. **Upgrade tree** + EXP + perk card picks at level milestones.
17. **Abilities** — bullet time, rage, phase, homing, pull, storm.
18. **Arena events** — supply drops, horde push, blackout, heal zones.
19. **Per-weapon gun silhouettes** (`drawGun`) + plain-circle zombies + cheats panel + HUD stats + wave system + boss every 20 waves + top-down arena base.
