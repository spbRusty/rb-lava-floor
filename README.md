# FLOOR IS LAVA

A round-based Roblox survival game. Climb a shifting obstacle arena, dodge moving sweepers, stay above the rising lava, and be the last player standing.

## Current build

### Gameplay
- Automatic rounds from one real player; two lightweight NPC rivals join solo sessions.
- Automatic multiplayer rounds; NPC rivals are disabled when two or more real players are present.
- Intermission, survival timer, rising lava, winner detection and lobby return.
- A procedural arena generator creates a fresh sector each round, with randomized lane count, platform positions, heights, sizes, colors and hazard placement.
- Every platform layer has at least two reachable upward choices; platform spacing and height steps are constrained for standard Roblox jumping.
- Moving neon sweepers on elevated platforms.
- Lava and sweeper contact eliminate players.
- Coins for participation and a larger reward for the winner.
- Wins and coins saved with DataStore.
- Global top-10 wins leaderboard displayed in the lobby and refreshed every 60 seconds.
- Global ranking is backed by an OrderedDataStore and updated when a player wins.

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

The game starts with one real player and adds two NPC rivals in solo sessions. When two or more real players are present, NPC rivals are not spawned.

While the place is unpublished, DataStores are unavailable: the server logs a warning and the match loop keeps running without saving stats or the global leaderboard, so local Studio playtests work without API access.

## Required Studio test pass

Studio verification is required after each gameplay update. Verify:
- Procedural sectors vary between rounds and all generated platform routes remain jumpable.
- Each platform offers at least two upward route choices.
- Two NPC rivals spawn only when exactly one real player is present and can climb the generated platforms.
- Moving sweepers rotate and eliminate both players and NPC rivals on contact.
- Lava rises at the intended speed and eliminates players reliably.
- Players joining mid-round remain in the lobby until the next round.
- A winner receives exactly one win reward.
- Participation rewards are granted once per participant.
- DataStore and OrderedDataStore access work in a published test experience.
- Global leaderboard displays the correct top 10 players and refreshes without errors.
- HUD and result panel remain readable on phone aspect ratios.

## Development principles

- Prefer strong composition, lighting, color and UI over complex custom models.
- Keep maps built from simple, performant Roblox Parts.
- Keep round state, eliminations and rewards server-authoritative.
- Add new maps and round modifiers before expensive assets.
- Add monetization only after the core loop is tested and enjoyable.
