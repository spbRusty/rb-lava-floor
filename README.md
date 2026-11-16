# FLOOR IS LAVA

A round-based Roblox survival game. Climb a shifting obstacle arena, stay above the rising lava, and be the last player standing.

## Current build

### Gameplay
- Automatic multiplayer rounds (2+ players).
- Intermission, countdown, rising-lava survival, winner detection and lobby return.
- Three arena layouts selected at random: Volcano Heights, Neon Foundry and Skyline Ruins.
- Coins for participation and a larger reward for the winner.
- Wins and coins saved with DataStore.

### Visual direction
- Stylized volcanic / industrial world built from standard Roblox Parts.
- Reworked lobby with a central stage, neon trims, signs and colored lighting.
- Arena foundations, varied platforms, towers and glowing edge details.
- Neon lava with a PointLight and particle sparks.
- Atmosphere, color grading and bloom.

### Interface
- Responsive round HUD with phase, countdown and objective text.
- Coins and wins counters.
- Live survivor count.
- Animated event notifications for round starts and results.
- Scales down for narrow screens.

## Project setup

This repository uses [Rojo](https://rojo.space/) to sync Luau files into Roblox Studio.

1. Install Rojo and the Rojo Studio plugin.
2. Clone this repository.
3. Run `rojo serve` from the repository directory.
4. Connect the Rojo plugin in Roblox Studio.
5. Publish the experience and enable **Game Settings → Security → Enable Studio Access to API Services** to test DataStores.
6. Use **Test → Start** with at least two players to test multiplayer rounds.

For solo testing only, temporarily set `MIN_PLAYERS = 1` in `src/ReplicatedStorage/Shared/Config.lua`. Restore it to 2 before publishing.

## Important testing notes

The repository has been updated through source files, but the current build still needs a Roblox Studio test pass. In particular, verify:
- All three arenas spawn correctly and are traversable.
- Lava contact eliminates players reliably on desktop and mobile.
- Players who join during a round wait safely in the lobby.
- Respawns, winner rewards and participation rewards happen only once.
- DataStore access works in a published test experience.
- HUD remains readable on phone aspect ratios.

## Development principles

- Prefer strong composition, lighting, color and UI over complex custom models.
- Keep maps built from simple, performant Roblox Parts.
- Keep round state, eliminations and rewards server-authoritative.
- Add new map layouts and round modifiers before adding expensive assets.
- Add monetization only after the core loop is tested and enjoyable.
