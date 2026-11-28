# Home Assistant dashboard roadmap

## Current objective

Complete and accept the full simulated house HMI on `feature/living-room-pilot` before merging the design baseline to `main`. Smartphone is the primary acceptance layout.

## Simulated design phase

1. Maintain and regression-test EG.
2. Complete and accept OG.
3. Implement and accept DG.
4. Implement and accept Garden.
5. Apply global design insights consistently to all views.
6. Run smartphone full-house acceptance, desktop regression, manual Light/Dark theme checks, navigation, console, deployment, rollback, and source-export checks.
7. Keep the visible theme switch out of the HMI until its scope and behavior are explicitly resolved.

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


## Patch 0026 merge preparation

- The complete simulated house HMI is accepted through Patch 0025.
- Patch 0026 adds the immutable baseline description, merge checklist, and pull-request template.
- After the checklist is complete, merge `feature/living-room-pilot` to `main`.
- Create `feature/mqtt-readonly-baseline` from updated `main`; never experiment with real MQTT or entity controls directly on `main`.

## MQTT read-only baseline

Patch 0027 validates the broker, bridge, and two nearby temperature sensors without changing production or controlling devices. The first accepted data sources are Arbeitszimmer and Schlafzimmer temperature, battery, and linkquality. Broker hardening remains a separate production-migration security phase.

## Patch 0028 infrastructure baseline

- Persist only the narrow `ha-test` Docker-network exception to production MQTT TCP/1883.
- Keep the existing block for every other port and protocol to `192.168.178.16`.
- Maintain `docs/MQTT_INVENTORY.md` as the migration source of truth.
- Do not harden or reconfigure production Mosquitto, Zigbee2MQTT, or production Home Assistant in this patch.
- Continue read-only inventory before selecting any writable pilot entity.

## Patch 0029 inventory expansion

- Capture Zigbee2MQTT bridge devices and retained Home Assistant discovery messages read-only.
- Generate a redacted physical/logical device inventory in Markdown and CSV.
- Review command-topic presence and assign migration ownership before selecting a writable pilot.
- Do not add runtime entities, Discovery, broker changes, or device commands in this patch.

## Patch 0030 Tasmota inventory expansion
- Inventory non-Zigbee MQTT devices, especially Tasmota devices, without publishing commands from `ha-test`.
- Correlate reviewed Tasmota status/telemetry captures with Home Assistant MQTT metadata.
- Record state, telemetry, availability, and command-topic candidates in `docs/MQTT_TASMOTA_INVENTORY.md`.
- Keep production ownership for all writable topics until a separately reviewed migration patch selects one harmless pilot and documents rollback.
- Include the Patch 0030 inventory document and both export tools in future source exports.

## Patch 0031 documentation and writable-pilot readiness
- Add `docs/README.md` as the documentation entry point and archive completed one-time merge documents.
- Add `docs/MQTT_MIGRATION_PLAN.md` with entry gates, candidate classes, exclusions, and evidence required for the first writable pilot.
- Do not publish MQTT commands or change runtime configuration in Patch 0031.
- Implement one writable pilot in the next patch only after physical mapping, production ownership, retained behavior, and rollback are complete.

## Patch 0032 level taxonomy and room migration foundation
- Replace package directories `ground_floor`, `first_floor`, and `second_floor` with `l0`, `l1`, and `l2`.
- Replace technical dashboard paths with `l0`, `l1`, and `l2` while keeping the visible titles `EG`, `OG`, and `DG`.
- Establish English code naming and room-by-room migration without separate room documents.
- Preserve existing entity IDs to avoid unrelated breaking changes.
- Continue Patch 0032 with the office room migration only after the remaining room inventory and automation review is complete.
