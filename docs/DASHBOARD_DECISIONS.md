# Dashboard: Entscheidungen und Freigaben

Basis: `HMI_ARCHITECTURE.md`, `DEVELOPER_HANDOFF.md` und `ENTITY_MAPPING.md`.
Die Implementierung bleibt im Konfigurationsrepo; `ha-hmi-mockup` bleibt die Designreferenz.

| Datum | Status | Entscheidung und Prüfkriterium |
| --- | --- | --- |
| 22.11.2026 | Bestätigt | Dimmer nur bei dimmbaren, aktuell eingeschalteten Leuchten. Aus, nicht verfügbar und reine Schaltleuchte: kein Slider und kein Platzhalter. An/Aus bleibt erreichbar, wenn das Licht verfügbar ist. |
| 22.11.2026 | Bestätigt | Raumorientiertes Layout, helle gerahmte Karten, dezente Akzente. Bestehende Dashboards bleiben. Prüfung im Desktop-Browser und auf dem iPhone. |
| 22.11.2026 | Bestätigt | Ist links, Soll/Heizung rechts. Heizsymbol schaltet An/Aus. Sollwert direkt per −/+ in 0,5-°C-Schritten. Keine Navigation und kein Popup für diese Kurzbedienung. |
| 22.11.2026 | Pilot-Vorschlag | Der erste technische Test verwendet native HA-Karten und keine neue Frontend-Abhängigkeit. Das finale Mushroom-Layout wird danach vorgelegt. Das separat benannte Demolicht demonstriert den Slider; die Bogenlampe hat im Pilot nur An/Aus. TV-Board zunächst nur als Simulationsschalter. |
| 22.11.2026 | Offen | Erneuter HTML-/JS-Abgleich beim Zugriff auf den eingefrorenen Mockup-Stand. `auto`, Bogenlampen-Presets, TV-Board-Auto-Off, Rollläden, RGB-Details, Theme-Umschalter und weitere Räume kommen in späteren Schritten. `auto` in der Simulation ist kein Nachweis für die spätere Hardware. |
| 22.11.2026 | Bestätigt | Finale Pilot-Optik nutzt Mushroom-Cards (`mushroom-entity-card`, `mushroom-light-card`, `mushroom-climate-card`) statt nativer HA-Tiles. Dimmer-Sichtbarkeits-Regel wird über `collapsible_controls: true` der jeweiligen Mushroom-Karte abgebildet, nicht mehr über separate `conditional`-Karten. Voraussetzung: Mushroom ist auf `ha-test` über den integrierten Marketplace (HA ab 2026.11) installiert. |

Bei jeder Freigabe: zu prüfender Commit, Entscheidungen und Abweichungen, tatsächlich getestete Endgeräte und offene Punkte. Freigabe für `ha-test` und Freigabe für Produktion getrennt dokumentieren. Keine Zugangsdaten oder privaten Geräteexporte ins Repo aufnehmen.
