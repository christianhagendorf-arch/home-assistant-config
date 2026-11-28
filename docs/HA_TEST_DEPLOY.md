# Home Assistant: Test-Deploy und Ãœbergabe

Stand: 22.11.2026. Entwicklungsbasis des abgenommenen Wohnzimmer-Piloten: `feature/living-room-pilot`, Commit `1bdfb87` (Patch 0003). Dieses Runbook gilt ausschlieÃŸlich fÃ¼r `ha-test`. Adressen, Arbeitsplatzpfade und der konkrete Backup-Nachweis gehÃ¶ren in das separat und autorisiert weitergegebene Ãœbergabedokument.

## Arbeitsumgebung und ZustÃ¤ndigkeiten

- **A: Test-Pi (`ha-test`).** Raspberry Pi mit Debian 13 und Home Assistant Container, betrieben Ã¼ber Docker Compose. Portainer steht zur Einsicht bereit. Der Pi benÃ¶tigt weder einen Git-Checkout noch GitHub-Zugangsdaten. Dashboard-Pilot: â€žWohnzimmer (Sim)â€œ, `/living-room-pilot/ground_floor`.
- **B: Laptop.** Chat/Entwurf, Downloads und GitHub-Review im Browser, bei Bedarf SSH zur Diagnose. Der Chat ist weder auf dem Pi angemeldet noch mit dem lokalen Checkout verbunden. Der GAIA-GitHub-Connector wird nicht genutzt.
- **C: Windows-Mini-PC.** Lokaler Git-Checkout, GitHub Desktop, VS Code, PowerShell/OpenSSH. Code und Dokumentation hier bearbeiten und committen, vom Arbeitsbranch pushen und per SSH/SCP bereitstellen. YAML- und Home Assistant Config Helper sind im Repo empfohlen. FÃ¼r die Entwicklung ist keine zusÃ¤tzliche lokale HA-Instanz nÃ¶tig.

Bei Chat-Patches fÃ¼hrt der Weg B â†’ freigegebener kDrive-Transfer â†’ C â†’ SSH-Staging auf A. Der Transferordner enthÃ¤lt Patch und Anleitung, keinen Git-Checkout. Bei direkter Entwicklung auf C kann nach Commit und Review sofort aus Git bereitgestellt werden. Weder direkte Live-DateiÃ¤nderungen per Remote-Editor/SFTP noch ein ungeprÃ¼fter `git pull` auf dem Pi sind Teil des Workflows.

## Einstieg und Vorbereitung

1. Repo-Zugriff Ã¼ber den EigentÃ¼mer einrichten. Repo soll privat sein; Sichtbarkeit im GitHub-Kopf prÃ¼fen. Keine SchlÃ¼ssel, Tokens, `secrets.yaml`, `.storage`, Datenbanken oder Backups einchecken. Private SchlÃ¼ssel bleiben auf den jeweiligen GerÃ¤ten. FÃ¼r die Ã¼bernehmende Person einen eigenen Ã¶ffentlichen SchlÃ¼ssel autorisieren; SSH-Hostfingerabdruck Ã¼ber einen bereits vertrauenswÃ¼rdigen Kanal prÃ¼fen.
2. Arbeitsbranch in GitHub Desktop wÃ¤hlen und `Fetch origin` ausfÃ¼hren. In VS Code `git status --short --branch` und `git log -3 --oneline` prÃ¼fen. Offene Ã„nderungen an versionierten Dateien vor einem Patch separat sichern oder committen. Einen Patch nie zweimal anwenden. Kein direktes Arbeiten auf `main`.
3. Auf A ist der Compose-Projektordner `/opt/ha-test/homeassistant`; Host-Config `config/` wird als `/config` eingebunden. GewÃ¶hnlicher Zugriff ist Ã¼ber den lokal eingerichteten SSH-Alias `ha-test`; `ssh ha-test hostname` muss `ha-test` zurÃ¼ckgeben. Host-Netzwerk, Registry und Produktionsverbindungen bleiben unverÃ¤ndert.
4. Auf A in **Einstellungen â†’ Marketplace** vorhandene Frontend-Ressourcen prÃ¼fen: Mushroom (`piitaya/lovelace-mushroom`), Card Mod (`thomasloven/lovelace-card-mod`), Vertical Stack In Card (`ofekashery/vertical-stack-in-card`). FÃ¼r 0003 ist weder `custom-cards/stack-in-card` noch der gleichnamige Fork erforderlich. Versionen bei der Ãœbergabe erfassen; bei Kartenfehlern Registrierung und Browser-Reload prÃ¼fen.

## Git-Patch einspielen

Vierstellige passende PrÃ¤fixe: `NNNN-<thema>.patch` plus `NNNN-HA_TEST_DEPLOY-snippet.md`. Das Snippet ist schon vor dem Import verfÃ¼gbar und enthÃ¤lt die konkreten Kopiervorlagen. Dieses Runbook bleibt unnummeriert und fÃ¼hrt die Historie kumulativ. Downloadkopien der Repo-Markdown-Dateien nie vor `git am` Ã¼ber die versionierten Dateien kopieren.

Auf C in PowerShell den Patchpfad aus dem Transferordner angeben. Erst bei erfolgreichem Check anwenden; `git am` erzeugt den Commit selbst.

```powershell
$patch = (Read-Host 'VollstÃ¤ndiger Pfad zur Patch-Datei').Trim('"')
if (-not (Test-Path -LiteralPath $patch -PathType Leaf)) { throw 'Patch fehlt.' }
git status --short --branch
git apply --check -- $patch
if ($LASTEXITCODE -ne 0) { throw 'Patch-PrÃ¼fung fehlgeschlagen; nichts importiert.' }
git am -- $patch
if ($LASTEXITCODE -ne 0) { throw 'Import fehlgeschlagen; Git-Status prÃ¼fen.' }
git log -3 --oneline
```

Bei einem bereits gescheiterten, noch laufenden Import zeigt `git status` den `am`-Vorgang an. Eigene Ã„nderungen sichern und erst dann ggf. `git am --abort` verwenden. Bei `does not match index` zuerst `git diff` und `git diff --cached` ansehen. Bei 0002 waren lokale Ã„nderungen in zwei Markdown-Dateien sichtbar; Wiederherstellung der Repo-Dateien und lokales `core.autocrlf=false` ermÃ¶glichten den Import. Die genaue Ursache der Abweichung wurde nicht isoliert. Kein globales `core.autocrlf` und kein `git reset --hard` als Standardfix. In GitHub Desktop ausschlieÃŸlich den Arbeitsbranch pushen.

## Ãœbertragen und Teststart

Diesen Block auf C in PowerShell im lokalen Repo ausfÃ¼hren. Er nimmt den Git-Commit `HEAD`, keine ungespeicherten oder nur lokal editierten Dateien. MÃ¶glichst erst nach Push des geprÃ¼ften Commits ausfÃ¼hren; der Push selbst deployt nichts. Das Archiv enthÃ¤lt genau das Dashboard, das Simulationspaket und das Deploy-Skript. Eine neue Sitzung benÃ¶tigt neue Staging-Variablen; die Vorschau kann dafÃ¼r erneut ausgefÃ¼hrt werden.

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
  config/packages/l0/pilot_living_room.yaml `
  tools/deploy_ha_test.py
if ($LASTEXITCODE -ne 0) { throw 'Git-Archiv konnte nicht erstellt werden.' }
$stage = ssh $target 'mktemp -d ~/ha-pilot.XXXXXXXX'
if ($LASTEXITCODE -ne 0 -or $stage -notmatch '^/[a-zA-Z0-9_./-]+/ha-pilot\.[a-zA-Z0-9]+$') {
    throw 'Staging-Verzeichnis ungÃ¼ltig.'
}
scp $archive "${target}:${stage}/pilot.tar"
if ($LASTEXITCODE -ne 0) { throw 'Ãœbertragung fehlgeschlagen.' }
ssh $target "cd '$stage' && tar -xf pilot.tar && python3 tools/deploy_ha_test.py"
if ($LASTEXITCODE -ne 0) { throw 'Dry-Run fehlgeschlagen.' }
```

Der Dry-Run prÃ¼ft Hostname und `/config`-Mount und vergleicht die Dateien. Bei reinem Dashboard-Wechsel ist `Geplante DateiÃ¤nderungen: dashboards/living-room-pilot.yaml` die vollstÃ¤ndige erwartete Ausgabe. Ein Inhaltsdiff wird nur fÃ¼r Ã„nderungen an `configuration.yaml` angezeigt. Der Dry-Run Ã¤ndert keine HA-Konfiguration und fÃ¼hrt kein `check_config` aus. Staging und der Skript-Lock kÃ¶nnen dabei auf dem Pi angelegt werden.

Erst bei erwarteten Zieldateien und nach Review im selben Terminal aus demselben Staging anwenden:

```powershell
ssh $target "cd '$stage' && python3 tools/deploy_ha_test.py --apply"
```

Das Skript legt eine lokale Sicherung der drei verwalteten Pfade an und fÃ¼hrt nach dem Schreiben `check_config` aus. Bei einem Validierungsfehler versucht es die vorherigen Dateien wiederherzustellen und startet fÃ¼r diesen Fehlerpfad den Container nicht neu. Bei ausschlieÃŸlicher Dashboard-YAML-Ã„nderung folgt kein Restart; in **Wohnzimmer (Sim) â†’ â‹® â†’ Aktualisieren** lÃ¤dt man die YAML neu. Ã„nderungen am Paket oder an der Registrierung fÃ¼hren nach erfolgreichem Check zu einem HA-Container-Neustart mit HTTP-200-PrÃ¼fung. Ein unvertrauter `lovelace:`-Block, Host-/Mount-Abweichung oder Berechtigungsfehler sind GrÃ¼nde zum Stoppen und PrÃ¼fen. Keine Rechte pauschal lockern und keine RegistrierungsblÃ¶cke blind ersetzen.

Die Payload-Liste in `tools/deploy_ha_test.py` ist fest auf den Wohnzimmer-Pilot beschrÃ¤nkt. Neue Paket-/Dashboard-Dateien erst nach expliziter Erweiterung und Review von Skript, Archivliste, Backup und Abnahme deployen. Das nachtrÃ¤gliche Ablegen im Repo allein Ã¼bertrÃ¤gt sie nicht.

## Abnahme, Diagnose und RÃ¼ckfall

- Nach jedem Apply die Ausgabe samt Commit, Backup-Pfad, Check und Reload/Restart protokollieren. `check_config`/HTTP 200 bestÃ¤tigen die YAML/Erreichbarkeit, kein erfolgreiches Browser-Rendering der Karten.
- Desktop und iPhone getrennt prÃ¼fen: Heizzeile ohne Zwischenrahmen, Heizsymbol Heizen/Aus, âˆ’/+ in 0,5-Â°C-Schritten; Dimmer nur bei Licht An, Bogenlampe und TV-Board manuell. Keine abgeschnittenen Bedienelemente oder Kartenfehler. Bei `Custom element doesn't exist` zuerst Frontend-Ressource und Tab-Reload prÃ¼fen. Keine Produktiv-Entity zum Test verknÃ¼pfen.
- Bei UI-Fehlern vorherigen Stand via zuletzt ausgegebenem Backup wiederherstellen. Das Skript akzeptiert nur den jÃ¼ngsten Snapshot; es stellt alle drei verwalteten Pfade auf diesen Snapshot zurÃ¼ck und startet auch nach einer reinen UI-Ã„nderung HA neu. Bei zwischenzeitlichen Ã„nderungen erst vergleichen und mit dem EigentÃ¼mer abstimmen. Backups bleiben lokal.

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
| 0003 | `1bdfb87` | Heizzeile horizontal mit Vertical Stack In Card und Card Mod. Nur Dashboard-YAML; Check erfolgreich, kein Neustart. Alle vier PrÃ¼fpunkte laut Bedienprobe bestanden, siehe `DASHBOARD_DECISIONS.md`. |
| 0004 | beruht auf `1bdfb87` | Nur Dokumentation zur Ãœbergabe. Patch importieren und Arbeitsbranch pushen; kein SCP, kein Apply, kein HA-Neustart. |

