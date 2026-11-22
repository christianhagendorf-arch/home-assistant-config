# Home Assistant: Test-Deploy und Übergabe

Stand: 22.11.2026. Entwicklungsbasis des abgenommenen Wohnzimmer-Piloten: `feature/living-room-pilot`, Commit `1bdfb87` (Patch 0003). Dieses Runbook gilt ausschließlich für `ha-test`. Adressen, Arbeitsplatzpfade und der konkrete Backup-Nachweis gehören in das separat und autorisiert weitergegebene Übergabedokument.

## Arbeitsumgebung und Zuständigkeiten

- **A: Test-Pi (`ha-test`).** Raspberry Pi mit Debian 13 und Home Assistant Container, betrieben über Docker Compose. Portainer steht zur Einsicht bereit. Der Pi benötigt weder einen Git-Checkout noch GitHub-Zugangsdaten. Dashboard-Pilot: „Wohnzimmer (Sim)“, `/living-room-pilot/ground_floor`.
- **B: Laptop.** Chat/Entwurf, Downloads und GitHub-Review im Browser, bei Bedarf SSH zur Diagnose. Der Chat ist weder auf dem Pi angemeldet noch mit dem lokalen Checkout verbunden. Der GAIA-GitHub-Connector wird nicht genutzt.
- **C: Windows-Mini-PC.** Lokaler Git-Checkout, GitHub Desktop, VS Code, PowerShell/OpenSSH. Code und Dokumentation hier bearbeiten und committen, vom Arbeitsbranch pushen und per SSH/SCP bereitstellen. YAML- und Home Assistant Config Helper sind im Repo empfohlen. Für die Entwicklung ist keine zusätzliche lokale HA-Instanz nötig.

Bei Chat-Patches führt der Weg B → freigegebener kDrive-Transfer → C → SSH-Staging auf A. Der Transferordner enthält Patch und Anleitung, keinen Git-Checkout. Bei direkter Entwicklung auf C kann nach Commit und Review sofort aus Git bereitgestellt werden. Weder direkte Live-Dateiänderungen per Remote-Editor/SFTP noch ein ungeprüfter `git pull` auf dem Pi sind Teil des Workflows.

## Einstieg und Vorbereitung

1. Repo-Zugriff über den Eigentümer einrichten. Repo soll privat sein; Sichtbarkeit im GitHub-Kopf prüfen. Keine Schlüssel, Tokens, `secrets.yaml`, `.storage`, Datenbanken oder Backups einchecken. Private Schlüssel bleiben auf den jeweiligen Geräten. Für die übernehmende Person einen eigenen öffentlichen Schlüssel autorisieren; SSH-Hostfingerabdruck über einen bereits vertrauenswürdigen Kanal prüfen.
2. Arbeitsbranch in GitHub Desktop wählen und `Fetch origin` ausführen. In VS Code `git status --short --branch` und `git log -3 --oneline` prüfen. Offene Änderungen an versionierten Dateien vor einem Patch separat sichern oder committen. Einen Patch nie zweimal anwenden. Kein direktes Arbeiten auf `main`.
3. Auf A ist der Compose-Projektordner `/opt/ha-test/homeassistant`; Host-Config `config/` wird als `/config` eingebunden. Gewöhnlicher Zugriff ist über den lokal eingerichteten SSH-Alias `ha-test`; `ssh ha-test hostname` muss `ha-test` zurückgeben. Host-Netzwerk, Registry und Produktionsverbindungen bleiben unverändert.
4. Auf A in **Einstellungen → Marketplace** vorhandene Frontend-Ressourcen prüfen: Mushroom (`piitaya/lovelace-mushroom`), Card Mod (`thomasloven/lovelace-card-mod`), Vertical Stack In Card (`ofekashery/vertical-stack-in-card`). Für 0003 ist weder `custom-cards/stack-in-card` noch der gleichnamige Fork erforderlich. Versionen bei der Übergabe erfassen; bei Kartenfehlern Registrierung und Browser-Reload prüfen.

## Git-Patch einspielen

Vierstellige passende Präfixe: `NNNN-<thema>.patch` plus `NNNN-HA_TEST_DEPLOY-snippet.md`. Das Snippet ist schon vor dem Import verfügbar und enthält die konkreten Kopiervorlagen. Dieses Runbook bleibt unnummeriert und führt die Historie kumulativ. Downloadkopien der Repo-Markdown-Dateien nie vor `git am` über die versionierten Dateien kopieren.

Auf C in PowerShell den Patchpfad aus dem Transferordner angeben. Erst bei erfolgreichem Check anwenden; `git am` erzeugt den Commit selbst.

```powershell
$patch = (Read-Host 'Vollständiger Pfad zur Patch-Datei').Trim('"')
if (-not (Test-Path -LiteralPath $patch -PathType Leaf)) { throw 'Patch fehlt.' }
git status --short --branch
git apply --check -- $patch
if ($LASTEXITCODE -ne 0) { throw 'Patch-Prüfung fehlgeschlagen; nichts importiert.' }
git am -- $patch
if ($LASTEXITCODE -ne 0) { throw 'Import fehlgeschlagen; Git-Status prüfen.' }
git log -3 --oneline
```

Bei einem bereits gescheiterten, noch laufenden Import zeigt `git status` den `am`-Vorgang an. Eigene Änderungen sichern und erst dann ggf. `git am --abort` verwenden. Bei `does not match index` zuerst `git diff` und `git diff --cached` ansehen. Bei 0002 waren lokale Änderungen in zwei Markdown-Dateien sichtbar; Wiederherstellung der Repo-Dateien und lokales `core.autocrlf=false` ermöglichten den Import. Die genaue Ursache der Abweichung wurde nicht isoliert. Kein globales `core.autocrlf` und kein `git reset --hard` als Standardfix. In GitHub Desktop ausschließlich den Arbeitsbranch pushen.

## Übertragen und Teststart

Diesen Block auf C in PowerShell im lokalen Repo ausführen. Er nimmt den Git-Commit `HEAD`, keine ungespeicherten oder nur lokal editierten Dateien. Möglichst erst nach Push des geprüften Commits ausführen; der Push selbst deployt nichts. Das Archiv enthält genau das Dashboard, das Simulationspaket und das Deploy-Skript. Eine neue Sitzung benötigt neue Staging-Variablen; die Vorschau kann dafür erneut ausgeführt werden.

```powershell
$target = 'ha-test'
$hostName = ssh $target hostname
if ($LASTEXITCODE -ne 0 -or ([string]$hostName).Trim() -cne 'ha-test') {
    throw 'Zielhost ist nicht ha-test.'
}
$sha = git rev-parse --short=12 HEAD
if ($LASTEXITCODE -ne 0) { throw 'Kein Git-Commit ermittelt.' }
$archive = Join-Path $env:TEMP "ha-pilot-$sha.tar"
git archive --format=tar --output="$archive" HEAD `
  config/dashboards/living-room-pilot.yaml `
  config/packages/ground_floor/pilot_living_room.yaml `
  tools/deploy_ha_test.py
if ($LASTEXITCODE -ne 0) { throw 'Git-Archiv konnte nicht erstellt werden.' }
$stage = ssh $target 'mktemp -d ~/ha-pilot.XXXXXXXX'
if ($LASTEXITCODE -ne 0 -or $stage -notmatch '^/[a-zA-Z0-9_./-]+/ha-pilot\.[a-zA-Z0-9]+$') {
    throw 'Staging-Verzeichnis ungültig.'
}
scp $archive "${target}:${stage}/pilot.tar"
if ($LASTEXITCODE -ne 0) { throw 'Übertragung fehlgeschlagen.' }
ssh $target "cd '$stage' && tar -xf pilot.tar && python3 tools/deploy_ha_test.py"
if ($LASTEXITCODE -ne 0) { throw 'Dry-Run fehlgeschlagen.' }
```

Der Dry-Run prüft Hostname und `/config`-Mount und vergleicht die Dateien. Bei reinem Dashboard-Wechsel ist `Geplante Dateiänderungen: dashboards/living-room-pilot.yaml` die vollständige erwartete Ausgabe. Ein Inhaltsdiff wird nur für Änderungen an `configuration.yaml` angezeigt. Der Dry-Run ändert keine HA-Konfiguration und führt kein `check_config` aus. Staging und der Skript-Lock können dabei auf dem Pi angelegt werden.

Erst bei erwarteten Zieldateien und nach Review im selben Terminal aus demselben Staging anwenden:

```powershell
ssh $target "cd '$stage' && python3 tools/deploy_ha_test.py --apply"
```

Das Skript legt eine lokale Sicherung der drei verwalteten Pfade an und führt nach dem Schreiben `check_config` aus. Bei einem Validierungsfehler versucht es die vorherigen Dateien wiederherzustellen und startet für diesen Fehlerpfad den Container nicht neu. Bei ausschließlicher Dashboard-YAML-Änderung folgt kein Restart; in **Wohnzimmer (Sim) → ⋮ → Aktualisieren** lädt man die YAML neu. Änderungen am Paket oder an der Registrierung führen nach erfolgreichem Check zu einem HA-Container-Neustart mit HTTP-200-Prüfung. Ein unvertrauter `lovelace:`-Block, Host-/Mount-Abweichung oder Berechtigungsfehler sind Gründe zum Stoppen und Prüfen. Keine Rechte pauschal lockern und keine Registrierungsblöcke blind ersetzen.

Die Payload-Liste in `tools/deploy_ha_test.py` ist fest auf den Wohnzimmer-Pilot beschränkt. Neue Paket-/Dashboard-Dateien erst nach expliziter Erweiterung und Review von Skript, Archivliste, Backup und Abnahme deployen. Das nachträgliche Ablegen im Repo allein überträgt sie nicht.

## Abnahme, Diagnose und Rückfall

- Nach jedem Apply die Ausgabe samt Commit, Backup-Pfad, Check und Reload/Restart protokollieren. `check_config`/HTTP 200 bestätigen die YAML/Erreichbarkeit, kein erfolgreiches Browser-Rendering der Karten.
- Desktop und iPhone getrennt prüfen: Heizzeile ohne Zwischenrahmen, Heizsymbol Heizen/Aus, −/+ in 0,5-°C-Schritten; Dimmer nur bei Licht An, Bogenlampe und TV-Board manuell. Keine abgeschnittenen Bedienelemente oder Kartenfehler. Bei `Custom element doesn't exist` zuerst Frontend-Ressource und Tab-Reload prüfen. Keine Produktiv-Entity zum Test verknüpfen.
- Bei UI-Fehlern vorherigen Stand via zuletzt ausgegebenem Backup wiederherstellen. Das Skript akzeptiert nur den jüngsten Snapshot; es stellt alle drei verwalteten Pfade auf diesen Snapshot zurück und startet auch nach einer reinen UI-Änderung HA neu. Bei zwischenzeitlichen Änderungen erst vergleichen und mit dem Eigentümer abstimmen. Backups bleiben lokal.

```powershell
$backup = (Read-Host 'Absoluter Pfad des letzten Backups auf ha-test').Trim()
if ($backup -notmatch '^/[a-zA-Z0-9_./-]+/\.ha-pilot-backups/deploy-[a-zA-Z0-9_-]+$') {
    throw 'Backup-Pfad passt nicht zum erwarteten Schema.'
}
ssh $target "cd '$stage' && python3 tools/deploy_ha_test.py --rollback '$backup'"
```

## Patch-Verlauf

| Nr. | Basis / Stand | Umfang und Nachweis |
| --- | --- | --- |
| 0001 | `d000092` | Simulationspaket, native Tiles und Deploy-Skript. Registrierung angelegt; Check, Neustart und HTTP 200 protokolliert. |
| 0002 | `e5c5928` | Mushroom-Karten. Nur Dashboard-YAML; Check und Reload ohne Container-Neustart. Bedienprobe ohne Beanstandung, Heizzeile visuell noch nicht wie Mockup. |
| 0003 | `1bdfb87` | Heizzeile horizontal mit Vertical Stack In Card und Card Mod. Nur Dashboard-YAML; Check erfolgreich, kein Neustart. Alle vier Prüfpunkte laut Bedienprobe bestanden, siehe `DASHBOARD_DECISIONS.md`. |
| 0004 | beruht auf `1bdfb87` | Nur Dokumentation zur Übergabe. Patch importieren und Arbeitsbranch pushen; kein SCP, kein Apply, kein HA-Neustart. |
