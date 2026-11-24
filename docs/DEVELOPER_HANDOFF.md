# Developer Handoff

> **Operational update, 22 November 2026:** The active work branch is `feature/living-room-pilot`. Patch 0003 passed the recorded browser checks on `ha-test`. The current [deployment workflow](HA_TEST_DEPLOY.md) and [acceptance record](DASHBOARD_DECISIONS.md) supersede the implementation-status, tooling and deployment assumptions in this design handoff. The separate handover document contains the workstation and LAN details. No production deployment is in scope.


**Project:** Home Assistant dashboard and configuration redesign  
**Audience:** Additional Lovelace/YAML developer, including AI-assisted development with Claude or another coding assistant  
**Current status:** HTML HMI prototype approved; documentation baseline prepared; Home Assistant YAML pilot not yet started  
**Primary owner:** Christian Hagendorf

## 1. Objective

Build a new, optimized Home Assistant configuration and Lovelace dashboard from a validated HMI concept. The legacy configuration is evidence of existing behavior, not the target architecture.

The family-facing interface is German. All new backend identifiers are English. Physical MQTT/firmware device identifiers remain numbered and independent of room or purpose.

## 2. Authoritative sources

Read these documents before proposing implementation code:

1. `docs/HMI_ARCHITECTURE.md`
2. `docs/ENTITY_NAMING.md`
3. `docs/HARDWARE_INVENTORY.md`
4. `docs/ENTITY_MAPPING.md`

The approved interaction prototype is in the separate repository:

```text
christianhagendorf-arch/ha-hmi-mockup
```

Reference tag:

```text
v1.0.0
```

The HTML prototype validates interaction and information architecture. It is not a pixel-perfect Lovelace specification.

## 3. Project boundaries

### In scope

- Lovelace Sections dashboard
- Mushroom cards
- Dark and light Home Assistant themes
- room-oriented controls
- primary controls directly on room cards
- room detail popups where justified
- English target entity names
- migration on the Raspberry Pi test system
- operator/technical view in a later phase

### Out of scope for the first pilot

- production-system migration
- weather card
- favorites-based overview
- stairwell lights not yet installed
- automatic theme switching
- broad scene redesign
- automated Lotta window heating
- pixel-perfect HTML reproduction

## 4. Non-negotiable decisions

- Backend IDs are English; HMI labels are concise German.
- Floor keys are `ground_floor`, `first_floor`, `second_floor`, and `garden`.
- Physical device IDs such as `sonoff-mini-11` and `gosund-plug-06` remain stable and location-independent.
- Current installation purpose belongs in documentation and functional entities, not the MQTT device name.
- Existing code must not be copied blindly. Optimize structure and logic.
- Temperature controls use 0.5 °C steps.
- Main room cards show current temperature and heating target inline.
- Dimmer sliders appear only while the light is on.
- RGB presets belong in room details.
- Covers show Up, Stop, and Down on the main card.
- Lotta's window heating is a separate climate function in room details.
- Kinderhaus is a normal room card.
- Technical/TRV/Better Thermostat diagnostics stay out of the family HMI.

## 5. Git and repository strategy

Create a new private repository for executable Home Assistant configuration:

```text
home-assistant-config
```

Keep `ha-hmi-mockup` frozen as the design reference.

Recommended initial branches:

```text
main
feature/living-room-pilot
feature/themes
```

Rules:

- `main` contains only tested states.
- Work happens in feature branches.
- Use pull requests for review, even for a private single-owner project when an external developer contributes.
- Never commit secrets, tokens, databases, `.storage`, backups, or private certificates.
- Do not commit HACS-managed files unless deliberately vendored.

## 6. Development environment

### Laptop

- Microsoft Copilot chat
- browser and `github.dev`
- documentation review

### Mini-PC

- Windows 11
- Git for Windows
- GitHub Desktop
- Visual Studio Code
- Live Server for the HTML prototype
- preferred local workspace for Home Assistant configuration development

### Test system

- Raspberry Pi 3B+
- Home Assistant test instance
- existing remote access previously performed with Visual Studio Code Remote SSH and FileZilla

The initial Home Assistant workflow should remain simple:

```text
Mini-PC local repository
→ feature branch
→ commit/push
→ deploy selected files to Raspberry Pi test system
→ configuration check
→ restart/reload only the required integration
→ functional test
→ merge after success
```

Remote SSH may be reintroduced if stable. Git is used for versioning and collaboration, not as a reason to complicate deployment.

## 7. Target repository baseline

Proposed initial structure:

```text
home-assistant-config/
├── README.md
├── .gitignore
├── docs/
│   ├── HMI_ARCHITECTURE.md
│   ├── ENTITY_NAMING.md
│   ├── HARDWARE_INVENTORY.md
│   ├── ENTITY_MAPPING.md
│   ├── DEVELOPER_HANDOFF.md
│   └── MIGRATION.md
├── config/
│   ├── configuration.yaml
│   ├── packages/
│   │   ├── ground_floor/
│   │   ├── first_floor/
│   │   ├── second_floor/
│   │   ├── garden/
│   │   └── system/
│   ├── dashboards/
│   │   ├── home.yaml
│   │   ├── technical.yaml
│   │   └── views/
│   └── themes/
│       ├── night_control_dark.yaml
│       └── night_control_light.yaml
└── tools/
    └── README.md
```

Do not assume this structure is final until it has been checked against the existing `configuration.yaml`, include strategy, and the capabilities of the Home Assistant version installed on the test system.

## 8. Implementation priorities

### Pilot 1: Wohnzimmer

Validate:

- target include/package structure
- Sections layout
- Mushroom climate card
- inline current/target temperature
- TV-Board switch
- Bogenlampe functional abstraction and presets
- dark/light theme variables
- responsive rendering
- migration and rollback workflow

Known legacy evidence:

```text
sensor.temp_wozi_temperature
climate.heizung_wohnzimmer
switch.sonoff_11
switch.shelly1pm_244cab4330f0
sensor.shelly1pm_244cab4330f0_power
script.bogenlampe_intensity_low
script.bogenlampe_intensity_med
script.bogenlampe_intensity_high
switch.gosund_6
sensor.gosund_6_energy_power
```

Important investigations:

- confirm whether `auto` is truly supported by the chosen climate implementation
- add bounded retries/timeouts to the Bogenlampe preset logic
- preserve TV-Board low-power auto-off behavior
- verify heating-pump demand dependency

### Pilot 2: Küche

Validate:

- multiple primary controls in one room card
- conditional dimmers
- physical coupling between worktop and coffee-corner power
- stable backend name for seasonal window decoration socket

### Pilot 3: Arbeitszimmer

Validate:

- cover Up/Stop/Down
- grouped main work light
- separate pinboard and platform detail controls
- cyclic office/bedroom physical switching logic

## 9. Lovelace implementation guidance

Preferred order:

1. Home Assistant Sections
2. Mushroom cards and native card features
3. Theme variables
4. Browser Mod only where room details materially benefit
5. `card-mod` only for targeted gaps

Avoid:

- large fragile CSS blocks tied to internal Shadow DOM
- undocumented custom-card dependencies
- copying legacy YAML without understanding it
- duplicating entity logic in the dashboard
- putting raw device entities directly in the family HMI when a functional abstraction exists

Every externally sourced Mushroom, Browser Mod, Sections, or card-mod option must be checked against current official documentation and the test-system version.

## 10. Security and privacy

The configuration repository is private.

Exclude at minimum:

```text
secrets.yaml
.storage/
.cloud/
home-assistant_v2.db
*.db-shm
*.db-wal
backups/
tts/
*.pem
*.key
```

Review before sharing:

- IP addresses
- external URLs
- MQTT credentials
- API tokens
- MAC/IEEE addresses
- exact household presence information

Use placeholders or `secrets.yaml` references in shared code.

## 11. Required deliverable format from another developer

For every proposed change provide:

- branch name
- changed file list
- assumptions
- required custom integrations/cards and versions
- complete YAML, not isolated fragments without placement instructions
- validation steps
- Home Assistant configuration-check result
- reload/restart requirements
- rollback steps
- documentation changes

Do not deliver only screenshots or conceptual YAML.

## 12. Acceptance criteria

A feature is ready to merge when:

- YAML parses successfully
- Home Assistant configuration check passes
- no secrets are committed
- target entities match `ENTITY_NAMING.md`
- mappings are updated
- physical devices remain traceable
- desktop/tablet/mobile behavior is acceptable
- light and dark themes remain readable
- unavailable entities do not break the view
- rollback is documented
- the feature is tested on the Raspberry Pi test system

## 13. Immediate next steps

1. Correct the four baseline documents so stable MQTT/device names are location-independent.
2. Create the private `home-assistant-config` repository.
3. Add `.gitignore`, README, and documentation.
4. Copy only the minimum existing configuration needed to understand includes and the Wohnzimmer pilot.
5. Create `feature/living-room-pilot`.
6. Complete physical/entity verification items in the Wohnzimmer mapping.
7. Implement and test the pilot.
8. Review through a pull request before merging to `main`.

## 14. Questions the new developer must not assume

- Which Home Assistant version runs on the test system?
- Which Mushroom, Browser Mod, Better Thermostat, card-mod, and HACS versions are installed?
- Does the selected climate platform natively support `auto`?
- Which current entity IDs are integration-generated and unsafe to rename?
- Which physical devices are reachable through MQTT, Zigbee, or another integration?
- Which deployment method will be used initially: FileZilla, Remote SSH, or another process?

These questions are resolved from the test system and documentation, not guessed.
