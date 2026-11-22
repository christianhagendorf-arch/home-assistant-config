# Wohnzimmer-Pilot auf ha-test

## Rollen

- **GAIA/Laptop:** Entwurf und Diffs, GitHub-Review. GitHub-Anmeldung im Browser verleiht GAIA keinen Zugriff. Bei vorhandenem autorisiertem Repository-Connector: Änderungen nur in den Arbeitsbranch, kein direkter Commit nach `main`. Andernfalls einen Git-Patch über einen zulässigen Dateiweg übertragen.
- **Mini-PC:** Arbeitskopie von `home-assistant-config`, GitHub Desktop und VS Code. Beim Öffnen des Ordners die empfohlenen Erweiterungen YAML und Home Assistant Config Helper installieren. Für den Start genügen die lokalen Prüfungen der Editoren; der tatsächliche HA-Check erfolgt auf dem Pi. Keine zusätzliche lokale HA-Instanz erforderlich.
- **ha-test:** Einziges Deployment-Ziel. Zugriffe über den bestehenden SSH-Weg bzw. einen separaten, ausdrücklich autorisierten Schlüssel für den Mini-PC. Keine GitHub-Anmeldedaten auf dem Pi.

## Pilot-Patch einspielen

1. Am Mini-PC in GitHub Desktop `home-assistant-config` klonen oder **Fetch origin**. Arbeitskopie muss sauber sein. `feature/living-room-pilot` wählen, sofern dort noch kein neuer Pilotcommit liegt. Einen Commit nie zweimal importieren.
2. Den neuen Patch über den erlaubten Dateiweg auf den Mini-PC laden. Der frühere `0001-wohnzimmer-pilot-scaffolding.patch` ist ein separater Entwurf und wird hier nicht eingespielt.
3. In Git Bash (Git for Windows) im Repo:

   ```bash
   git status --short
   git apply --stat /pfad/zum/wohnzimmer-pilot-v1.patch
   git apply --check /pfad/zum/wohnzimmer-pilot-v1.patch
   git am /pfad/zum/wohnzimmer-pilot-v1.patch
   git show --stat --oneline HEAD
   ```

   Bei einem Fehler abbrechen, ggf. `git am --abort`. In GitHub Desktop den Commit prüfen und mit **Push origin** den Arbeitsbranch synchronisieren, sofern Änderungen noch nicht auf GitHub sind.

## Übertragen und Teststart

Der folgende Block ist für Windows PowerShell im Repo auf dem Mini-PC. `git`, `ssh` und `scp` müssen dort verfügbar sein. Falls der Pi vom Mini-PC noch nicht per SSH erreicht wird, kann der Nutzer denselben Test vom Laptop mit bestehendem SSH-Zugang ausführen. Kein privater Schlüssel wird zwischen Geräten kopiert. Bei Erstverbindung den SSH-Hostschlüssel gegen den bereits vertrauenswürdigen Zugang prüfen; auf Zertifikats- oder Hostkey-Fehler nicht mit abgeschalteter Prüfung reagieren.

```powershell
$target = 'haadmin@ha-test.local'
# Falls der lokale Name nicht auflösbar ist, den bekannten Testhost per LAN-IP verwenden.
ssh $target hostname
```

Nur mit Ausgabe `ha-test` fortfahren. Nutzt dein SSH-Zugang eine explizite `IdentityFile`, trage sie in der lokalen SSH-Konfiguration für diesen Host ein, damit `ssh` und `scp` denselben Schlüssel wählen.

```powershell
$sha = (git rev-parse --short=12 HEAD).Trim()
$archive = Join-Path $env:TEMP "ha-pilot-$sha.tar"
git archive --format=tar --output="$archive" HEAD config/dashboards/living-room-pilot.yaml config/packages/ground_floor/pilot_living_room.yaml tools/deploy_ha_test.py
if ($LASTEXITCODE -ne 0) { throw 'Git-Archiv konnte nicht erstellt werden.' }
$stage = (ssh $target 'mktemp -d ~/ha-pilot.XXXXXXXX').Trim()
if ($LASTEXITCODE -ne 0 -or $stage -notmatch '^/[a-zA-Z0-9_./-]+/ha-pilot\.[a-zA-Z0-9]+$') { throw 'Staging-Verzeichnis ungültig.' }
scp $archive "${target}:${stage}/pilot.tar"
if ($LASTEXITCODE -ne 0) { throw 'Übertragung fehlgeschlagen.' }
ssh $target "cd '$stage' && tar -xf pilot.tar && python3 tools/deploy_ha_test.py"
```

Standard ist die Vorschau; sie ändert keine HA-Dateien und startet HA nicht neu. Prüfe die angezeigten Pfade und den Konfigurationsdiff. Für den ersten Apply läuft der erfolgreiche Vorschauaufruf direkt noch einmal mit `--apply`:

```powershell
ssh $target "cd '$stage' && python3 tools/deploy_ha_test.py --apply"
```

Der Deploy prüft Hostname und Docker-Mount, sichert nur die betroffenen Dateien außerhalb des HA-Verzeichnisses und führt `check_config` aus. Ein bereits vorhandener, nicht hier verwalteter Lovelace-Block führt zu einem Stopp, damit die Dashboard-Registrierung gezielt ergänzt werden kann. Bei einem Rechtefehler und sofern du den übertragenen Stand geprüft hast, führe über PowerShell `ssh -t $target "cd '$stage' && sudo -H python3 tools/deploy_ha_test.py --apply"` aus. Für Rollback dieselbe Rechteebene verwenden. Keine rekursiven Rechteänderungen. Wenn die YAML-Prüfung scheitert, werden die gesicherten Dateien vor einem Neustart zurückgeholt. Bei reinem Lovelace-Dateiwechsel aktualisiere das Pilot-Dashboard über `⋮` → **Aktualisieren**. Dateien aus der Git-Arbeitskopie außerhalb der oben genannten Liste werden nie kopiert.

## Abnahme auf dem Pi

- Pilot in der Sidebar öffnen: **Wohnzimmer (Sim)**, Pfad `/living-room-pilot/ground_floor`. Bestehende Übersicht bleibt erreichbar. Startlogs seit dem im Deploy ausgegebenen UTC-Zeitpunkt prüfen.
- Heizsymbol: aus → heizen → aus. Ist links, Soll rechts; −/+ je 0,5 °C im Bereich 16–24 °C, ohne Popup. Anzeige des Heizstatus ist simuliert und unterscheidet aus, heizt und wartet. Diese Sollwerte sind Startwerte des Piloten; die Simulation ist kein Test der Sollwert-Wiederherstellung über Neustarts.
- Demolicht: Aus = kein Slider; An = Slider; erneut Aus = kein Leerraum. Helligkeit ändern und nach Aus/An erneut prüfen. Bogenlampe schaltet immer ohne Slider. TV-Board nur manuell ein/aus.
- Auf Desktop und iPhone testen, gerade nebeneinanderliegende Bedienelemente und schmale Displaybreiten. Unbekannte oder fehlende Entitäten beheben; HA-Prüfung und HTTP 200 allein prüfen die Lovelace-Bedienung nicht.
- Neue Sim-Entitäten nach dem Smoke-Test in der HA-Oberfläche mit dem vorhandenen Label `sim-test` markieren; das Deployment bearbeitet `.storage` nicht.

Bei UI-Problemen oder unbeabsichtigten Änderungen: das vom Apply ausgegebene letzte Backup verwenden. Keine sonstigen Konfigurationsänderungen zwischen Deploy und Rollback vornehmen.

```powershell
ssh $target "cd '$stage' && python3 tools/deploy_ha_test.py --rollback '$backup'"
```

`$backup` vorab auf den ausgegebenen absoluten Pfad setzen. Lokale Backups enthalten gegebenenfalls private Konfigurationswerte und bleiben auf `ha-test`.

## Patch-Verlauf

Patch-Dateien werden mit vierstelliger laufender Nummer benannt (`0001-...patch`, `0002-...patch`, ...) für korrekte alphabetische Sortierung im Download-Ordner. Die zugehörigen Befehle stehen hier, nicht in separaten Dateien.

### 0001 – Simulierter Wohnzimmer-Pilot (Basis)

Angewendet am 22.11.2026. Legt `config/packages/ground_floor/pilot_living_room.yaml`, `config/dashboards/living-room-pilot.yaml` (native HA-Tiles), `tools/deploy_ha_test.py`, VS-Code-Empfehlungen und diese Dokumentation an. Befehle siehe Abschnitt "Übertragen und Teststart" oben.

### 0002 – Umstellung auf Mushroom-Cards

Ersetzt die native Tile-Optik durch `mushroom-entity-card`, `mushroom-light-card`, `mushroom-climate-card`. Die Dimmer-Sichtbarkeitsregel läuft jetzt über `collapsible_controls: true` statt über `conditional`-Karten.

Voraussetzung: Mushroom ist auf `ha-test` installiert (**Einstellungen → Marketplace** → "Mushroom" suchen → Installieren → Browser-Tab neu laden; HA ab 2026.11 hat HACS/Marketplace fest integriert, kein Terminal-Schritt nötig).

Mini-PC, VS-Code-Terminal, im Repo-Ordner, nachdem `0002-wohnzimmer-pilot-mushroom-v1.patch` dorthin kopiert wurde:

```powershell
git status --short
git apply --stat 0002-wohnzimmer-pilot-mushroom-v1.patch
git apply --check 0002-wohnzimmer-pilot-mushroom-v1.patch
git am 0002-wohnzimmer-pilot-mushroom-v1.patch
git log --oneline -3
git status --short
```

Push über GitHub Desktop. Danach Deploy auf `ha-test`, identischer Ablauf wie bei Patch 0001 (Dry-Run zuerst, Ausgabe prüfen lassen, dann `--apply`):

```powershell
$target = 'ha-test'
ssh $target hostname
$sha = (git rev-parse --short=12 HEAD).Trim()
$archive = Join-Path $env:TEMP "ha-pilot-$sha.tar"
git archive --format=tar --output="$archive" HEAD config/dashboards/living-room-pilot.yaml config/packages/ground_floor/pilot_living_room.yaml tools/deploy_ha_test.py
if ($LASTEXITCODE -ne 0) { throw 'Git-Archiv konnte nicht erstellt werden.' }
$stage = (ssh $target 'mktemp -d ~/ha-pilot.XXXXXXXX').Trim()
if ($LASTEXITCODE -ne 0 -or $stage -notmatch '^/[a-zA-Z0-9_./-]+/ha-pilot\.[a-zA-Z0-9]+$') { throw 'Staging-Verzeichnis ungültig.' }
scp $archive "${target}:${stage}/pilot.tar"
if ($LASTEXITCODE -ne 0) { throw 'Übertragung fehlgeschlagen.' }
ssh $target "cd '$stage' && tar -xf pilot.tar && python3 tools/deploy_ha_test.py"
```

Nur Dry-Run, keine Änderung. Ausgabe an den Assistenten schicken, erst nach Freigabe:

```powershell
ssh $target "cd '$stage' && python3 tools/deploy_ha_test.py --apply"
```

Abnahme: Sidebar "Wohnzimmer (Sim)" neu laden. Demolicht und Heizung bei Aus eingeklappt, bei An mit Reglern. Optik jetzt runde Mushroom-Cards statt eckiger Tiles.
