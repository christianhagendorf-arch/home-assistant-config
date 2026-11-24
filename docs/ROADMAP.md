# Home Assistant dashboard roadmap

## Current objective

Complete and accept the full simulated house HMI on `feature/living-room-pilot` before merging the design baseline to `main`. Smartphone is the primary acceptance layout.

## Simulated design phase

1. Maintain and regression-test EG.
2. Complete and accept OG.
3. Implement and accept DG.
4. Implement and accept Garden.
5. Apply global design insights consistently to all views.
6. Run smartphone full-house acceptance, desktop regression, Light/Dark, navigation, console, deployment, rollback, and source-export checks.

## Merge baseline

After full-house acceptance, create a final source export, review `docs/DESIGN_BACKLOG.md`, and merge `feature/living-room-pilot` to `main`. `main` then represents the complete simulated and recoverable HMI baseline.

## Real integration branches

Do not develop real integrations directly on `main`.

1. Create `feature/mqtt-readonly-baseline`.
2. Connect `ha-test` to MQTT broker `192.168.178.16` with read-only or harmless sensor data first.
3. Inventory topics and prevent duplicate actuator control or production automations.
4. Document room-by-room heating architecture before climate migration.
5. Start real entity migration with `feature/living-room-real-entities`.
6. Migrate further rooms and floors on separately tested feature branches.

Living room and kitchen use floor-heating actuators connected through Sonoff Mini devices and circulation-pump logic. Rooms with external room sensors and radiator TRVs are Better Thermostat candidates. The HMI remains independent of the final climate backend.

## Later detail phase

Evaluate detail sliders, RGB presets, HVAC modes, cover position, Lotta window heating, office pinboard/platform, popup components, reusable templates, and technical-dashboard components after the main house controls and real entity behavior are stable.
