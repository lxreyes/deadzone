# DEADZONE

Top-down, wave-based zombie survival shooter. Single self-contained HTML file. Vanilla JS + Canvas 2D + Web Audio API (procedural SFX only — no audio files). No build step, no dependencies.

## Run

Open `index.html` in any modern browser (double-click, or `open index.html` on macOS). No server needed.

## Files

- `index.html` — **everything**: HTML scaffold, CSS, and one inline `<script>` block. Treat this as the entire project.
- `CLAUDE.md` — this file.

There are no other source files, configs, or dependencies. The user prefers it stay that way — keep new features in the same file unless they explicitly ask to split.

## Controls (player-facing)

- `WASD` / arrows — move
- mouse — aim
- hold left-click — fire (auto)
- `1`–`9` — buy upgrade (only while standing inside the shop rect)
- `E` or click the green **Swap** button — equip a weapon pickup you're hovering over
- `Space` or click **START NOW** — skip the intermission early
- `R` — hard reset (wipes everything, restores base upgrade costs, weapon → pistol)
- `M` — toggle mute
- `Shift` — dash (permanent ability, cooldown ~1.4s, 0.45s i-frames)
- `B` — toggle build mode (wall / turret / spike trap; place on grid with click)
- `Space` or click `START NOW` — manually begin the next wave (no auto-advance)

Cheats panel (top-left): hidden until the player types `1 2 3 4` outside the shop (`cheatBuffer` is a rolling 4-char window). Once unlocked, click buttons. God Mode toggles a flag checked in `updateZombies`; Mute toggles `soundMuted`.

## Audio

`AudioContext` is lazy-init'd on the first user gesture (`ensureAudio()` + `resumeAudio()` in the keydown/mousedown handlers) to satisfy autoplay policy. Two primitives — `tone({freq, type, dur, vol, sweep, delay})` and `noise({dur, vol, lowpass, hipass, delay})` — feed a `masterGain` (0.32) routed to destination. The `SFX` dispatch dict has one entry per game event (`shoot(weapon)`, `zombieHit`, `zombieDie`, `playerHurt`, `explosion`, `coin`, `pickup`, `crate`, `swap`, `swing`, `throwBlade`, `chestOpen`, `perkPick`, `waveStart`, `bossSpawn`, `uiClick`, `unlock`, `death`). Rapid-fire events (`zombieHit`, `zombieDie`, `coin`, `playerHurt`) call `sfxThrottle(name, gapMs)` to avoid crackle when a crowd dies at once. `soundMuted` is a global gate.

## Mental model

State is **all top-level**, no classes. Each entity kind is a plain-object array (`bullets`, `zombies`, `coins`, `guns`, `crates`, `particles`, `decals`). The game loop `tick()` lives at the bottom of the script and calls `updateX(dt)` functions, then `render()`. Coords are screen-space pixels; world == viewport (canvas fixed at 1200×680).

### Player
One `player` object. Holds position, hp/maxHp, base stats (speed, damage, fireRate, bulletSpeed, pierce), `weapon` (key into `WEAPONS`), and `buffs` (`triple`/`rapid`/`fast` are time-in-seconds counters; `shield` is 0/1).

### Weapons
`WEAPONS` dict keyed by id: `pistol`, `shotgun`, `smg`, `rifle`, `rocket`. Each has `shots`, `spread`, multipliers (`damage`/`fireRate`/`bulletSpeed`), `pierce`, `life`, `color`, `tag` (one-letter ID), and the rocket also carries `explosive`/`blastR`/`blastDmg`. Effective stat = `player.X * weapon.X` at fire time. `drawGun(weapon, r)` draws the held-weapon silhouette per type. `DROPPABLE_WEAPONS` excludes the pistol (default fallback).

### Waves
State: `wave`, `isBossWave`, `waveZombiesToSpawn`, `waveSpawnTimer`, `intermission`. `wave === 0 && intermission > 0` is the pre-game prep. `updateWave(dt)` is the state machine: count down intermission → `beginNextWave()` → trickle spawns → all dead + no queue → `endCurrentWave()` (money bonus + start intermission).

Every 20th wave is a boss wave: `spawnBoss()` puts one boss on the map. The boss periodically calls `spawnBossMinions()` while alive. Boss-wave detection is `wave % 20 === 0`.

Scaling: zombie hp `*= 1 + wave*0.09`, damage `*= 1 + wave*0.025`, money `*= 1 + wave*0.04`. `rollType()` biases tank/fast chances upward with wave.

### Shop
`shop` rect at top-right. Zombies cannot enter — `zombieCanEnter()` is called per-axis in `updateZombies()` so they slide along the boundary. `upgrades` array has 5 permanent (cost grows on each buy) + 4 temporary (Heal, Triple Shot, Rapid Fire, Nuke). Digit keys route to `tryBuy(idx)` only when `inShop()` is true. Holding LMB inside the shop intentionally doesn't fire.

### Pickups
- **Gun pickups (`guns`)** don't auto-equip. `updateGuns` tracks the nearest one within ~50px into `nearbyGun`. The swap prompt at the bottom of the screen shows current vs new stats; `E` or clicking the button calls `doSwapWeapon()`, which drops the old weapon at the player's feet (if it wasn't a pistol).
- **Money crates (`crates`)** spawn one per wave start (bonus every 5 waves). Auto-collect on contact.

### Death (`checkDeath`)
At hp ≤ 0:
1. Drop current weapon (if not pistol) at the corpse, 60s lifespan.
2. Drop money as a shower of 4–20 coins, 60s lifespan.
3. Reset weapon → pistol, money → 0, buffs cleared, 2s invuln.
4. Restart the **current** wave: clear zombies/bullets, re-queue spawn count (or respawn boss).
5. Permanent upgrades persist. Screen shake + red flash for feedback.

### Cheats panel
`cheats` is an array of `{label, run, toggle?}`. `drawCheats()` assigns each entry a `.rect` for hit-testing. The mousedown handler runs the first one whose rect contains the cursor. `godMode` is a flag checked in `updateZombies` to skip player contact damage.

### Visuals
- **Screen shake**: `shake(amt)` raises `shakeAmt`; `render()` wraps the world layer in `ctx.translate(sx, sy)` before drawing entities, then `restore()` before HUD so the HUD stays steady.
- **Red flash**: `flashRed` 0..1 decays each frame, drawn as translucent red overlay between world and HUD.
- **Blood decals** (`addBlood`) appear on zombie death, drawn between grid and entities so zombies cover them.
- **Vignette**: radial gradient drawn after the world layer, before HUD.
- **Muzzle flash**: `muzzleFlash(x,y,ang)` fires short-lived yellow particles once per shot batch in `tryShoot`.
- **Player + zombie graphics**: player has shadow, eyes that track the mouse, and a per-weapon silhouette. Zombies are intentionally simple — colored circle with two small dark eye-dots and HP bar when wounded. (Earlier the zombies had arms/faces/swaying; the user explicitly asked to revert to the plain look. Do not re-add detail without asking.)

## Render order (top to bottom in `render()`)

Inside the shake transform:
1. Grid floor
2. Blood decals
3. Shop zone
4. Coins
5. Particles
6. Zombies (boss branch is separate and more elaborate)
7. Bullets
8. Money crates
9. Gun pickups
10. Player

After `ctx.restore()`:
11. Vignette
12. Red flash
13. HUD (`drawHud`, `drawStats`, `drawWaveBanner`, `drawCheats`)
14. Swap prompt (if `nearbyGun && nearbyGun.weapon !== player.weapon`)
15. Shop menu (if `inShop()`)

## Pitfalls and conventions

- **Splice-while-iterating**: every entity-update loop iterates **backwards** so `splice(i, 1)` doesn't skip the next entry. Match this style.
- **Mousedown chain**: handler tries in order — cheats panel → skip wave button → swap gun button → fall through to firing. Each early branch `return`s. Add new UI clicks at the right place in this chain.
- **`hardReset`** restores upgrade costs from a hardcoded `base` array keyed by index in `upgrades`. **If you add/remove/reorder upgrades, update that array too.**
- **Forward references**: function declarations are hoisted; the `cheats` array literal contains arrow-less methods that reference functions/arrays defined later (`upgrades`, `spawnBoss`, `beginNextWave`). That works because method bodies only resolve at call time. Don't convert these to top-level `const` arrows without re-checking.
- **Canvas size is fixed (1200×680).** If you change it, also recheck `SPAWN`, `shop` rect, HUD layout numbers, and the panel positions (`drawCheats`, `drawStats`).
- **Pistol is special**: it's the infinite default. It never drops on swap or death so the player is never weaponless. Keep this invariant.

## Tuning quick-reference

- Difficulty: `hpMul`/`dmgMul`/`moneyMul` formulas in `spawnZombie`; chance curves in `rollType`.
- Spawn pacing: the `Math.max(0.16, 0.85 - wave * 0.013)` line in `updateWave`.
- Boss scale: `hp`/`speed`/`damage`/`money` formulas in `spawnBoss` (driven by `bossNum = floor(wave / 20)`).
- Player power: starting values on the `player` object literal at the top of the script.
- Weapon balance: `WEAPONS` dict.
- Drop rates: `tryDropGun`.
- Shop prices: each upgrade's `cost`; cost-scaling factors (`*1.5`, `*1.8`) live in each `buy()`.
- Visual punch: `shake(N)` calls scattered in damage/explosion/death sites.

## User preferences (carry over)

- Single-file, no build step, no dependencies. Don't add a `package.json` or split files.
- Terse responses. State results directly; no trailing recap.
- Default to no code comments unless the *why* is non-obvious.
- For multi-step features, use a todo list to track progress.
- The user is comfortable iterating — ship a working version with sensible defaults and let them ask for tuning rather than asking many up-front questions.

## History of major features (most recent first)

This is the iteration order the user took to arrive at the current state; useful for understanding *why* something is the way it is.

1. Per-weapon gun silhouettes (`drawGun`).
2. Reverted zombie graphics to plain circles + eye dots (had been more detailed).
3. Cheats panel (top-left).
4. Player visual polish: shadow, eyes tracking mouse, gun model.
5. Weapon swap prompt instead of auto-pickup; death drops weapon + money as pickups; current wave restarts on death.
6. HUD stats panel (bottom-right); Skip Wave button; rare gun drops; money crates.
7. Wave system + boss every 20 waves.
8. Top-down shooter base: arena, WASD + mouse, zombies, shop with permanent + temporary upgrades.
