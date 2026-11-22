# Migration Plan

**Project:** Home Assistant configuration redesign  
**Status:** Initial transition plan  
**Target:** Raspberry Pi Home Assistant test system before any production migration

## 1. Migration strategy

Migration is room-by-room and reversible. The legacy configuration remains available until the replacement has been tested through a realistic household-use cycle.

Sequence:

```text
verify
→ map
→ create on test system
→ configuration check
→ functional test
→ switch HMI references
→ observe
→ retire legacy configuration
```

## 2. Repository separation

- `ha-hmi-mockup`: frozen design and interaction reference, tag `v1.0.0`
- `home-assistant-config`: executable Home Assistant YAML, themes, dashboards, migration documentation

Do not copy HTML prototype code into the Home Assistant configuration repository.

## 3. Initial repository transition

1. Create private repository `home-assistant-config`.
2. Add the approved documentation baseline.
3. Create a Home Assistant-specific `.gitignore`.
4. Add only the minimum configuration files needed to understand includes and the first pilot.
5. Verify that no secrets or `.storage` content are staged.
6. Commit a clean baseline to `main`.
7. Create branch `feature/living-room-pilot`.
8. Perform all pilot work in that branch.

## 4. Pilot migration: Wohnzimmer

### Verification

- confirm `sensor.temp_wozi_temperature`
- confirm `climate.heizung_wohnzimmer`
- confirm `switch.sonoff_11`
- confirm stable device/MQTT ID `sonoff-mini-11`
- record optional Fritz!Box display name separately
- identify Bogenlampe Shelly model and installation position
- confirm Bogenlampe switch, power sensor, and three scripts
- confirm TV-Board switch and power sensor
- confirm heating-pump dependency
- search all references to every legacy entity

### Build

- create target climate/function entities
- add bounded retry/timeout behavior for Bogenlampe presets
- create or retain stable TV-Board functional switch
- create Wohnzimmer Lovelace card
- add dark/light theme variables needed by the pilot

### Validate

- run Home Assistant configuration check
- test unavailable room sensor
- test unavailable actuator
- test restart and target restoration
- test 0.5 °C changes
- test Bogenlampe presets and failure behavior
- test TV-Board low-power auto-off
- test desktop/tablet/mobile layout
- test light/dark themes

### Rollback

- preserve legacy files until pilot acceptance
- record all changed include paths
- keep a commit before deployment
- restore previous dashboard references if the pilot fails
- remove target files only after Home Assistant has returned to the prior valid state

## 5. Deployment workflow

Initial recommended workflow:

```text
Mini-PC local branch
→ commit and push
→ select files for deployment
→ transfer to Raspberry Pi test system
→ configuration check
→ reload/restart minimum required scope
→ test
→ document result
```

FileZilla is acceptable initially. Visual Studio Code Remote SSH may be used when stable. Deployment method must not bypass Git history.

## 6. Merge criteria

A feature branch may merge into `main` only when:

- configuration check passes
- no secrets are committed
- mapping and inventory are updated
- functionality is tested on the Raspberry Pi test system
- unavailable behavior is acceptable
- rollback is documented
- HMI labels and backend IDs follow the documentation
- required custom-card/integration versions are recorded

## 7. Later rooms

After Wohnzimmer:

1. Küche
2. Arbeitszimmer
3. Schlafzimmer
4. remaining first-floor rooms
5. second floor
6. garden
7. technical view

Each room repeats the same verify-map-build-test-switch-over process.
