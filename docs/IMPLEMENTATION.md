# Tidy Trails - Programmer Implementation Guide

## Scope

This repository uses Godot 4.7 and the existing Maaack game-template integrations for:

- Main menu and options
- Pause menu
- Scene loading
- Save and level-state data
- Music and UI sound controllers
- Level and result windows

Implement Tidy Trails gameplay in project-owned folders. Do not modify third-party files under `addons/` unless a plugin integration requires a narrowly documented fix.

## Project Structure

```text
scenes/game/stages/         Reusable map-stage scenes
scenes/game/mini_games/     Five mini-game scenes
scripts/stage/              Stage runtime and bubble control
scripts/mini_games/         Mini-game-specific shared support
scripts/timers/             Countdown utilities
scripts/scoring/            Result and star calculation
resources/stages/           Editable stage/activity balancing
assets/placeholders/        Temporary programmer visuals
assets/art/                 Artist-delivered final visuals
assets/audio/               Music and sound-effect assets
tests/                      Focused automated and scene tests
```

The existing `scenes/game/levels/` files are level containers. Shared stage implementation should live in the new stage, mini-game, script, and resource folders to avoid duplicating gameplay into every level.

## Temporary Art Rule

All programmer-created art is temporary placeholder art.

- Keep placeholder assets in `assets/placeholders/`.
- Keep artist-delivered assets in `assets/art/`.
- Use exported texture/resource properties so asset replacement does not require gameplay script changes.
- Do not implement final art assets or visual identity in programmer gameplay code.

## Agile Sprint Sequence

1. Prepare the template and project structure.
2. Build stage/activity resources, runtime state, timers, and scoring.
3. Build the reusable map stage, bubbles, popups, and Stage 1.
4. Implement Trash Collector and Waste Sorting.
5. Implement Drain Cleaner and River Cleaner.
6. Implement Save the Water and Stage 2/3.
7. Implement stage resolution, stars, balloons, and final results.
8. Integrate progression, UI, save data, asset handoff, audio hooks, and tests.
9. Run the complete playthrough and release validation.

## Baseline Values

These values are initial programmer defaults and must be moved into editable stage resources:

- Stage 1: 180 seconds
- Stage 2: 210 seconds
- Stage 3: 240 seconds
- Bubble interval: 12–18 seconds
- Bubble task duration: 35–50 seconds
- Mini-game duration: 30–45 seconds
- Waste Sorting errors: 3
- River Cleaner errors: 3
- GREAT: 100 points
- AWESOME: 150 points
- Star thresholds: 25%, 50%, and 75% of possible mini-game points
