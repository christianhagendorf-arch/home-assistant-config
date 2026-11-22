# HMI Architecture

**Project:** Home Assistant HMI Redesign  
**Document status:** Initial baseline derived from the approved HTML prototype `v1.0.0`  
**Scope:** Family-facing HMI and operator-facing detail views  
**Language:** German HMI, English backend identifiers

## 1. Purpose

This document defines the target architecture and interaction principles for the new Home Assistant dashboard. The existing installation is a source of functional knowledge, not a technical architecture to preserve.

The target is a compact, room-oriented Human-Machine Interface (HMI) that combines status and direct control. Daily functions must be usable without opening a popup wherever practical. Less frequently used settings and diagnostic information belong in room details or a separate technical view.

## 2. Guiding principles

### 2.1 Greenfield implementation

The dashboard and supporting YAML structure will be rebuilt and optimized. Existing entity IDs, packages, automations, and dashboards are not assumed to be suitable for reuse.

Existing code may be used to identify:

- physical devices and their current function
- room assignments
- required automations
- technical dependencies
- established family terminology

### 2.2 HMI first

The HMI represents how the house is understood and operated, not how devices are electrically connected.

Examples:

- Office and bedroom remain separate HMI rooms even though one physical switching logic controls both lighting functions.
- Kitchen worktop and coffee corner remain separate HMI functions even if a physical Sonoff switch can operate both.
- Technical names such as `sonoff_11` are not shown to family users.

### 2.3 Status and control are combined

A control surface is also a status surface. Each visible control communicates its current state.

- active lights use a visible active state
- dimmers show current brightness
- heating shows current room temperature and target temperature together
- covers provide direct Up, Stop, and Down controls
- washing machine and dryer are status objects, not power switches

### 2.4 Progressive disclosure

Frequently used functions remain on the room card. Less frequently used settings move to room details.

**Main-card examples:**

- room temperature and heating target
- primary lights and switches
- dimmers while the corresponding light is on
- cover Up, Stop, and Down controls
- appliance status

**Room-detail examples:**

- HVAC mode selection
- RGB presets
- Lotta's window heating
- separate office pinboard and platform controls
- future cover position sliders

### 2.5 Private-project pragmatism

Documentation and implementation must remain maintainable without imposing unnecessary industrial process. Documents grow alongside the implementation. New abstractions are introduced only when they solve an observed problem.

## 3. Language model

The project separates backend language from HMI language.

| Layer | Language | Example |
|---|---|---|
| Physical device/network name | English, with persistent hardware number | `sonoff-mini-11` |
| Home Assistant entity ID | English | `climate.living_room` |
| HMI room/function label | German, concise | `Wohnzimmer`, `Heizung`, `TV-Board` |

Familiar Anglicisms are allowed when shorter or more natural, for example `TV-Board`, `LED-Decke`, `RGB`, `Dimmer`, and `Auto`.

## 4. Information architecture

### 4.1 Primary views

1. **Übersicht**
2. **EG**
3. **OG**
4. **DG**
5. **Garten**
6. **Technik** in a later phase

### 4.2 Overview behavior

The overview initially shows all rooms and all agreed primary controls. It is not reduced to favorites in the first implementation. Favorites may be introduced after real-world use has shown which controls matter most. Weather is excluded from the initial overview.

### 4.3 Section layout

On desktop, the overview presents four vertical sections next to each other:

- Erdgeschoss
- Obergeschoss
- Dachgeschoss
- Garten

On narrower screens, sections reflow responsively. Room controls use a two-column grid where usable. A single-column fallback is permitted only when controls or German labels become too narrow.

### 4.4 Floor and hall identifiers

Target structural keys are:

```text
ground_floor
first_floor
second_floor
garden
```

The hall is the first room card in its floor section. The HMI label is simply `Flur`; floor context comes from the section.

Backend names remain unambiguous:

```text
first_floor_hall
second_floor_hall
```

Future stairwell lights are assigned to one floor and one room unless practical use later demonstrates a need for a separate cross-floor concept.

## 5. Room-card architecture

### 5.1 General structure

A room card consists of:

1. room title
2. optional inline climate row
3. optional cover control
4. primary functions in a compact two-column grid
5. optional access to room details

### 5.2 Inline climate row

For heated rooms, current room temperature and target setting are displayed on one horizontal line:

```text
Ist 22,7 °C       [Heizung] [−] 21,5 °C [+]
```

Rules:

- temperature step: `0.5 °C`
- radiator icon acts as quick on/off control
- HVAC selection is available in room details
- supported HVAC modes: `off`, `auto`, `heat`
- state colors distinguish off, enabled/idle, and actively heating
- TRV values and diagnostic data are excluded from the family HMI

### 5.3 Lighting controls

Lighting is classified by user capability rather than protocol or hardware.

| Capability | Main-card behavior |
|---|---|
| Switchable | icon and label, direct on/off |
| Dimmable | switch plus brightness slider while on |
| RGB-capable | switch plus brightness slider while on; colors in details |

The brightness slider is hidden while the light is off. RGB presets and color controls are hidden from the main card.

### 5.4 Cover controls

Covers remain visible on the main room card:

- Up
- Stop
- Down

A position slider is a detail function and is excluded from the initial main card.

### 5.5 Status objects

Washing machine and dryer are read-only status objects. Example states:

- Bereit
- Läuft
- Fertig

Underlying smart-plug state, power consumption, notification helpers, and state-machine internals belong in the technical view.

## 6. Target room structure

### 6.1 Erdgeschoss

#### Hauseingang

- Außenbeleuchtung

#### Wohnzimmer

- Heizung
- Bogenlampe
- TV-Board

TV-Board is a primary function. Bogenlamp brightness presets may be introduced later if useful.

#### Küche

- Heizung
- Arbeitsfläche, dimmable
- Kaffee-Ecke, dimmable
- Essecke, switchable decorative light
- Schwibbogen, switchable seasonal/decorative socket function

Worktop and coffee corner remain separate HMI functions. Lighting groups and scenes are deferred until after initial real-world use.

#### Gästebad

- Licht, with backend motion-sensor logic
- Waschmaschine status
- Trockner status

#### Hauswirtschaftsraum

- Licht, with backend motion-sensor logic

The ground-floor hall is not shown because its former controllable light was removed during renovation.

### 6.2 Obergeschoss

#### Flur

- Kommode, dimmable white LED strip

#### Arbeitszimmer

Main card:

- Heizung
- Rollladen, Up/Stop/Down
- Arbeitslicht, grouped main control

Room details:

- Pinnwand, separate switch
- Podest, separate dimmable light

Pinnwand and Podest are technically coupled by a physical switch but may be controlled separately in details.

#### Schlafzimmer

Main card:

- Heizung
- Rollladen, Up/Stop/Down
- Schlafzimmerlicht, dimmable

Room details:

- RGB presets for Schlafzimmerlicht

Office and bedroom remain distinct HMI rooms despite shared physical switching logic caused by the later room division and single ceiling outlet.

#### Gästezimmer

- Heizung
- Tischlampe, dimmable

### 6.3 Dachgeschoss

#### Flur

- Schuhschrank

#### Lotta

Main card:

- Heizung
- LED-Decke, dimmable and RGB-capable
- Tischlampe, dimmable
- Aquarium, switchable light

Room details:

- Fensterheizung with own on/off and target temperature
- RGB presets for LED-Decke

The window heating is a second climate function used mainly in cold weather to reduce condensation. Its target is adjustable but usually changed infrequently. Future automation based on outdoor temperature or condensation indicators is possible.

#### Lene

Main card:

- Heizung
- LED-Decke, dimmable and RGB-capable

Room details:

- RGB presets for LED-Decke

### 6.4 Garten

#### Terrasse

- Terrassenlicht, technically a switched socket used for lighting

#### Kinderhaus

- Dachbeleuchtung
- Stern
- Beleuchtung neben Kinderhaus

The Kinderhaus is treated as a normal room card and receives no special hero treatment.

## 7. Detail views and popups

Room details are used for secondary controls, not as a prerequisite for common actions. A popup may contain:

- HVAC mode selection
- RGB presets
- secondary lights split from a main group
- Lotta's window heating
- future cover-position control

The popup works as a centered dialog on desktop/tablet and a bottom sheet on smartphone. The main card remains usable if the popup is never opened.

## 8. Theme and visual system

### 8.1 Themes

Two Home Assistant themes will be implemented:

- Night Control Dark
- Night Control Light

Theme switching may initially be manual. Automatic switching based on time or solar state may be added later.

### 8.2 Light-theme hierarchy

The light theme maintains visible separation between:

1. dashboard background
2. floor/section container
3. room card
4. individual control

Sections and room cards require visible borders. The interface must not rely on white-on-white surfaces or shadows alone.

### 8.3 Icon system

- Material Design Icons (MDI)
- outline variants preferred
- standard filled MDI accepted when no suitable outline exists
- consistent circular Mushroom-style icon background
- no emoji icons

### 8.4 State colors

| State/function | Color behavior |
|---|---|
| Inactive/off | neutral gray |
| Active light | restrained amber |
| Temperature/value | blue |
| Heating enabled but idle | blue |
| Actively heating | orange |
| Finished appliance | green |
| Error/unavailable | red, reserved for true faults |

Exact colors are refined in Home Assistant themes rather than treated as fixed by the HTML prototype.

## 9. Family HMI and technical view separation

### 9.1 Family HMI

The family HMI contains only operationally relevant controls and statuses:

- light
- heating
- covers
- important sockets
- washing-machine/dryer status
- future scenes where validated by use

### 9.2 Technical/operator view

A later technical view may contain:

- room sensor temperature
- TRV current and target temperature
- Better Thermostat data
- valve positions
- heating-pump status
- unavailable entities
- automation health
- Raspberry Pi system information
- Home Assistant version and uptime
- last restart or crash indicators
- MQTT and Zigbee2MQTT status
- device batteries and maintenance information

Technical data does not clutter the family HMI.

## 10. Backend boundary

A functional Home Assistant entity may abstract one or more physical devices:

```text
Physical device
→ integration/raw entity
→ functional entity or group
→ HMI control
```

Example:

```text
sonoff-mini-11
→ switch.sonoff_11
→ climate.living_room
→ HMI: Wohnzimmer / Heizung
```

Physical numbering remains traceable for maintenance, Fritz!Box identification, replacement, and fault diagnosis. MQTT/firmware identifiers remain numbered and independent of room or purpose. Current installation purpose is maintained in the hardware inventory and functional Home Assistant layer rather than encoded into the device name.

## 11. Implementation strategy

The Lovelace implementation follows a room-by-room pilot:

1. Wohnzimmer
2. Küche
3. Arbeitszimmer
4. remaining rooms by floor
5. technical view

The Wohnzimmer pilot validates Sections layout, Mushroom climate control, inline temperatures, primary switches, themes, and responsive behavior. Kitchen adds multiple lights and conditional dimmers. Office adds covers, grouping, and separated detail controls.

## 12. Out of scope for the initial YAML pilot

- favorites-based landing page
- weather card
- stairwell lighting not yet installed
- automatic theme switching
- new lighting groups and scenes
- automated Lotta window heating
- production-system migration
- full technical/admin view
- pixel-perfect recreation of the HTML prototype

## 13. Decision log

| Decision | Status |
|---|---|
| Greenfield dashboard/YAML design | Approved |
| Existing code used only as functional evidence | Approved |
| Backend identifiers in English | Approved |
| Family HMI in concise German | Approved |
| Structural floor keys: `ground_floor`, `first_floor`, `second_floor`, `garden` | Approved |
| Overview initially shows all rooms/functions | Approved |
| Four floor/garden sections on desktop | Approved |
| Hall first in each floor section | Approved |
| Inline current temperature and target control | Approved |
| Temperature step 0.5 °C | Approved |
| HVAC modes off/auto/heat | Approved |
| Dimmer visible only while light is on | Approved |
| RGB controls in room details | Approved |
| Cover Up/Stop/Down on main card | Approved |
| Cover position slider in details | Deferred |
| Kinderhaus treated as normal room | Approved |
| Technical/operator information separated | Approved |
| Final colors refined in HA themes | Approved |

## 14. Related project documents

- `ENTITY_NAMING.md`
- `HARDWARE_INVENTORY.md`
- `ENTITY_MAPPING.md`

The approved interaction reference is the HTML prototype tagged:

```text
v1.0.0
```
