# Simulation baseline merge checklist

## Repository

- [ ] branch is `feature/living-room-pilot`
- [ ] working tree is clean
- [ ] local branch equals upstream
- [ ] Patch 0026 documentation is committed and pushed
- [ ] final post-Patch-0026 source export exists

## HMI acceptance

- [ ] EG opens and representative controls work
- [ ] OG opens and representative controls work
- [ ] DG opens and representative controls work
- [ ] Garden opens and representative controls work
- [ ] smartphone has no horizontal page overflow
- [ ] desktop layout remains usable
- [ ] navigation `EG | OG | DG | Garten` works
- [ ] Night Control Light is manually usable
- [ ] Night Control Dark is manually usable
- [ ] no configuration-error cards
- [ ] no red browser-console errors

## Deployment and recovery

- [ ] latest deploy dry-run succeeded
- [ ] latest apply succeeded
- [ ] Home Assistant `check_config` succeeded
- [ ] latest backup path was recorded
- [ ] rollback procedure is documented
- [ ] source-export tool includes dashboard, all packages, themes, tools, backlog, roadmap, and baseline documentation

## Pull request

- [ ] PR title uses `ui: complete simulated full-house HMI baseline`
- [ ] PR body is based on `docs/PULL_REQUEST_SIMULATION_BASELINE.md`
- [ ] known accepted debt is included
- [ ] no MQTT or real-entity work is included
- [ ] merge target is `main`

## After merge

- [ ] delete or archive `feature/living-room-pilot` after confirming `main`
- [ ] create `feature/mqtt-readonly-baseline` from updated `main`
- [ ] begin with broker reachability and read-only topics
