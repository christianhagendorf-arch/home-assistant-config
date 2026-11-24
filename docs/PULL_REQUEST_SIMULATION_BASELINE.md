# Pull request: Complete simulated house HMI baseline

## Suggested title

```text
ui: complete simulated full-house HMI baseline
```

## Summary

This pull request merges the completed simulated house dashboard from `feature/living-room-pilot` into `main`.

The dashboard now contains smartphone-first views for EG, OG, DG, and Garden, with simulated lighting, dimming, climate, roller shutters, washer/dryer controls, Lotta window heating, and garden controls.

## Included

- complete YAML Lovelace dashboard
- separate simulation packages for EG, OG, DG, and Garden
- Night Control Light/Dark themes
- controlled `ha-test` deployment, dry-run, backup, rollback, and source export
- roadmap and design backlog
- accepted mobile and desktop design baseline

## Validation performed

- all four views deployed to `ha-test`
- primary smartphone acceptance completed
- desktop regression completed
- representative light, dimmer, climate, cover, appliance, and garden controls tested
- no reported configuration-error cards
- no reported red browser-console errors at acceptance
- Home Assistant `check_config` completed through deployment
- source export created after Patch 0025

## Known accepted debt

- visible Theme switch is intentionally removed
- Light/Dark themes remain manually selectable
- popup/details, RGB presets, and deeper technical views are later work
- real MQTT entities, Better Thermostat, floor-heating pump control, and production automations are not part of this pull request

## After merge

Create:

```text
feature/mqtt-readonly-baseline
```

Use the existing MQTT broker at `192.168.178.16` first for read-only or harmless sensor validation. Do not develop real integrations directly on `main`.

## Rollback reference

Before merging, create a final post-Patch-0026 source export. The Patch-0025 source reference is commit `b7fbdc2ad8bc`.
