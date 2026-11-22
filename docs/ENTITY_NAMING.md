# Entity Naming

**Project:** Home Assistant HMI Redesign  
**Document status:** Initial binding convention for the YAML pilot  
**Applies to:** New and migrated Home Assistant backend objects  
**Backend language:** English  
**HMI language:** German

## 1. Purpose

This document defines the naming rules for the Home Assistant redesign. The goal is to create predictable, readable, and maintainable identifiers without losing the permanent identity of physical devices.

The rules apply to new YAML, helpers, groups, scripts, scenes, automations, dashboards, and entity IDs created during the migration. Existing identifiers are not renamed merely for cosmetic reasons. Renaming occurs when a function is migrated into the new structure and the change can be documented in `ENTITY_MAPPING.md`.

## 2. Core principles

### 2.1 Backend English, HMI German

All new backend identifiers use English. The family-facing HMI uses concise German labels.

| Layer | Example |
|---|---|
| Physical/network name | `sonoff-mini-11` |
| Raw Home Assistant entity | `switch.sonoff_11` |
| Functional Home Assistant entity | `climate.living_room` |
| HMI room | `Wohnzimmer` |
| HMI control | `Heizung` |

### 2.2 Hardware identity must remain traceable

Permanent hardware numbers such as `11` in `sonoff_11` are retained in physical-device and raw-entity names. A number must not be reassigned to a replacement device unless the replacement physically takes over the documented installation position.

The functional HMI entity does not need the hardware number. The link between both layers is recorded in `HARDWARE_INVENTORY.md` and `ENTITY_MAPPING.md`.

### 2.3 Name the function, not the protocol

Functional entity IDs describe what the entity does and where it belongs. They do not expose implementation details such as Wi-Fi, Zigbee, MQTT, Sonoff, Shelly, Gosund, or Better Thermostat.

Preferred:

```text
light.kitchen_worktop
climate.living_room
cover.office_shutter
```

Avoid for functional entities:

```text
light.zigbee_0x00158d0001234567
climate.better_thermostat_wohnzimmer
cover.shelly25_channel_0
```

Implementation details remain appropriate for raw integration entities and device names.

### 2.4 Stable names over temporary use

Identifiers describe the stable installation purpose, not a temporary seasonal object.

Example: the kitchen window socket currently used for a Christmas Schwibbogen may later serve another decorative light. The backend identifier should therefore describe the stable location/function, while the HMI label may remain `Schwibbogen` while that is the family-recognized use.

Recommended backend candidate:

```text
switch.kitchen_window_decoration
```

Current HMI label:

```text
Schwibbogen
```

### 2.5 One canonical identifier per function

Each user-facing function has one canonical functional entity or group. Raw member entities remain available for diagnostics but are not used inconsistently across dashboards and automations.

Example:

```text
light.office_work_lights
```

may represent:

```text
switch.sonoff_mini_04_office_pinboard
light.office_platform
```

The group becomes the main HMI control. Individual members remain available in room details.

## 3. General syntax

### 3.1 Character rules

Entity object IDs use:

- lowercase ASCII letters
- digits where semantically required
- underscores as separators
- no spaces
- no hyphens
- no German umlauts
- no abbreviations unless defined in this document

Correct:

```text
light.living_room_arc_lamp
sensor.guest_bathroom_temperature
```

Incorrect:

```text
light.Wohnzimmer-Bogenlampe
sensor.gästebad_temp
```

### 3.2 Basic pattern

For most functional entities:

```text
<domain>.<room>_<function>
```

Examples:

```text
light.kitchen_worktop
switch.living_room_tv_board
cover.office_shutter
sensor.lotta_room_temperature
```

When a room has only one entity in a domain and the meaning is unambiguous, the function may be omitted for selected domains:

```text
climate.living_room
climate.kitchen
```

Do not use this shortening when multiple same-domain functions exist:

```text
climate.lotta_room
climate.lotta_room_window
```

### 3.3 Singular naming

Use singular nouns for one function or device:

```text
light.guest_room_table_lamp
```

Use plural only for a deliberate group:

```text
light.office_work_lights
```

### 3.4 No redundant domain words

Avoid repeating the Home Assistant domain in the object ID unless needed to distinguish the function.

Preferred:

```text
light.kitchen_worktop
cover.office_shutter
```

Avoid:

```text
light.kitchen_worktop_light
cover.office_shutter_cover
```

Exceptions are allowed when the natural function name itself contains the word, for example:

```text
switch.terrace_lighting_socket
```

## 4. Canonical room keys

The following English room keys are binding for the initial implementation.

| Floor | HMI label | Backend room key |
|---|---|---|
| Ground floor | Hauseingang | `entrance` |
| Ground floor | Wohnzimmer | `living_room` |
| Ground floor | Küche | `kitchen` |
| Ground floor | Gästebad | `guest_bathroom` |
| Ground floor | Hauswirtschaftsraum | `utility_room` |
| First floor | Flur | `first_floor_hall` |
| First floor | Arbeitszimmer | `office` |
| First floor | Schlafzimmer | `bedroom` |
| First floor | Gästezimmer | `guest_room` |
| Second floor | Flur | `second_floor_hall` |
| Second floor | Lotta | `lotta_room` |
| Second floor | Lene | `lene_room` |
| Garden | Terrasse | `terrace` |
| Garden | Kinderhaus | `playhouse` |

### 4.1 Floor keys

Use these keys for folders, dashboard sections, and structural identifiers:

```text
ground_floor
first_floor
second_floor
garden
```

`upper_floor` is not used in the target backend naming because `first_floor` is more explicit and aligns with the physical sequence above the ground floor. The existing HTML data key may remain unchanged until a later refactor because the HTML prototype is frozen at `v1.0.0`.

### 4.2 Child room names

The room keys `lotta_room` and `lene_room` intentionally include `_room`. This avoids names that look like person entities and makes entity IDs self-explanatory:

```text
light.lotta_room_ceiling
climate.lene_room
```

The HMI labels remain simply:

```text
Lotta
Lene
```

## 5. Physical device, MQTT, and network names

### 5.1 Stable device identity

Physical MQTT and firmware identifiers remain numbered and independent of room or purpose.

Preferred examples:

```text
sonoff-mini-11
sonoff-mini-12
gosund-plug-06
shelly-1pm-01
```

Do not rename a stable field device to encode the current installation purpose:

```text
sonoff-mini-11-heating-living-room
```

The purpose may change after a renovation or device move. The stable identifier must still identify the same physical unit.

### 5.2 Installation context belongs in documentation

The current room, installation position, electrical load, and function are recorded in `HARDWARE_INVENTORY.md` and linked through `ENTITY_MAPPING.md`.

Example:

```text
Stable MQTT/device ID: sonoff-mini-11
Current installation: living-room heating actuator
Current raw entity: switch.sonoff_11
Functional entity: climate.living_room
HMI: Wohnzimmer / Heizung
```

### 5.3 Router display names

A descriptive Fritz!Box display name may be used as an optional operator aid, for example:

```text
sonoff-mini-11-heating-wozi
```

This display name is not the canonical device identity and must not be used as the only mapping source.

### 5.4 Numbering rules

- Preserve the existing device number where one exists.
- Do not reuse a number for an unrelated physical device.
- A replacement in the same documented installation position may inherit an installation slot only when the replacement is recorded in the inventory history.
- Keep firmware/MQTT names within platform length restrictions.
- Do not silently invent room abbreviations in canonical identifiers.

### 5.5 Raw integration entities

Existing numbered raw entities may remain stable:

```text
switch.sonoff_11
switch.gosund_6
```

They are implementation entities and are not shown directly in the family HMI. Functional entities provide the stable room/function layer:

```text
climate.living_room
switch.living_room_tv_board
```

Raw-entity renaming is optional, not a migration objective. Rename only when the integration supports it safely and the benefit outweighs reference churn.

## 6. Domain-specific conventions

### 6.1 Climate

#### Normal room heating

```text
climate.<room>
```

Examples:

```text
climate.living_room
climate.kitchen
climate.office
climate.bedroom
climate.guest_room
climate.lotta_room
climate.lene_room
```

#### Additional room heating

```text
climate.<room>_<purpose>
```

Example:

```text
climate.lotta_room_window
```

HMI label:

```text
Fensterheizung
```

#### Climate-related sensors

```text
sensor.<room>_temperature
sensor.<room>_humidity
sensor.<room>_trv_temperature
sensor.<room>_trv_target_temperature
sensor.<room>_valve_position
```

Examples:

```text
sensor.living_room_temperature
sensor.living_room_trv_temperature
sensor.living_room_valve_position
sensor.lotta_room_window_temperature
```

The family HMI normally uses the room sensor and functional climate entity. TRV-specific sensors belong to the technical view.

### 6.2 Lights

Pattern:

```text
light.<room>_<function>
```

Initial target examples:

```text
light.living_room_arc_lamp
light.kitchen_worktop
light.kitchen_coffee_corner
light.kitchen_dining_corner
light.first_floor_hall_sideboard
light.office_platform
light.bedroom_ceiling
light.guest_room_table_lamp
light.second_floor_hall_shoe_cabinet
light.lotta_room_ceiling
light.lotta_room_table_lamp
light.lotta_room_aquarium
light.lene_room_ceiling
light.playhouse_roof
light.playhouse_star
light.playhouse_outside
```

For lights implemented by a switch domain, the preferred long-term approach is to expose a functional `light` entity when Home Assistant supports a reliable conversion or template abstraction. Until then, the mapping document records the actual domain.

### 6.3 Switches and sockets

Pattern:

```text
switch.<room>_<function>
```

Examples:

```text
switch.living_room_tv_board
switch.kitchen_window_decoration
switch.terrace_lighting_socket
```

Do not name a switched socket as a light in the backend if the function may change. The HMI may present it with a light icon and German lighting label when that is the current use.

### 6.4 Covers

Pattern:

```text
cover.<room>_shutter
```

Examples:

```text
cover.office_shutter
cover.bedroom_shutter
```

Use `shutter` consistently. Do not mix `blind`, `roller_shutter`, `rollladen`, and `shade` in new identifiers.

### 6.5 Binary sensors

Pattern:

```text
binary_sensor.<room>_<condition>
```

Examples:

```text
binary_sensor.guest_bathroom_occupancy
binary_sensor.utility_room_occupancy
binary_sensor.living_room_window
```

Use condition names that match Home Assistant device classes where practical:

```text
occupancy
motion
window
door
moisture
problem
```

Do not use both `motion` and `occupancy` for the same meaning without a documented distinction.

### 6.6 Sensors

Pattern:

```text
sensor.<room-or-system>_<measurement>
```

Examples:

```text
sensor.kitchen_temperature
sensor.washing_machine_power
sensor.home_assistant_uptime
sensor.raspberry_pi_cpu_temperature
```

Include units only in attributes, never in entity IDs.

Avoid:

```text
sensor.kitchen_temperature_celsius
sensor.washing_machine_watts
```

### 6.7 Groups

Functional groups use the domain matching the exposed behavior.

Examples:

```text
light.office_work_lights
light.kitchen_task_lights
```

Use `_lights` for a group of lights. Do not use generic names such as:

```text
group.office
light.all_lights_2
```

A group must have one understandable user purpose.

### 6.8 Helpers

Use the helper's native domain and a functional name.

Examples:

```text
input_boolean.guest_bathroom_light_automation
input_number.lotta_room_window_heating_target
input_select.washing_machine_state
input_datetime.home_assistant_last_restart
```

Avoid implementation-history names such as:

```text
input_boolean.test2
input_number.slider_new
```

### 6.9 Scripts

Pattern:

```text
script.<room-or-system>_<action>
```

Examples:

```text
script.living_room_arc_lamp_low
script.living_room_arc_lamp_medium
script.living_room_arc_lamp_high
script.office_lights_cycle
script.home_all_lights_off
```

Use a verb or resulting state at the end. Scripts must describe an action, not a device.

### 6.10 Scenes

Pattern:

```text
scene.<scope>_<purpose>
```

Examples:

```text
scene.living_room_evening
scene.kitchen_cooking
scene.office_work
scene.home_good_night
```

Scene IDs remain English. HMI labels may be German:

```text
Wohnzimmer Abend
Kochen
Arbeiten
Gute Nacht
```

Scenes are deferred until recurring use cases are confirmed.

### 6.11 Automations

Automation IDs and aliases serve different purposes.

#### Stable automation ID

Use a stable ASCII identifier:

```text
<scope>_<trigger-or-purpose>_<action>
```

Examples:

```text
guest_bathroom_occupancy_light
utility_room_occupancy_light
washing_machine_power_state
heating_pump_demand_control
```

#### Alias

Use a concise English technical alias:

```text
Guest bathroom: occupancy lighting
Washing machine: update operating state
Heating: control circulation pump from demand
```

#### Description

Each non-trivial automation should include a short description explaining why the automation exists, particularly for unusual logic such as the office/bedroom light cycling.

### 6.12 Packages

Package filenames use English snake_case and represent one coherent feature or room subsystem.

Examples:

```text
living_room_climate.yaml
kitchen_lighting.yaml
guest_bathroom_appliances.yaml
office_bedroom_lighting.yaml
lotta_room_window_heating.yaml
heating_pump_control.yaml
```

Avoid numeric floor prefixes in the target package names unless sorting proves materially useful. Directory structure already provides floor context.

### 6.13 Dashboard files and views

Recommended dashboard file names:

```text
home.yaml
technical.yaml
```

Recommended view or include names:

```text
overview.yaml
ground_floor.yaml
first_floor.yaml
second_floor.yaml
garden.yaml
```

Dashboard URLs use concise English slugs:

```text
overview
ground-floor
first-floor
second-floor
garden
technical
```

HMI titles remain German.

## 7. Initial functional target names

The following list is the current target vocabulary. It is not yet a confirmation that every entity exists or will retain the proposed domain. Final bindings belong in `ENTITY_MAPPING.md`.

### 7.1 Erdgeschoss

```text
light.entrance_outside
climate.living_room
light.living_room_arc_lamp
switch.living_room_tv_board
climate.kitchen
light.kitchen_worktop
light.kitchen_coffee_corner
light.kitchen_dining_corner
switch.kitchen_window_decoration
light.guest_bathroom_ceiling
sensor.washing_machine_state
sensor.dryer_state
light.utility_room_ceiling
```

### 7.2 Obergeschoss

```text
light.first_floor_hall_sideboard
climate.office
cover.office_shutter
light.office_work_lights
light.office_pinboard
light.office_platform
climate.bedroom
cover.bedroom_shutter
light.bedroom_ceiling
climate.guest_room
light.guest_room_table_lamp
```

### 7.3 Dachgeschoss

```text
light.second_floor_hall_shoe_cabinet
climate.lotta_room
climate.lotta_room_window
light.lotta_room_ceiling
light.lotta_room_table_lamp
light.lotta_room_aquarium
climate.lene_room
light.lene_room_ceiling
```

### 7.4 Garten

```text
switch.terrace_lighting_socket
light.playhouse_roof
light.playhouse_star
light.playhouse_outside
```

## 8. Friendly names and HMI labels

### 8.1 Friendly names

Home Assistant friendly names may be German because they are user-facing.

Examples:

```text
climate.living_room
friendly_name: Heizung
```

```text
light.kitchen_coffee_corner
friendly_name: Kaffee-Ecke
```

Do not include the room in a friendly name when the card already provides room context, unless the entity is also used in global lists where ambiguity would result.

### 8.2 Card-level names

Lovelace cards may override the friendly name to preserve short labels. This is acceptable for HMI clarity but should not hide an ambiguous backend entity.

### 8.3 Areas and floors

Home Assistant Areas use German display names for user-facing navigation:

```text
Wohnzimmer
Küche
Arbeitszimmer
```

Internal documentation and package paths use the English room keys defined in this document.

If Home Assistant Floors are configured, display names are German:

```text
Erdgeschoss
Obergeschoss
Dachgeschoss
Garten
```

## 9. Renaming and migration rules

### 9.1 Do not rename blindly

Before renaming an existing entity, check references in:

- automations
- scripts
- scenes
- groups
- helpers
- dashboards
- templates
- notifications
- external systems

### 9.2 Mapping is mandatory

Every migrated function receives an entry in `ENTITY_MAPPING.md` containing:

- HMI label
- target entity ID
- previous entity ID
- raw physical entity
- physical device/network name
- migration status
- notes and dependencies

### 9.3 Staged migration

Recommended statuses:

```text
planned
created
tested
switched-over
legacy-removed
```

A legacy entity is removed only after the replacement has been tested on the Home Assistant test system and all references have been updated.

### 9.4 Compatibility aliases

Temporary template entities or groups may preserve compatibility during migration. Such aliases must be marked as temporary and listed with a removal condition.

Example:

```text
legacy entity: switch.sonoff_11
new raw entity: switch.sonoff_11
functional entity: climate.living_room
removal condition: all automations and dashboards migrated
```

## 10. Reserved abbreviations

Use abbreviations sparingly. The following are allowed:

| Abbreviation | Meaning | Usage |
|---|---|---|
| `rgb` | red/green/blue color capability | entity function or attribute context |
| `trv` | thermostatic radiator valve | technical sensors only |
| `ha` | Home Assistant | system-level filenames or variables only when unambiguous |
| `mqtt` | MQTT protocol | technical entities and packages |
| `cpu` | central processing unit | system sensors |

Avoid room abbreviations such as:

```text
wozi
azi
kue
bad1
og_flur
```

Use the canonical English room keys instead.

## 11. Validation checklist

Before accepting a new identifier, verify:

- [ ] Backend identifier is English.
- [ ] HMI label is concise German.
- [ ] Identifier uses lowercase snake_case.
- [ ] Room key matches the canonical room table.
- [ ] Function describes user purpose, not protocol/vendor.
- [ ] Hardware number is preserved where applicable.
- [ ] Identifier is not ambiguous within its domain.
- [ ] No redundant domain suffix is present.
- [ ] Existing references were searched before a rename.
- [ ] Mapping and hardware inventory are updated.
- [ ] The name is likely to remain valid if hardware is replaced.

## 12. Decision log

| Decision | Status |
|---|---|
| New backend identifiers use English | Approved |
| HMI labels use concise German | Approved |
| Physical hardware numbers are preserved | Approved |
| Raw and functional entity layers are separated | Approved |
| Canonical room keys are binding | Approved |
| Home Assistant object IDs use snake_case | Approved |
| Physical/network names use hyphens | Approved |
| Functional names avoid vendor and protocol names | Approved |
| `shutter` is the standard cover term | Approved |
| `lotta_room` and `lene_room` include `_room` | Approved |
| Existing entities are migrated incrementally | Approved |
| Every rename requires mapping documentation | Approved |

## 13. Related documents

- `HMI_ARCHITECTURE.md`
- `HARDWARE_INVENTORY.md`
- `ENTITY_MAPPING.md`

The first practical validation of these rules will be the Wohnzimmer YAML pilot.
