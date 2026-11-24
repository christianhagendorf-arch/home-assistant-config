# Simulated house HMI baseline

## Baseline identity

- Branch: `feature/living-room-pilot`
- Accepted UI milestone: Patch `0025`
- Source-export commit: `b7fbdc2ad8bc`
- Primary acceptance layout: smartphone
- Secondary acceptance layout: desktop
- Dashboard title: `Zuhause (Sim)`
- Dashboard views: `EG`, `OG`, `DG`, `Garten`

This baseline is the complete simulated and recoverable house HMI that is intended to be merged to `main` before real MQTT and entity integration begins.

## Simulated scope

### Erdgeschoss

- Hauseingang
- Hauswirtschaftsraum
- Gästebad
- Küche
- Wohnzimmer
- switching and dimming
- washer/dryer status, sockets, and notification controls
- room temperature and climate controls

### Obergeschoss

- Flur
- Arbeitszimmer
- Schlafzimmer
- Gästezimmer
- switching and dimming
- roller-shutter controls
- room temperature and climate controls

### Dachgeschoss

- Flur
- Lotta
- Lene
- Bad
- switching and dimming
- Aquarium
- normal room heating
- Lotta window heating as a separate climate function
- temperature-only DG hall footer

### Garten

- Garten
- Kinderhaus
- terrace and outdoor lighting
- dimmable Kinderhaus roof lighting
- Kinderhaus star

## Frontend components

Validated component versions during the simulation phase:

```text
Mushroom: 5.3.0
Stack In Card: 2.0.7
Card Mod: 4.2.1
Mushroom Themes: installed through HACS
```

The dashboard uses `Night Control Light` and `Night Control Dark`. The visible theme switch is intentionally removed until global, per-user, or per-device behavior is resolved.

## Accepted interaction rules

### Dimmable lights

- main card tap toggles the light
- main card off/on restores the last brightness
- plus while off starts at 10 percent
- plus/minus changes brightness by 10 percentage points
- minus at 10 percent switches off
- hold opens More Info for detailed control

### Climate

- Mushroom Climate Card remains the functional climate component
- target changes in 0.5 degree steps
- simulated `hvac_action` exposes `off`, `idle`, and `heating`
- room temperature and climate control remain in a footer
- Better Thermostat and real floor-heating abstractions are later integration work

### Roller shutters

- main HMI provides open, stop, and close
- simulation jumps between endpoints
- real position, movement, timing, and capabilities are validated later

## Deployment and recovery

- target host: `ha-test`
- Home Assistant configuration root: `/opt/ha-test/homeassistant/config`
- deployment uses `tools/apply_deploy_patch.ps1` and `tools/deploy_ha_test.py`
- deployment performs a dry-run before apply
- Home Assistant `check_config` runs before restart
- files are backed up locally on `ha-test` before apply
- post-patch Markdown source exports provide a reviewable source snapshot

## Accepted open design debt

The following items do not block the merge:

- visible Light/Dark switch remains removed
- possible future harmonization of light and climate step controls
- later review of floor-container versus room-card border weight
- popup/detail strategy and RGB presets
- washer/dryer fast-restart state-machine behavior and possible manual reset
- final real climate architecture, Better Thermostat selection, and pump logic

The authoritative working list remains `docs/DESIGN_BACKLOG.md`.
