# FLOOR IS LAVA

A round-based Roblox survival game. Climb a shifting obstacle arena, dodge moving sweepers, stay above the rising lava, and be the last player standing.

## Current build

### Gameplay
- Automatic multiplayer rounds (2+ players).
- Intermission, survival timer, rising lava, winner detection and lobby return.
- Three arena layouts selected at random: Volcano Heights, Neon Foundry and Skyline Ruins.
- Moving neon sweepers on elevated platforms.
- Lava and sweeper contact eliminate players.
- Coins for participation and a larger reward for the winner.
- Wins and coins saved with DataStore.

### Visual direction
- Stylized volcanic / industrial world built from standard Roblox Parts.
- Lobby with a central stage, neon trims, signs and colored lighting.
- Three platform layouts with different silhouettes and accent colors.
- Arena foundations, towers, glowing platform edges and moving hazards.
- Neon lava with PointLight and particle sparks.
- Atmosphere, color grading and bloom.

### Interface
- Responsive round HUD with phase, countdown and objective text.
- Coins and wins counters.
- Live survivor count and current arena badge.
- Animated event notifications.
- Large animated victory / round-result panel.
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

## Required Studio test pass

The code has been committed, but this build has not been executed in Roblox Studio. Verify:
- All three arenas load and all platform jumps are reachable.
- Moving sweepers rotate and eliminate players on contact.
- Lava rises at the intended speed and eliminates players reliably.
- Players joining mid-round remain in the lobby until the next round.
- A winner receives exactly one win reward.
- Participation rewards are granted once per participant.
- DataStore access works in a published test experience.
- HUD and result panel remain readable on phone aspect ratios.

## Development principles

- Prefer strong composition, lighting, color and UI over complex custom models.
- Keep maps built from simple, performant Roblox Parts.
- Keep round state, eliminations and rewards server-authoritative.
- Add new maps and round modifiers before expensive assets.
- Add monetization only after the core loop is tested and enjoyable.
