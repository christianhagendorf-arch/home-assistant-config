# Simulation baseline merge checklist

## Repository

- [X] branch is `feature/living-room-pilot`
- [X] working tree is clean
- [X] local branch equals upstream
- [X] Patch 0026 documentation is committed and pushed
- [X] final post-Patch-0026 source export exists

## HMI acceptance

- [X] EG opens and representative controls work
- [X] OG opens and representative controls work
- [X] DG opens and representative controls work
- [X] Garden opens and representative controls work
- [X] smartphone has no horizontal page overflow
- [X] desktop layout remains usable
- [X] navigation `EG | OG | DG | Garten` works
- [X] Night Control Light is manually usable
- [X] Night Control Dark is manually usable
- [X] no configuration-error cards
- [X] no red browser-console errors

## Deployment and recovery

- [X] latest deploy dry-run succeeded
- [X] latest apply succeeded
- [X] Home Assistant `check_config` succeeded
- [X] latest backup path was recorded
- [X] rollback procedure is documented
- [X] source-export tool includes dashboard, all packages, themes, tools, backlog, roadmap, and baseline documentation

## Pull request

- [X] PR title uses `ui: complete simulated full-house HMI baseline`
- [X] PR body is based on `docs/PULL_REQUEST_SIMULATION_BASELINE.md`
- [X] known accepted debt is included
- [X] no MQTT or real-entity work is included
- [X] merge target is `main`

## After merge

- [X] delete or archive `feature/living-room-pilot` after confirming `main`
- [X] create `feature/mqtt-readonly-baseline` from updated `main`
- [X] begin with broker reachability and read-only topics
