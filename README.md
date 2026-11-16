# FLOOR IS LAVA

A round-based Roblox multiplayer survival game. Players climb a simple obstacle arena while lava rises from below. The last surviving player wins.

## Current prototype

- Generated lobby and first arena built from standard Roblox Parts.
- Automatic intermission and round countdown.
- Rising lava that eliminates players on contact.
- Last-player-standing win condition.
- Coins and wins in the Roblox leaderboard.
- DataStore persistence for coins and wins.
- Basic round HUD.

## Project setup

This repository uses [Rojo](https://rojo.space/) to sync Luau files into Roblox Studio.

1. Install Rojo and the Rojo Studio plugin.
2. Clone this repository.
3. Run `rojo serve` from the repository directory.
4. Connect the Rojo plugin in Roblox Studio.
5. Publish the experience and enable **Game Settings → Security → Enable Studio Access to API Services** to test DataStores.
6. Use **Test → Start** with at least two players to test the multiplayer round.

For solo testing only, temporarily set `MIN_PLAYERS = 1` in `src/ReplicatedStorage/Shared/Config.lua`. Keep it at 2 for public servers.

## Current limitations

This is an early playable foundation, not a release build. It has one block-based arena, a basic HUD, and placeholder economy. Mobile layout, spectator flow, anti-exploit hardening, shop UI, multiple maps, sound, effects, and full multiplayer testing are still to be done.

## Development principles

- Keep maps built from simple Roblox Parts.
- Keep round state, eliminations, and rewards server-authoritative.
- Prefer new arena layouts and gameplay modifiers over expensive custom assets.
- Add monetization only after the core round loop is tested and fun.
