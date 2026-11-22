# Hardware Inventory

**Project:** Home Assistant HMI Redesign  
**Document status:** Initial inventory based on the reviewed legacy configuration  
**Purpose:** Preserve physical-device identity, installation location, network naming, and the link to Home Assistant functions  
**Backend language:** English  
**HMI language:** German

## 1. Purpose

This inventory records which physical smart-home device is installed at which location and which function it performs. It preserves identifiers such as `sonoff_11` that are essential for maintenance, troubleshooting, Fritz!Box identification, replacement, and work inside switch or socket boxes.

This document does **not** replace `ENTITY_MAPPING.md`:

- `HARDWARE_INVENTORY.md` answers: **Which physical device is installed where?**
- `ENTITY_MAPPING.md` answers: **How does an existing/raw entity map to the new functional entity and HMI control?**

## 2. Inventory principles

### 2.1 Never lose the physical identifier

Existing device numbers remain permanent installation references where practical.

Example:

```text
sonoff_11
→ sonoff-mini-11
→ installed heating actuator in the living room
```

A replacement installed in the same documented position may inherit the installation identifier, but the replacement event must be recorded in the history field.

### 2.2 Stable field-device naming

MQTT, firmware, and canonical device IDs remain numbered and independent of installation purpose. A descriptive Fritz!Box display name may include room/purpose as an operator convenience, but is not the canonical identity.

### 2.3 Separate physical and functional naming

Example layers:

```text
Physical/network device:
sonoff-mini-11

Raw Home Assistant entity:
switch.sonoff_11

Functional entity:
climate.living_room

HMI:
Wohnzimmer / Heizung
```

### 2.4 Record uncertainty explicitly

The legacy configuration does not always prove the exact device model, mounting position, circuit, or network hostname. Unknown values are marked `TBD` and confirmed room by room during migration.

Do not infer a device model from an entity ID alone.

## 3. Required fields

Each physical device should eventually include:

| Field | Description |
|---|---|
| Inventory ID | Permanent human-readable installation identifier |
| Vendor/model | Exact product, if known |
| Protocol | Wi-Fi, Zigbee, Ethernet, GPIO, etc. |
| Floor/room | Physical location using canonical English room keys |
| Installation position | Switch box, outlet, cabinet, radiator, ceiling, etc. |
| Physical function | What the device electrically controls or measures |
| Stable device/MQTT ID | Numbered, location-independent device identity |
| Optional router display name | Descriptive Fritz!Box label; not canonical |
| Current raw entity | Existing Home Assistant entity ID |
| Target raw entity | Planned integration/raw entity ID |
| Functional entity | Planned stable functional entity/group |
| HMI label | German family-facing label |
| Status | `identified`, `partially_identified`, `to_verify`, `retired` |
| Notes/history | Dependencies, unusual wiring, replacement history |

## 4. Inventory ID convention

Use:

```text
HW-<FAMILY>-<NUMBER>
```

Examples:

```text
HW-SONOFF-MINI-11
HW-GOSUND-PLUG-06
HW-LED-RGBW-02
```

For devices without an established number, assign a new inventory number only after physical verification.

## 5. Known numbered switching devices

### 5.1 Sonoff devices

| Inventory ID | Stable device/MQTT ID | Optional router display name | Floor / room | Physical function | Current/raw entity | Functional entity | HMI label | Status / notes |
|---|---|---|---|---|---|---|---|---|---|
| `HW-SONOFF-MINI-04` | `sonoff-mini-04` | `sonoff-mini-04-light-office-pinboard` or current Fritz!Box label | `first_floor / office` | Pinboard lighting; part of office work-light arrangement | `switch.sonoff_4` | `light.office_pinboard`; member of `light.office_work_lights` | Pinnwand | Partially identified. Exact switch-box position and model to verify. |
| `HW-SONOFF-MINI-09` | `sonoff-mini-09` | Current descriptive Fritz!Box label TBD | `first_floor / bedroom` | Physical switching input involved in cyclic office/bedroom lighting logic | `switch.sonoff_9` | `light.bedroom_ceiling` through functional logic | Schlafzimmerlicht | Partially identified. Shared switching logic; do not migrate blindly. |
| `HW-SONOFF-MINI-11` | `sonoff-mini-11` | `sonoff-mini-11-heating-wozi` or current Fritz!Box label | `ground_floor / living_room` | Living-room heating actuator | `switch.sonoff_11` | `climate.living_room` | Heizung | Identified from legacy heating package. Device ID remains purpose-independent. Exact installation position to document. |
| `HW-SONOFF-MINI-12` | `sonoff-mini-12` | Current descriptive Fritz!Box label TBD | `ground_floor / kitchen` | Kitchen heating actuator | `switch.sonoff_12` | `climate.kitchen` | Heizung | Identified from legacy heating package. Device ID remains purpose-independent. |
| `HW-SONOFF-MINI-14` | `sonoff-mini-14` | Current descriptive Fritz!Box label TBD | `ground_floor / utility_room` | Utility-room light | `switch.sonoff_14` | Prefer functional light abstraction: `light.utility_room_ceiling` | Licht | Identified. Used with motion automation. Exact model/box to verify. |
| `HW-SONOFF-MINI-15` | `sonoff-mini-15` | Current descriptive Fritz!Box label TBD | `ground_floor / guest_bathroom` | Guest-bathroom light | `switch.sonoff_15` | Prefer functional light abstraction: `light.guest_bathroom_ceiling` | Licht | Identified. Used with motion automation. Exact model/box to verify. |
| `HW-SONOFF-ZBMINIR2-DG1` | Existing numbered Zigbee device ID to confirm | Current descriptive Zigbee/Fritz!Box label TBD | `second_floor / lotta_room` | Physical switch for Lotta ceiling lighting | Existing entity to confirm | `light.lotta_room_ceiling` | LED-Decke | Partially identified. Exact device/entity and installation box to verify. |

### 5.2 Gosund smart plugs

| Inventory ID | Stable device/MQTT ID | Optional router display name | Floor / room | Physical function | Current/raw entity | Functional entity | HMI label | Status / notes |
|---|---|---|---|---|---|---|---|---|---|
| `HW-GOSUND-PLUG-06` | `gosund-plug-06` | Current descriptive Fritz!Box label TBD | `ground_floor / living_room` | TV-board power supply | `switch.gosund_6` | `switch.living_room_tv_board` | TV-Board | Identified. Existing automatic shutdown uses power measurement. |
| TBD | Washing-machine plug | TBD | `ground_floor / guest_bathroom` | Washing-machine power measurement and operating-state detection | Existing entity to extract from appliance package | TBD | `sensor.washing_machine_state` plus technical power sensor | Waschmaschine | Device family appears to be Gosund from legacy logic; number/model and outlet position to verify. |
| TBD | Dryer plug | TBD | `ground_floor / guest_bathroom` | Dryer power measurement and operating-state detection | Existing entity to extract from appliance package | TBD | `sensor.dryer_state` plus technical power sensor | Trockner | Device family appears to be Gosund from legacy logic; number/model and outlet position to verify. |

## 6. Heating-system hardware

| Inventory ID | Existing identifier | Proposed name | Floor / room | Function | Current entity | Target entity | HMI / technical use | Status / notes |
|---|---|---|---|---|---|---|---|---|
| TBD | Heating pump device | TBD | `ground_floor / utility_room` or heating-system location | Circulation/heating pump switched from aggregated heat demand | `switch.lsc_1_heizung_pumpe` | TBD after device verification | Technical view only | Existing logic derives demand from `switch.sonoff_11` and `switch.sonoff_12`. Exact device/model/location to verify. |
| TBD | Living-room room-temperature sensor | TBD | `ground_floor / living_room` | Control temperature for functional climate entity | Existing sensor to map | `sensor.living_room_temperature` | Family HMI current temperature | Verify physical sensor and placement. |
| TBD | Kitchen room-temperature sensor | TBD | `ground_floor / kitchen` | Control temperature for functional climate entity | Existing sensor to map | `sensor.kitchen_temperature` | Family HMI current temperature | Verify physical sensor and placement. |
| TBD | Lotta window-heating actuator | TBD | `second_floor / lotta_room` | Window heating for condensation protection | Existing switch/entity to extract | TBD | `climate.lotta_room_window` | The window heating is a separate climate function. Exact actuator and mounting position to verify. |
| TBD | Lotta window temperature sensor | TBD | `second_floor / lotta_room` | Temperature input for window-heating control | Existing sensor to extract | `sensor.lotta_room_window_temperature` | Detail/technical view | Verify sensor location and whether value represents window area or room air. |

### Better Thermostat and TRVs

The initial inventory does not yet assign TRV hardware because exact device identities, room allocations, and current entity IDs still require extraction and physical confirmation.

For each heated room, record separately:

- physical TRV device
- TRV network/Zigbee name
- raw TRV climate entity
- room-temperature sensor
- Better Thermostat functional entity
- valve-position sensor, if available
- battery entity

The family HMI uses the functional room climate entity. TRV details belong in the technical view.

## 7. Lighting hardware and controllers

### 7.1 Known controller families

| Inventory ID | Existing identifier | Proposed name | Room | Function | Current entity | Target functional entity | Status / notes |
|---|---|---|---|---|---|---|---|
| `HW-LED-WW-01` | `led_ww_1` | `led-ww-01-light-office-platform` | `office` | Dimmable white platform light | `light.led_ww_1` | `light.office_platform` | Identified function; physical controller/model/location to verify. |
| `HW-LED-WW-02` | `led_ww_2` | `led-ww-02-light-first-floor-hall-sideboard` | `first_floor_hall` | Dimmable white LED strip at sideboard | `light.led_ww_2` | `light.first_floor_hall_sideboard` | Identified function; physical controller/model/location to verify. |
| `HW-LED-RGBW-02` | `led_rgbw_2` | `led-rgbw-02-light-lotta-room-ceiling` | `lotta_room` | Dimmable RGB-capable ceiling light | `light.led_rgbw_2` | `light.lotta_room_ceiling` | Identified function; RGB is secondary HMI function. |
| `HW-LED-RGBW-03` | `led_rgbw_3` | `led-rgbw-03-light-lene-room-ceiling` | `lene_room` | Dimmable RGB-capable ceiling light | `light.led_rgbw_3` | `light.lene_room_ceiling` | Identified function; exact physical switch input is Sonoff 9 per legacy configuration and must be verified. |
| `HW-LED-RGBW-04` | `led_rgbw_4` | `led-rgbw-04-light-bedroom-ceiling` | `bedroom` | Dimmable RGB-capable bedroom light | `light.led_rgbw_4` | `light.bedroom_ceiling` | Function inferred from reviewed office/bedroom switching logic; verify controller and wiring. |
| `HW-BULB-01` | `bulb_1` | TBD after exact product identification | `lotta_room` | Dimmable table lamp | `light.bulb_1` | `light.lotta_room_table_lamp` | Identified function. Vendor/model and physical fixture to record. |
| `HW-BULB-02` | `bulb_2` | TBD after exact product identification | `guest_room` | Dimmable table lamp | `light.bulb_2` | `light.guest_room_table_lamp` | Identified function. Vendor/model and physical fixture to record. |

### 7.2 Other lighting functions requiring physical identification

| Room | HMI function | Proposed functional entity | Hardware information still required |
|---|---|---|---|
| `entrance` | Außenbeleuchtung | `light.entrance_outside` | switch/controller, device number, box/location, current entity |
| `living_room` | Bogenlampe | `light.living_room_arc_lamp` | Shelly exact model/ID, switching/dimming behavior, installation position |
| `kitchen` | Arbeitsfläche | `light.kitchen_worktop` | controller(s), physical coupling, current member entities |
| `kitchen` | Kaffee-Ecke | `light.kitchen_coffee_corner` | dimmer/controller and coupling to worktop switch |
| `kitchen` | Essecke | `light.kitchen_dining_corner` | smart lamp/socket identity and window position |
| `kitchen` | Schwibbogen | HMI label mapped to stable backend candidate `switch.kitchen_window_decoration` | socket/device number, seasonal use, exact outlet |
| `lotta_room` | Aquarium | `light.lotta_room_aquarium` | switch/device identity, outlet, any schedule |
| `second_floor_hall` | Schuhschrank | `light.second_floor_hall_shoe_cabinet` | controller, entity, physical installation |
| `terrace` | Terrassenlicht | `switch.terrace_lighting_socket` | socket/device identity and outdoor protection/location |
| `playhouse` | Dachbeleuchtung | `light.playhouse_roof` | controller/device identity and physical installation |
| `playhouse` | Stern | `light.playhouse_star` | controller/device identity and physical installation |
| `playhouse` | Beleuchtung neben Kinderhaus | `light.playhouse_outside` | controller/device identity and physical installation |


## 8. Motion and occupancy sensors

| Inventory ID | Existing identifier | Proposed name | Room | Function | Current entity | Target entity | Status / notes |
|---|---|---|---|---|---|---|---|
| TBD | Guest-bathroom motion sensor | TBD | `guest_bathroom` | Occupancy/motion input for automatic light | `binary_sensor.motion_gaestebad_occupancy` | `binary_sensor.guest_bathroom_occupancy` | Function identified. Vendor/model, Zigbee name, mounting position, and battery entity to verify. |
| TBD | Utility-room motion sensor | TBD | `utility_room` | Occupancy/motion input for automatic light | `binary_sensor.motion_hwr_occupancy` | `binary_sensor.utility_room_occupancy` | Function identified. Vendor/model, Zigbee name, mounting position, and battery entity to verify. |

## 9. Cover hardware

| Inventory ID | Existing identifier | Proposed name | Room | Function | Current entity | Target entity | Status / notes |
|---|---|---|---|---|---|---|---|
| TBD | Office shutter controller | TBD | `office` | Office roller shutter | `cover.rollladen_arbeitszimmer` | `cover.office_shutter` | Function identified. Controller model, channels, wiring, installation box, and calibration to verify. |
| TBD | Bedroom shutter controller | TBD | `bedroom` | Bedroom roller shutter | Existing entity to confirm | `cover.bedroom_shutter` | Target function confirmed; raw entity and hardware details to verify. |

## 10. Special physical logic

### 10.1 Office and bedroom lighting cycle

The office and bedroom were created by dividing an existing room with one ceiling outlet. The physical switching sequence cycles through logical lighting states:

```text
off → on:
office

off → on → off → on:
bedroom

off → on → off → on → off → on:
both
```

The implementation must be documented as a subsystem rather than treated as independent wiring.

Required inventory work:

- identify the physical Sonoff model and installation box
- identify all controlled light controllers
- document the exact state machine
- identify restart/power-loss behavior
- define a safe manual fallback
- preserve separate HMI functions for office and bedroom

### 10.2 Kitchen coupled switching

A physical Sonoff Mini switches both worktop and coffee-corner lighting. The HMI represents both functions separately because the coffee corner is independently dimmable.

Required inventory work:

- identify the physical Sonoff number/model
- identify both controlled lamp/controller entities
- document which operations are physically coupled
- document which operations remain independently controllable

### 10.3 Heating pump demand logic

The heating pump is controlled from aggregated demand, currently derived from living-room and kitchen heating actuators.

Required inventory work:

- identify pump device/model/location
- document all demand contributors
- define behavior when an actuator is unavailable
- define minimum run-on/off delays if applicable
- expose pump control only in the technical view

## 11. Device verification procedure

For each `TBD` device, use this process:

1. Select one room and one function.
2. Operate the entity in Home Assistant and observe the physical result.
3. Inspect the device registry, integration, MQTT/Zigbee2MQTT entry, or firmware page.
4. Match the device to the Fritz!Box hostname or Zigbee device name.
5. Record the physical installation position precisely.
6. Photograph the device or installation label when accessible and safe.
7. Record vendor, exact model, serial/MAC/IEEE address only in a private local inventory if desired.
8. Update this inventory and `ENTITY_MAPPING.md`.
9. Do not rename or remove the legacy entity until the mapping is tested.

Do not open mains-voltage installations unless qualified and the circuit is safely isolated.

## 12. Suggested detailed inventory template

Copy this block for each newly verified device when the summary tables are insufficient:

```markdown
### HW-EXAMPLE-01

- **Vendor/model:**
- **Protocol:**
- **Floor/room:**
- **Installation position:**
- **Electrical load/function:**
- **Stable device/MQTT ID:**
- **Optional router display name:**
- **MAC/IEEE/serial:** Stored privately / not recorded
- **Current raw entity:**
- **Target raw entity:**
- **Functional entity:**
- **HMI label:**
- **Firmware:**
- **Installed:**
- **Last verified:**
- **Status:**
- **Dependencies:**
- **Replacement/history:**
- **Notes:**
```

## 13. Migration status vocabulary

Use:

```text
to_verify
identified
mapped
renamed
tested
switched_over
retired
```

Meaning:

| Status | Meaning |
|---|---|
| `to_verify` | Function or device is known incompletely |
| `identified` | Physical device and location are confirmed |
| `mapped` | Existing and target entities are documented |
| `renamed` | Target naming is applied on the test system |
| `tested` | Functional operation is verified |
| `switched_over` | New entity is used by HMI/automation |
| `retired` | Legacy entity/configuration is removed or disabled |

## 14. Immediate verification backlog

Before or during the first YAML pilots, verify in this order:

1. `HW-SONOFF-MINI-11` living-room heating
2. living-room room-temperature sensor
3. living-room Bogenlampe controller and presets
4. `HW-GOSUND-PLUG-06` TV-Board
5. `HW-SONOFF-MINI-12` kitchen heating
6. kitchen worktop and coffee-corner physical coupling
7. washing-machine and dryer plug numbers/entities
8. office shutter controller
9. office/bedroom cyclic lighting subsystem
10. Lotta window-heating actuator and temperature sensor

This order follows the planned YAML pilots: Wohnzimmer, Küche, then Arbeitszimmer.

## 15. Related documents

- `HMI_ARCHITECTURE.md`
- `ENTITY_NAMING.md`
- `ENTITY_MAPPING.md`

The inventory is expected to grow iteratively as each room is migrated and physically verified.
