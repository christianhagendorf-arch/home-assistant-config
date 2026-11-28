# MQTT writable pilot migration plan

## Purpose

Patch 0031 prepares the decision for the first writable MQTT pilot without publishing a command, enabling Discovery, changing the broker, or deploying a runtime entity. The first writable change must be a separate patch with an explicit test and rollback procedure.

## Entry gates

All gates must be satisfied before a writable pilot patch is prepared:

- physical device and room/function are confirmed
- production Home Assistant entity and every production automation controlling it are identified
- exact state, command, availability, and telemetry topics are confirmed
- retained behavior is tested and documented for both state and command topics
- payloads for on, off, availability, and unknown/unavailable behavior are known
- production and `ha-test` cannot command the device concurrently
- rollback restores one authoritative controller without depending on retained commands
- the selected device is non-safety-critical and can be verified locally

## Candidate classes

| Candidate class | Inventory evidence | Suitability | Decision |
|---|---|---:|---|
| Tasmota plug or simple relay | Tasmota inventory includes Gosund, Maxcio, socket-swa11, and Sonoff devices with `cmnd/` candidates | Potentially suitable after physical mapping and production-automation review | Shortlist only |
| Zigbee IKEA light | Device inventory contains `ikea_kueche_licht_1` and `ikea_kueche_licht_2` | Technically simple, but Zigbee2MQTT Discovery and production ownership make dual control more likely | Defer |
| Heating or climate | Device inventory contains thermostat and Sonoff actuator candidates | High consequence because heating demand, pump logic, and Better Thermostat ownership are unresolved | Exclude from first pilot |
| Cover, appliance, notification, or occupancy automation | Inventory and backlog show cross-automation dependencies | State and automation ownership are not yet bounded | Exclude from first pilot |

## Preferred selection direction

Choose one physically accessible Tasmota plug or simple light relay that is not used for heating, refrigeration, networking, aquarium life support, security, access control, or an unattended appliance. Device names alone are not sufficient evidence. The final choice remains open until its physical function and production automation ownership are confirmed.

## Evidence to collect for the selected candidate

Record the following in this document before creating the writable implementation patch:

```text
Inventory name:
Physical device and location:
Current production entity:
Production automations/scripts/scenes:
State topic and payloads:
Command topic and payloads:
Availability topic and payloads:
Retain behavior:
Last known state after broker/device/Home Assistant restart:
Chosen controller during pilot:
Local verification method:
Rollback steps:
```

## Acceptance for Patch 0031

- documentation index exists and all maintained documents are classified
- completed merge documents are archived without content changes
- source export follows the archived paths and includes the new documents
- candidate classes and exclusion rules are documented
- no device is selected solely from a friendly name
- no MQTT command is published and no runtime or broker configuration changes

## Exit to the next patch

The next regular patch should implement exactly one writable pilot only after the evidence template is complete. If the evidence is incomplete, the next patch remains an inventory/ownership clarification patch rather than a control patch.

## Room-by-room migration

Migration is planned and accepted by room. Each room patch covers physical device mapping, entities, dashboard behavior, local controls, automations, scripts, scenes, failure behavior, rollback, and updates to the existing inventory and planning documents. No separate per-room documentation files are created. House-wide functions remain explicit shared dependencies and may require a later system patch.

## Technical naming convention

- Code, identifiers, aliases, comments, file names, and directory names use English.
- User-facing HMI text uses German; established contemporary English HMI terms are acceptable.
- Technical levels are `l0`, `l1`, and `l2`; the HMI labels remain `EG`, `OG`, and `DG`.
- `garden` is retained for the outdoor area and `shared` is reserved for genuinely house-wide logic.
- Room entities normally use the English room name without a level prefix, for example `sensor.office_temperature`.
- Level prefixes are used for level-wide behavior, for example `script.l2_lights_off`.
- Existing entity IDs are not renamed solely for taxonomy. Entity renames require a compatibility and reference review in the room patch that owns the entity.
## Patch 0033 office operating boundary
Patch 0033 allows manual control of the office pinboard and platform lights from `ha-test`, but does not migrate the physical wall-switch sequence. Production remains authoritative for that automation until a separate, attended cutover. Commands are never retained or queued for replay. Heating and shutter data are display-only.
