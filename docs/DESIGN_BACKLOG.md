# Design and behavior backlog

Short working list for accepted design debt and later validation.

## Global design

- Revisit the visual weight of the floor container versus the individual room-card borders. The two-level framing is useful on mobile but may be softened after OG, DG, and Garden provide more examples.
- Re-evaluate the climate footer after Better Thermostat, floor-heating, roller-shutter, RGB-light, and second-heating-zone patterns are available.
- Revisit visual harmonization of light dimmer `-/+` controls and Mushroom Climate temperature controls. Keep the functional Mushroom Climate Card unless styling materially fails mobile acceptance criteria.
- Keep smartphone as the primary acceptance layout. Desktop must remain usable but must not force a worse mobile layout.

## Lighting

- Verify active light colors after Patch 0020; dimmable Template Cards now use `state-light-active-color` instead of hard-coded `amber`.
- Keep sliders in More Info or detail views. Main views use compact step controls for now.

## Themes

- Verify the Light/Dark switch with the user profile set to `Backend-selected`. `frontend.set_theme` cannot override a theme manually fixed in a user profile.
- Decide later whether theme selection should be global, per user, or per browser/device.

## Washer and dryer

- Validate the real automation when a new program is started immediately after `Fertig`.
- Check whether timing or state-machine improvements remove the need for a manual reset action.
- Add a manual reset control only if the automation cannot reliably resolve the state itself.

## Details and popups

- Compare More-Info Popup Card, Browser Mod, and Bubble Card when detail views are implemented.
- Candidate detail functions: dimmer slider, RGB presets, HVAC modes, cover position, Lotta window heating, office pinboard/platform.

## First-floor implementation review

- Validate the new OG room pattern on the primary smartphone HMI before popup/detail work.
- Recheck the unified 9 px icon radius across all card types.
- Reassess floor-container versus room-card border weight with EG and OG available.
- Confirm real roller-shutter capabilities and state handling before entity migration.


## Patch 0022 validation

- Verify OG hall climate footer and heating-state display.
- Verify `hvac_action` states `off`, `idle`, and `heating` consistently across EG and OG.
- Verify global dimmer behavior: off plus starts at 10 percent; icon toggle restores last brightness; 10 percent minus switches off.
- Theme-switch diagnosis remains intentionally deferred. Existing Backend-selected and global/per-user/per-browser work items remain open.


## Second-floor implementation review

- Validate DG smartphone layout for hall, Lotta, Lene, and bathroom.
- Keep RGB color selection in More Info; main cards expose toggle and 10-percent brightness steps.
- Validate Lotta window heating as a separate function before defining real control logic.
- Confirm the temperature-only DG hall row remains understandable without climate control.
- Confirm the DG bathroom remains clear with climate only and no other functions.


## Patch 0024 validation

- Verify corrected DG hall light entity.
- Validate Lotta window heating as a separate climate footer with window icon, temperature, target, and `hvac_action`.
- Validate Garden and Playhouse on the primary smartphone HMI.
- Confirm centralized package lists keep export and deployment archives synchronized.


## Patch 0025 full-house UI consolidation

- Visible theme-switch chips were removed from EG, OG, DG, and Garden because the current control is not reliable and suggests a working action.
- Keep `Night Control Light` and `Night Control Dark` available through the Home Assistant user profile.
- Before restoring a visible switch, decide global versus per-user versus per-browser/device behavior and verify `frontend.set_theme` with profile overrides.
- Recheck the two-level visual framing (floor container plus room borders) during final full-house acceptance; retain it unless mobile orientation suffers.
- Function labels are room-local and concise: use `Licht` inside personal rooms and `Dachbeleuchtung` in Kinderhaus.


## Merge classification after Patch 0025

### Accepted after merge

- visible Theme switch remains removed
- light/climate control styling may be refined later
- floor/room border weight may be refined after real entity experience
- popup/detail and RGB-preset work remains later

### Before real migration

- document room-by-room heating architecture
- document Better Thermostat candidates
- document living-room/kitchen floor-heating actuators and circulation-pump rules
- validate washer/dryer fast-restart automation before adding a reset control
- inventory MQTT topics and control ownership
