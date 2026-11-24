# Home Assistant Config

Repository for the redesigned Home Assistant configuration, Lovelace dashboards, themes, packages, and migration documentation. Intended visibility: private.

## Status

The interactive HMI concept is approved in the separate repository `ha-hmi-mockup` at tag `v1.0.0`.

The simulated Wohnzimmer pilot passed the four recorded browser checks for patch 0003 on `ha-test` (22 November 2026, commit `1bdfb87`). This is a test acceptance only; no production rollout has been approved. See [the acceptance record](docs/DASHBOARD_DECISIONS.md) and [the tested deployment runbook](docs/HA_TEST_DEPLOY.md).

## Read first

1. [Current deployment runbook and handover entry point](docs/HA_TEST_DEPLOY.md)
2. `docs/DEVELOPER_HANDOFF.md` (design baseline; runtime workflow superseded by the runbook)
3. `docs/HMI_ARCHITECTURE.md`
4. `docs/ENTITY_NAMING.md`
5. `docs/HARDWARE_INVENTORY.md`
6. `docs/ENTITY_MAPPING.md`
7. `docs/MIGRATION.md`

## Principles

- German family HMI
- English backend identifiers
- stable numbered MQTT/device identities
- room/function mapping in documentation and functional entities
- optimize rather than copy legacy YAML
- test-system-first migration
- no secrets in Git

## Initial branches

```text
main
feature/living-room-pilot
feature/themes
```

## Security

This repository must remain private. Use `secrets.yaml` and never commit credentials, tokens, databases, `.storage`, backups, or private keys.
