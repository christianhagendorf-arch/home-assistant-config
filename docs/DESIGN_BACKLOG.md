# Design and behavior backlog

Short working list for accepted design debt and later validation.

## Global design

- Revisit the visual weight of the floor container versus the individual room-card borders. The two-level framing is useful on mobile but may be softened after OG, DG, and Garden provide more examples.
- Re-evaluate the climate footer after Better Thermostat, floor-heating, roller-shutter, RGB-light, and second-heating-zone patterns are available.
- Revisit visual harmonization of light dimmer `-/+` controls and Mushroom Climate temperature controls. Keep the functional Mushroom Climate Card unless styling materially fails mobile acceptance criteria.
- Keep smartphone as the primary acceptance layout. Desktop must remain usable but must not force a worse mobile layout.

## Lighting

- Align active colors of dimmable Template Cards and regular Mushroom Light Cards through `state-light-active-color`; remove hard-coded `amber` values.
- Keep sliders in More Info or detail views. Main views use compact step controls for now.

## Themes

- Diagnose the Light/Dark switch: helper state, script execution, exact theme names, `frontend.set_theme`, and possible user-profile theme override.
- Decide later whether theme selection should be global, per user, or per browser/device.

## Washer and dryer

- Validate the real automation when a new program is started immediately after `Fertig`.
- Check whether timing or state-machine improvements remove the need for a manual reset action.
- Add a manual reset control only if the automation cannot reliably resolve the state itself.

## Details and popups

- Compare More-Info Popup Card, Browser Mod, and Bubble Card when detail views are implemented.
- Candidate detail functions: dimmer slider, RGB presets, HVAC modes, cover position, Lotta window heating, office pinboard/platform.
