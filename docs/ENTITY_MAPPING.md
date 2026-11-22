# Entity Mapping

**Project:** Home Assistant HMI Redesign  
**Document status:** Initial migration map based on the reviewed legacy configuration and approved target architecture  
**Purpose:** Connect HMI functions, target entities, legacy entities, and physical hardware  
**Backend language:** English  
**HMI language:** German

## 1. Purpose

This document is the operational bridge between the current Home Assistant installation and the new target architecture.

Each mapping answers:

```text
German HMI function
→ target functional entity
→ current/legacy entity
→ physical device or raw entity
→ migration status
```

This document grows room by room. Values marked `TBD` require configuration review or physical verification before migration.

## 2. Mapping principles

1. Do not rename or remove a legacy entity until all references have been searched.
2. Physical device numbers remain traceable.
3. New functional entity IDs use English names from `ENTITY_NAMING.md`.
4. HMI labels remain concise German.
5. A functional entity may abstract one or more raw entities.
6. Direct entity reuse is allowed when the existing integration entity already has the correct function and capabilities.
7. Temporary compatibility entities must include a removal condition.
8. Every migrated function receives a tested rollback path.

## 3. Status vocabulary

| Status | Meaning |
|---|---|
| `planned` | Target is defined but not created |
| `to_verify` | Existing entity, hardware, or behavior is not confirmed |
| `mapped` | Legacy, hardware, and target relationship is documented |
| `created` | Target entity/configuration exists on the test system |
| `tested` | Function is verified on the test system |
| `switched_over` | New dashboard/automation uses the target entity |
| `legacy_removed` | Old configuration is removed or disabled |
| `not_required` | No migration object is required |

## 4. Mapping fields

| Field | Meaning |
|---|---|
| Floor / room | Canonical target location |
| HMI label | German family-facing label |
| Capability | Switch, dimmer, RGB, climate, cover, or status |
| Target functional entity | Stable entity used by HMI and new automations |
| Current/legacy entity | Entity currently used by the legacy installation |
| Physical/raw entity | Device-level entity or hardware identifier |
| Source/configuration | Legacy file or subsystem providing evidence |
| Migration approach | Reuse, rename, template, group, rebuild, or verify |
| Status | Migration state |
| Notes / validation | Dependencies, tests, and open questions |

## 5. Erdgeschoss mappings

### 5.1 Hauseingang

| HMI label | Capability | Target functional entity | Current/legacy entity | Physical/raw entity | Source/configuration | Migration approach | Status | Notes / validation |
|---|---|---|---|---|---|---|---|---|
| Außenbeleuchtung | Switch/light | `light.entrance_outside` | TBD | TBD | Existing dashboard/configuration to review | Verify current controller; expose as functional light if reliable | `to_verify` | Record device number, switch-box position, and actual domain. |

### 5.2 Wohnzimmer

| HMI label | Capability | Target functional entity | Current/legacy entity | Physical/raw entity | Source/configuration | Migration approach | Status | Notes / validation |
|---|---|---|---|---|---|---|---|---|
| Raumtemperatur | Sensor | `sensor.living_room_temperature` | `sensor.temp_wozi_temperature` | Physical temperature sensor TBD | `wozi_climate.yaml`, `eg.yaml` | Verify the physical sensor, then rename or create a compatibility alias | `mapped` | The entity is confirmed as the `generic_thermostat` target sensor and dashboard room temperature. Physical model and placement remain to verify; keep separate from any TRV temperature. |
| Heizung | Climate | `climate.living_room` | `climate.heizung_wohnzimmer` | `switch.sonoff_11` / `HW-SONOFF-MINI-11` | `wozi_climate.yaml`, `eg.yaml`, `hwr_pumpe.yaml` | Rebuild or safely rename the existing `generic_thermostat`; preserve the confirmed 16–24 °C range and 0.5 °C target step | `mapped` | Current configuration uses target `21.5 °C`, cold tolerance `0.1`, hot tolerance `0`, keep-alive `3 min`, initial mode `heat`, away `18 °C`, comfort `21.5 °C`, sleep `16 °C`, and precision `0.1`. Native support for `auto` is not proven by the generic thermostat configuration even though the legacy dashboard offers it; verify before implementing the target HVAC modes. Validate restart behavior and heating-pump demand integration. |
| Bogenlampe | Switched light with presets | `light.living_room_arc_lamp` (preferred functional abstraction; confirm during pilot) | `switch.shelly1pm_244cab4330f0`; `script.bogenlampe_intensity_low`; `script.bogenlampe_intensity_med`; `script.bogenlampe_intensity_high` | `switch.shelly1pm_244cab4330f0`; `sensor.shelly1pm_244cab4330f0_power`; physical Shelly model/location TBD | `wozi_lampe.yaml` | Build a functional light abstraction for normal on/off and retain three explicit preset actions; do not model it as a normal percentage dimmer | `mapped` | Presets are reached by repeated 200 ms power cycles with 8 s settling time and power thresholds: low `<4.0 W`, medium `4.5–6.5 W`, high `>7 W`. Add retry/time-out protection before replacing the legacy scripts, otherwise the current unbounded repeat can loop indefinitely when the power sensor is unavailable or never reaches the threshold. Verify off-state detection and power-loss behavior. |
| TV-Board | Switch | `switch.living_room_tv_board` | `switch.gosund_6` | `switch.gosund_6`; `sensor.gosund_6_energy_power`; `HW-GOSUND-PLUG-06` | `wozi_tv_board.yaml` | Create a stable functional switch or safely rename the existing entity; preserve the automatic shutdown and physical/MQTT button behavior | `mapped` | Confirmed auto-off: power below `5 W` for `5 min` turns the socket off. Confirmed MQTT/device-button action turns it on only while currently off. Device IDs are legacy-installation references and must be remapped if the device registry changes. |

### 5.3 Küche

| HMI label | Capability | Target functional entity | Current/legacy entity | Physical/raw entity | Source/configuration | Migration approach | Status | Notes / validation |
|---|---|---|---|---|---|---|---|---|
| Raumtemperatur | Sensor | `sensor.kitchen_temperature` | Existing room-temperature sensor TBD | Physical temperature sensor TBD | `kueche_climate.yaml`, climate view | Reuse or rename verified room sensor | `to_verify` | Confirm sensor placement and TRV separation. |
| Heizung | Climate | `climate.kitchen` | Legacy generic thermostat entity TBD | `switch.sonoff_12` / `HW-SONOFF-MINI-12` | `kueche_climate.yaml` | Rebuild functional climate entity; preserve 0.5 °C step and pump-demand relationship | `mapped` | Validate actuator and source sensor. |
| Arbeitsfläche | Dimmer | `light.kitchen_worktop` | Member of legacy kitchen lighting TBD | Controller(s) TBD | `kueche_licht.yaml`, user confirmation | Split functional entity from legacy group while documenting physical coupling | `to_verify` | Dimmable. Physical Sonoff switch also switches coffee corner. Identify raw members. |
| Kaffee-Ecke | Dimmer | `light.kitchen_coffee_corner` | Member of legacy kitchen lighting TBD | Dimmer/controller TBD | `kueche_licht.yaml`, user confirmation | Create independent functional dimmer while retaining coupled physical switching behavior | `to_verify` | Dimmable. Confirm off/on behavior when shared physical switch changes state. |
| Essecke | Switch/light | `light.kitchen_dining_corner` | TBD | Decorative window lamp/socket TBD | Current dashboard/user confirmation | Reuse appropriate light or switch; prefer light abstraction if stable | `to_verify` | Non-dimmable decorative light. |
| Schwibbogen | Switch/socket | `switch.kitchen_window_decoration` | TBD | Numbered smart socket TBD | Current dashboard/user confirmation | Use stable location/function name; HMI may show `Schwibbogen` seasonally | `to_verify` | Non-dimmable. Confirm outlet and device number. |
| Küchenlicht-Gruppe | Optional group | `light.kitchen_task_lights` | `light.kitchen_lights` | Members include two IKEA lights per legacy configuration | `kueche_licht.yaml` | Defer until individual mappings are validated | `planned` | Lighting groups/scenes are not part of initial pilot. |

### 5.4 Gästebad

| HMI label | Capability | Target functional entity | Current/legacy entity | Physical/raw entity | Source/configuration | Migration approach | Status | Notes / validation |
|---|---|---|---|---|---|---|---|---|
| Licht | Switch/light | `light.guest_bathroom_ceiling` | `switch.sonoff_15` | `HW-SONOFF-MINI-15` | `gaestebad_licht.yaml` | Expose as functional light if practical; preserve motion automation | `mapped` | Confirm manual override and seven-minute timeout. |
| Bewegung/Belegung | Binary sensor | `binary_sensor.guest_bathroom_occupancy` | `binary_sensor.motion_gaestebad_occupancy` | Motion sensor TBD | `gaestebad_licht.yaml` | Rename/migrate after device verification | `mapped` | Decide whether semantic condition is `occupancy` or `motion`; use consistently. |
| Waschmaschine | Status sensor | `sensor.washing_machine_state` | Legacy state helper/entity TBD | Smart plug TBD | `waschmaschine.yaml` | Preserve state machine behind a normalized status sensor | `mapped` | States include idle/running/finishing/clean. Confirm raw plug and power entity. |
| Trockner | Status sensor | `sensor.dryer_state` | Legacy state helper/entity TBD | Smart plug TBD | `trockner.yaml` | Preserve state machine behind a normalized status sensor | `mapped` | States include idle/running/finishing/clean. Confirm raw plug and power entity. |

### 5.5 Hauswirtschaftsraum

| HMI label | Capability | Target functional entity | Current/legacy entity | Physical/raw entity | Source/configuration | Migration approach | Status | Notes / validation |
|---|---|---|---|---|---|---|---|---|
| Licht | Switch/light | `light.utility_room_ceiling` | `switch.sonoff_14` | `HW-SONOFF-MINI-14` | `hwr_licht.yaml` | Expose as functional light; preserve motion automation | `mapped` | Confirm manual override and timeout behavior. |
| Bewegung/Belegung | Binary sensor | `binary_sensor.utility_room_occupancy` | `binary_sensor.motion_hwr_occupancy` | Motion sensor TBD | `hwr_licht.yaml` | Rename/migrate after device verification | `mapped` | Record vendor, Zigbee name, placement, and battery entity. |
| Heizungspumpe | Technical switch | Target raw/technical entity TBD | `switch.lsc_1_heizung_pumpe` | Heating-pump device TBD | `hwr_pumpe.yaml` | Rebuild demand-control automation after all climate mappings are known | `mapped` | Technical view only. Current demand derives from living-room and kitchen actuators. |

## 6. Obergeschoss mappings

### 6.1 Flur

| HMI label | Capability | Target functional entity | Current/legacy entity | Physical/raw entity | Source/configuration | Migration approach | Status | Notes / validation |
|---|---|---|---|---|---|---|---|---|
| Kommode | Dimmer | `light.first_floor_hall_sideboard` | `light.led_ww_2` | `HW-LED-WW-02` | `lichtschalter_kommode.yaml` | Rename or expose stable functional light | `mapped` | White LED strip, dimmable, not RGB. |

### 6.2 Arbeitszimmer

| HMI label | Capability | Target functional entity | Current/legacy entity | Physical/raw entity | Source/configuration | Migration approach | Status | Notes / validation |
|---|---|---|---|---|---|---|---|---|
| Raumtemperatur | Sensor | `sensor.office_temperature` | Existing room sensor TBD | Physical sensor TBD | `og.yaml`, climate view | Verify and rename | `to_verify` | Separate from TRV temperature. |
| Heizung | Climate | `climate.office` | `climate.thermostat_arbeitszimmer_bt` or current functional entity | TRV/Better Thermostat devices TBD | `og.yaml` | Determine whether Better Thermostat entity can become canonical functional climate entity | `to_verify` | Record TRV, room sensor, valve position, battery, and modes. |
| Rollladen | Cover | `cover.office_shutter` | `cover.rollladen_arbeitszimmer` | Cover controller TBD | `og.yaml` | Rename/migrate after calibration and controller verification | `mapped` | Main HMI: Up/Stop/Down. Position slider in details later. |
| Arbeitslicht | Light group | `light.office_work_lights` | Legacy combined behavior TBD | `switch.sonoff_4`, `light.led_ww_1` | `arbeitszimmer_schalter.yaml` | Create functional group or template control | `mapped` | Main-card group; detail controls remain separate. Validate group state and partial-on behavior. |
| Pinnwand | Switch/light | `light.office_pinboard` | `switch.sonoff_4` | `HW-SONOFF-MINI-04` | `arbeitszimmer_schalter.yaml` | Expose as light abstraction if practical | `mapped` | Non-dimmable detail function. |
| Podest | Dimmer | `light.office_platform` | `light.led_ww_1` | `HW-LED-WW-01` | `arbeitszimmer_schalter.yaml` | Rename or retain entity with stable target ID | `mapped` | Dimmable, not RGB. |
| Office/bedroom cycle logic | Subsystem | Script/automation IDs TBD | Legacy automation/state logic | Sonoff input plus multiple light controllers | `arbeitszimmer_schalter.yaml` | Rebuild only after exact state machine and restart behavior are documented | `to_verify` | Critical technical dependency. Preserve separate office and bedroom HMI functions. |

### 6.3 Schlafzimmer

| HMI label | Capability | Target functional entity | Current/legacy entity | Physical/raw entity | Source/configuration | Migration approach | Status | Notes / validation |
|---|---|---|---|---|---|---|---|---|
| Raumtemperatur | Sensor | `sensor.bedroom_temperature` | Existing room sensor TBD | Physical sensor TBD | `og.yaml`, climate view | Verify and rename | `to_verify` | Separate from TRV temperature. |
| Heizung | Climate | `climate.bedroom` | Existing Better Thermostat/climate entity TBD | TRV/Better Thermostat devices TBD | `og.yaml` | Select canonical functional climate entity | `to_verify` | HVAC modes and 0.5 °C target steps required. |
| Rollladen | Cover | `cover.bedroom_shutter` | Current entity TBD | Cover controller TBD | Existing dashboard/configuration | Identify raw cover and migrate | `to_verify` | Main HMI: Up/Stop/Down. |
| Schlafzimmerlicht | RGB dimmer | `light.bedroom_ceiling` | `light.led_rgbw_4` | `HW-LED-RGBW-04`; switching input linked to cyclic subsystem | `arbeitszimmer_schalter.yaml` | Preserve functional light; rebuild physical switch-cycle logic separately | `mapped` | Main HMI shows on/off and dimmer; RGB only in details. |

### 6.4 Gästezimmer

| HMI label | Capability | Target functional entity | Current/legacy entity | Physical/raw entity | Source/configuration | Migration approach | Status | Notes / validation |
|---|---|---|---|---|---|---|---|---|
| Raumtemperatur | Sensor | `sensor.guest_room_temperature` | Existing room sensor TBD | Physical sensor TBD | `og.yaml`, climate view | Verify and rename | `to_verify` | Separate from TRV temperature. |
| Heizung | Climate | `climate.guest_room` | Existing climate entity TBD | TRV/Better Thermostat devices TBD | `og.yaml` | Select canonical functional climate entity | `to_verify` | Test HVAC modes and sensor binding. |
| Tischlampe | Dimmer | `light.guest_room_table_lamp` | `light.bulb_2` | `HW-BULB-02` | `gaeste_tischlampe.yaml` | Rename or retain with stable target ID | `mapped` | Dimmable. Existing remote brightness-up/down automations must be preserved or simplified. |

## 7. Dachgeschoss mappings

### 7.1 Flur

| HMI label | Capability | Target functional entity | Current/legacy entity | Physical/raw entity | Source/configuration | Migration approach | Status | Notes / validation |
|---|---|---|---|---|---|---|---|---|
| Schuhschrank | Switch/light | `light.second_floor_hall_shoe_cabinet` | Current entity TBD | Controller TBD | Existing dashboard/configuration | Identify and expose stable functional light | `to_verify` | Non-confirmed capability; verify whether dimmable. |

### 7.2 Lotta

| HMI label | Capability | Target functional entity | Current/legacy entity | Physical/raw entity | Source/configuration | Migration approach | Status | Notes / validation |
|---|---|---|---|---|---|---|---|---|
| Raumtemperatur | Sensor | `sensor.lotta_room_temperature` | Existing room sensor TBD | Physical sensor TBD | `dg.yaml`, climate view | Verify and rename | `to_verify` | Separate from TRV and window-heating sensor. |
| Heizung | Climate | `climate.lotta_room` | `climate.thermostat_lotta_bt` or current functional entity | TRV/Better Thermostat devices TBD | `dg.yaml` | Determine canonical functional climate entity | `to_verify` | Maintain 0.5 °C steps and HVAC modes. |
| Fensterheizung | Climate | `climate.lotta_room_window` | `climate.fensterheizung` | Actuator and dedicated sensor TBD | `lotta_fensterheizung_climate.yaml`, `dg.yaml` | Rebuild/rename generic thermostat after actuator/sensor verification | `mapped` | Detail function. Intended for condensation prevention. Future outdoor-temperature automation deferred. |
| Fensterheizung Temperatur | Sensor | `sensor.lotta_room_window_temperature` | Existing sensor TBD | Dedicated physical sensor TBD | `lotta_fensterheizung_climate.yaml` | Verify semantics and rename | `to_verify` | Confirm whether sensor measures window area or room air. |
| LED-Decke | RGB dimmer | `light.lotta_room_ceiling` | `light.led_rgbw_2` | `HW-LED-RGBW-02`, physical switch `HW-SONOFF-ZBMINIR2-DG1` | `lichtschalter_lotta.yaml` | Preserve functional light; map physical switch behavior | `mapped` | Main HMI on/off and dimmer; RGB in details. |
| Tischlampe | Dimmer | `light.lotta_room_table_lamp` | `light.bulb_1` | `HW-BULB-01` | `lotta_tischlampe.yaml` | Rename or retain with stable target ID | `mapped` | Preserve MQTT/remote brightness controls. |
| Aquarium | Switch/light | `light.lotta_room_aquarium` | Current entity TBD | Physical switch/socket TBD | Existing dashboard/user confirmation | Identify and expose functional light | `to_verify` | Non-dimmable, non-RGB. Confirm any schedule. |

### 7.3 Lene

| HMI label | Capability | Target functional entity | Current/legacy entity | Physical/raw entity | Source/configuration | Migration approach | Status | Notes / validation |
|---|---|---|---|---|---|---|---|---|
| Raumtemperatur | Sensor | `sensor.lene_room_temperature` | Existing room sensor TBD | Physical sensor TBD | `dg.yaml`, climate view | Verify and rename | `to_verify` | Separate from TRV temperature. |
| Heizung | Climate | `climate.lene_room` | Existing climate entity TBD | TRV/Better Thermostat devices TBD | `dg.yaml` | Select canonical functional climate entity | `to_verify` | Maintain HVAC modes and 0.5 °C steps. |
| LED-Decke | RGB dimmer | `light.lene_room_ceiling` | `light.led_rgbw_3` | `HW-LED-RGBW-03`, switching input linked to `sonoff_9` per legacy configuration | `lichtschalter_lene.yaml` | Preserve functional light and document shared physical logic | `mapped` | Main HMI on/off and dimmer; RGB in details. Verify cycle relationship with office/bedroom subsystem. |

## 8. Garten mappings

### 8.1 Terrasse

| HMI label | Capability | Target functional entity | Current/legacy entity | Physical/raw entity | Source/configuration | Migration approach | Status | Notes / validation |
|---|---|---|---|---|---|---|---|---|
| Terrassenlicht | Switch/socket | `switch.terrace_lighting_socket` | Current entity TBD | Outdoor smart socket TBD | Existing dashboard/user confirmation | Keep socket semantics in backend; present as lighting in HMI | `to_verify` | Confirm device number, outlet location, and weather protection. |

### 8.2 Kinderhaus

| HMI label | Capability | Target functional entity | Current/legacy entity | Physical/raw entity | Source/configuration | Migration approach | Status | Notes / validation |
|---|---|---|---|---|---|---|---|---|
| Dachbeleuchtung | Switch/light | `light.playhouse_roof` | Current entity TBD | Controller TBD | Existing dashboard/user confirmation | Identify and expose functional light | `to_verify` | Normal room function; no hero treatment. |
| Stern | Switch/light | `light.playhouse_star` | Current entity TBD | Controller TBD | Existing dashboard/user confirmation | Identify and expose functional light | `to_verify` | Non-dimmable unless physical verification shows otherwise. |
| Beleuchtung neben Kinderhaus | Switch/light | `light.playhouse_outside` | Current entity TBD | Controller TBD | Existing dashboard/user confirmation | Identify and expose functional light | `to_verify` | Record physical location and load. |

## 9. Technical-view mappings

These entities are not primary family-HMI controls but require consistent technical mappings.

| Technical function | Target entity | Current/legacy source | Migration approach | Status | Notes |
|---|---|---|---|---|---|
| Heating pump state | TBD | `switch.lsc_1_heizung_pumpe` | Verify hardware and expose in technical view | `mapped` | Do not present as a family control. |
| Home Assistant uptime | `sensor.home_assistant_uptime` | TBD | Add supported integration/helper | `planned` | Technical view. |
| Last Home Assistant restart | `sensor.home_assistant_last_restart` or helper TBD | TBD | Implement with reliable source | `planned` | Distinguish planned restart from crash only if evidence is available. |
| Raspberry Pi CPU temperature | `sensor.raspberry_pi_cpu_temperature` | TBD | Add supported system monitor source | `planned` | Technical view. |
| Raspberry Pi storage usage | `sensor.raspberry_pi_storage_used_percent` | TBD | Add supported system monitor source | `planned` | Define warning threshold during technical-view design. |
| Unavailable entity count | `sensor.home_assistant_unavailable_entity_count` | TBD | Template sensor or dashboard query | `planned` | Technical overview indicator. |
| Zigbee2MQTT status | `binary_sensor.zigbee2mqtt_available` | TBD | Define based on actual deployment | `planned` | Only if Zigbee2MQTT remains part of target system. |
| MQTT status | `binary_sensor.mqtt_available` | TBD | Define based on broker/integration | `planned` | Only if reliable status source exists. |

## 10. Compatibility and dependency mapping

### 10.1 Living-room climate dependencies

```text
sensor.living_room_temperature
+ switch.sonoff_mini_11_heating_living_room
→ climate.living_room
→ heating pump demand
→ HMI Wohnzimmer / Heizung
```

Validation required:

- sensor availability behavior
- actuator unavailable behavior
- target restore behavior after restart
- HVAC modes actually supported by chosen implementation
- heating-pump demand timing

### 10.2 Kitchen lighting dependencies

```text
physical Sonoff switch
→ worktop power
→ coffee-corner power

light.kitchen_worktop
light.kitchen_coffee_corner
→ separate HMI controls
```

The mapping must document which actions are physically independent and which are coupled.

### 10.3 Office/bedroom lighting dependencies

```text
physical switch sequence
→ office state
→ bedroom state
→ both state
```

The migration must preserve:

- separate functional entities
- deterministic state behavior
- restart/power-loss recovery
- manual operation
- safe rollback to legacy logic

## 11. Migration procedure per mapping row

1. Verify physical device and current entity.
2. Search all references to the legacy entity.
3. Confirm target ID against `ENTITY_NAMING.md`.
4. Add or update `HARDWARE_INVENTORY.md`.
5. Create target entity/configuration on the test system.
6. Test direct function and unavailable behavior.
7. Test dependent automations, groups, scripts, and dashboards.
8. Switch the new HMI control to the target entity.
9. Observe through a reasonable household-use cycle.
10. Mark `switched_over` only after successful testing.
11. Remove legacy configuration only when rollback is no longer needed.

## 12. Pilot mapping checklist: Wohnzimmer

Before writing the first production-like YAML pilot, complete these items:

- [ ] Confirm current room-temperature sensor entity.
- [ ] Confirm physical room-temperature sensor location.
- [ ] Confirm `switch.sonoff_11` controls only living-room heating.
- [ ] Confirm stable MQTT/device ID `sonoff-mini-11`. Record the current descriptive Fritz!Box display name separately.
- [ ] Do not rename the stable MQTT/device ID for room or purpose; only document or adjust the optional router display name if useful.
- [ ] Confirm current generic-thermostat entity ID.
- [ ] Confirm required HVAC modes with the selected climate implementation.
- [ ] Confirm 0.5 °C target step.
- [ ] Confirm heating-pump demand behavior.
- [ ] Identify Bogenlampe switch, power sensor, and scripts.
- [ ] Confirm Bogenlampe preset behavior after power loss.
- [ ] Confirm TV-Board switch and power sensor entities.
- [ ] Confirm TV-Board automatic shutdown behavior.
- [ ] Search all legacy entity references.
- [ ] Define rollback procedure.

## 13. Review rules

A mapping row is ready for YAML implementation only when:

- target entity ID follows `ENTITY_NAMING.md`
- current entity is known
- physical device is identified or explicitly not required
- dependencies are listed
- migration approach is selected
- test criteria are defined
- rollback remains possible

## 14. Related documents

- `HMI_ARCHITECTURE.md`
- `ENTITY_NAMING.md`
- `HARDWARE_INVENTORY.md`

This mapping is intentionally incomplete where available evidence does not prove the physical or entity-level relationship. Those gaps are migration tasks, not assumptions to hide.
