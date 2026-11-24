# Dashboard: Entscheidungen und Freigaben

Basis: `HMI_ARCHITECTURE.md`, `DEVELOPER_HANDOFF.md`, `ENTITY_MAPPING.md` und der Mockup-Stand `ha-hmi-mockup` / `v1.0.0`. Die Umsetzung bleibt im Konfigurationsrepo.

## Gestaltung und Funktionen

| Thema | Vereinbarung und Stand |
| --- | --- |
| Oberfläche | Raumorientiertes, helles, kompaktes Layout mit Rahmen und dezenten Akzenten. Deutsche UI-Beschriftungen. Vorhandene Dashboards bleiben bestehen. |
| Heizung | Ist links; Heizsymbol und Sollwert mit −/+ rechts in derselben Zeile. Direkter Wechsel Heizen/Aus und Sollwert in 0,5-°C-Schritten, ohne Dialog. Die Simulation unterstützt `off` und `heat` bei 16–24 °C. Dauerhafte Sollwert-Wiederherstellung und produktive Regelfunktion sind nicht Gegenstand des Piloten. |
| Dimmer | Bei dimmbaren Leuchten erscheinen die Regler nur im Zustand An. Im Pilot nutzt das Demolicht `collapsible_controls`; die Bogenlampe ist ein reiner An/Aus-Schalter. Für den Zustand „nicht verfügbar“ ist kein separater Test dokumentiert. |
| Umsetzung | `custom:vertical-stack-in-card` mit `horizontal: true` gruppiert die beiden Mushroom-Karten. `card_mod` entfernt ihre Innenrahmen. Die Klimakarte nutzt `layout: horizontal`, keine Namens-/Statuszeile und eine explizite Aktion zum Umschalten über das Simulationsskript. Die Sollwerttasten bleiben in der Zeile; das Heizungslayout ist vom Lichtdimmer unabhängig. |
| Identitäten | Englische, raumbezogene Entity-IDs und `_sim` für simulierte Entitäten. Etagenpräfixe entfallen in Dateinamen, wenn der Ordner die Etage abbildet. Bestehende Geräte- und Produktions-Entity-IDs bleiben unverändert. |

## Abnahme Patch 0003 auf ha-test

Stand: 22.11.2026, `feature/living-room-pilot` / `1bdfb87`. Im Dry-Run wurde ausschließlich `dashboards/living-room-pilot.yaml` angekündigt. Apply mit erreichtem `check_config` und ohne Fehler abgeschlossen, kein Container-Neustart. Das Backup verbleibt auf `ha-test`; sein konkreter Pfad steht im Übergabedokument.

| Prüfschritt | Rückmeldung am 22.11.2026 |
| --- | --- |
| Ist-Temperatur und Heizung nebeneinander in einer durchgehenden Zeile ohne Zwischenrahmen | Ja |
| Heizsymbol schaltet Heizen/Aus | Ja |
| −/+ ändert Sollwert in 0,5-°C-Schritten | Ja |
| Dimmer, Bogenlampe und TV-Board unverändert bedienbar | Ja |

Die vier Punkte sind für den Wohnzimmer-Pilot auf `ha-test` bestätigt. Ein separater Endgeräte-Nachweis für iPhone und Desktop nach Patch 0003 ist nicht protokolliert. Eine Abnahme des gesamten Mockup-Layouts, eine Serienfreigabe für weitere Räume oder eine Produktionsfreigabe sind daraus nicht abzuleiten.

## Offene Arbeit

- Auf Desktop und iPhone den Stand nach Patch 0003 prüfen (enge Breiten, keine abgeschnittenen Bedienelemente). Installierte Versionen von Mushroom, Card Mod und Vertical Stack In Card protokollieren. `sim-test`-Label der neuen Wohnzimmer-Entitäten in der UI prüfen bzw. ergänzen.
- Je nach Review das Wohnzimmer-Layout verfeinern; dann Küche, anschließend Arbeitszimmer. Den HTML-/JS-Abgleich gegen den eingefrorenen Mockup-Stand ergänzen, sofern er zugänglich ist.
- `auto`, Bogenlampen-Presets, TV-Board-Auto-Off, Rollläden, RGB-Details und Theme-Umschaltung gesondert priorisieren und erst mit passenden Prüfkriterien umsetzen. Keine Verbindung zu produktiven Aktoren in diesen Pilot aufnehmen.

Pro Freigabe Commit, geprüfte Geräte, tatsächliche Ergebnisse und offene Punkte festhalten. `ha-test` und Produktion getrennt freigeben.
