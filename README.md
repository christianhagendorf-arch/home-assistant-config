# Home Assistant Config

Private repository for the redesigned Home Assistant configuration, Lovelace dashboards, themes, packages, and migration documentation.

## Status

The interactive HMI concept is approved in the separate repository `ha-hmi-mockup` at tag `v1.0.0`.

The executable Home Assistant migration begins with a Wohnzimmer pilot on the Raspberry Pi test system.

## Read first

1. `docs/DEVELOPER_HANDOFF.md`
2. `docs/HMI_ARCHITECTURE.md`
3. `docs/ENTITY_NAMING.md`
4. `docs/HARDWARE_INVENTORY.md`
5. `docs/ENTITY_MAPPING.md`
6. `docs/MIGRATION.md`

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
