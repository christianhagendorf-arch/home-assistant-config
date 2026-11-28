# Documentation overview

Short guide to the repository documentation. Start here before changing a baseline, inventory, or migration plan.

## Active planning

- `ROADMAP.md`: current phases, sequencing, and next migration steps.
- `DESIGN_BACKLOG.md`: accepted open design, behavior, and technical decisions.
- `MQTT_MIGRATION_PLAN.md`: gate and candidate review for the first writable MQTT pilot.

## Accepted baselines

- `SIMULATION_BASELINE.md`: accepted simulated full-house HMI reference.
- `MQTT_READONLY_BASELINE.md`: accepted read-only MQTT connection and safety boundary.

## MQTT inventory

- `MQTT_INVENTORY.md`: broker, network boundary, ownership context, and inventory workflow.
- `MQTT_DEVICE_INVENTORY.md`: generated Zigbee2MQTT and Discovery device inventory.
- `MQTT_TASMOTA_INVENTORY.md`: generated Tasmota device inventory.

## Archive

- `archive/PULL_REQUEST_SIMULATION_BASELINE.md`: completed simulation-baseline pull-request template.
- `archive/MERGE_CHECKLIST.md`: completed simulation-baseline merge checklist.

Archived documents remain versioned for traceability but are no longer operational instructions.

## Maintenance rules

- Keep active planning documents short and update them when a patch changes their scope.
- Keep accepted baselines stable; supersede them explicitly instead of silently rewriting history.
- Move completed one-time checklists and templates to `archive/`.
- Do not store raw MQTT captures, Home Assistant metadata exports, credentials, or temporary patch files under `docs/`.
- Add every maintained document to this overview and to the source-export allowlist.
