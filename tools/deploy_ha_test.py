#!/usr/bin/env python3
"""Deploy only the reviewed pilot to ha-test. Never target production."""
import argparse
import difflib
import fcntl
import os
from pathlib import Path
import re
import shutil
import socket
import subprocess
import tempfile
import time
from urllib.error import URLError
from urllib.request import urlopen

ROOT = Path('/opt/ha-test/homeassistant')
CONFIG = ROOT / 'config'
REPO = Path(__file__).resolve().parent.parent
BACKUPS = Path.home() / '.ha-pilot-backups'
PAYLOAD = (
    Path('dashboards/living-room-pilot.yaml'),
    Path('packages/l0/pilot_living_room.yaml'),
    Path('packages/l1/pilot_l1.yaml'),
    Path('packages/l2/pilot_l2.yaml'),
    Path('packages/garden/pilot_garden.yaml'),
    Path('packages/mqtt/pilot_mqtt_readonly.yaml'),
    Path('themes/night_control_light.yaml'),
    Path('themes/night_control_dark.yaml'),
)
MAIN = Path('configuration.yaml')
FILES = (MAIN, *PAYLOAD)
CARD_MOD_URL = '/local/community/lovelace-card-mod/card-mod.js?v=190927524-v4.2.1'
BLOCK = '''# BEGIN HA-TEST LIVING ROOM PILOT
lovelace:
  dashboards:
    living-room-pilot:
      mode: yaml
      title: Zuhause (Sim)
      show_in_sidebar: true
      filename: dashboards/living-room-pilot.yaml
# END HA-TEST LIVING ROOM PILOT
'''
MARKERS = ('# BEGIN HA-TEST LIVING ROOM PILOT', '# END HA-TEST LIVING ROOM PILOT')


def compose(*args, capture=False):
    return subprocess.run(['docker', 'compose', *args], cwd=ROOT, check=True,
                          text=True, capture_output=capture).stdout


def verify_target():
    if socket.gethostname().split('.')[0] != 'ha-test':
        raise RuntimeError('Abbruch: Zielhost ist nicht ha-test.')
    if CONFIG.resolve() != CONFIG or not (CONFIG / MAIN).is_file():
        raise RuntimeError('Abbruch: erwartete HA-Konfiguration nicht gefunden.')
    cid = compose('ps', '-q', 'homeassistant', capture=True).strip()
    if not cid:
        raise RuntimeError('Home-Assistant-Container läuft nicht.')
    mounted = subprocess.check_output([
        'docker', 'inspect', '--format',
        '{{range .Mounts}}{{if eq .Destination "/config"}}{{.Source}}{{end}}{{end}}', cid
    ], text=True).strip()
    if mounted != str(CONFIG):
        raise RuntimeError('Abbruch: /config ist nicht an den erwarteten Testpfad gebunden.')


def checked_path(rel):
    path = CONFIG / rel
    if path.resolve() != path or (path.exists() and not path.is_file()):
        raise RuntimeError(f'Abbruch: unerwarteter Dateityp oder Link: {rel}')
    return path


def new_main(old):
    if not re.search(r'(?m)^  packages:\s*!include_dir_named +packages(?:[ \t]*(?:#.*)?)$', old):
        raise RuntimeError('Erwarteter packages-Include fehlt. Keine Änderung vorgenommen.')

    frontend_anchor = 'frontend:\n  themes: !include_dir_merge_named themes'
    frontend_with_module = (
        frontend_anchor + '\n  extra_module_url:\n    - ' + CARD_MOD_URL
    )
    if CARD_MOD_URL not in old:
        if frontend_anchor not in old:
            raise RuntimeError('Erwarteter frontend/themes-Block fehlt. Keine Änderung vorgenommen.')
        old = old.replace(frontend_anchor, frontend_with_module, 1)

    managed_pattern = re.compile(
        r'(?ms)^# BEGIN HA-TEST LIVING ROOM PILOT\n.*?^# END HA-TEST LIVING ROOM PILOT\n?'
    )
    managed = managed_pattern.findall(old)
    if len(managed) > 1:
        raise RuntimeError('Mehrere verwaltete Pilot-Blöcke gefunden. Keine Änderung vorgenommen.')
    if len(managed) == 1:
        return managed_pattern.sub(BLOCK, old, count=1)

    if re.search(r'(?m)^lovelace\s*:', old):
        raise RuntimeError('Bestehender Lovelace-Block gefunden. Pilot manuell darin ergänzen; nichts überschrieben.')
    if re.search(r'(?m)^(?:---|\.\.\.)(?:\s|$)', old):
        raise RuntimeError('YAML-Dokumentmarker gefunden. Pilot manuell anmelden.')
    return old.rstrip('\r\n') + '\n\n' + BLOCK


def atomic_write(dst, content, mode):
    dst.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile(dir=dst.parent, prefix='.ha-pilot-', delete=False) as handle:
        temp = Path(handle.name)
        try:
            handle.write(content)
            handle.flush()
            os.fchmod(handle.fileno(), mode)
            os.replace(temp, dst)
        finally:
            temp.unlink(missing_ok=True)


def restore(backup):
    if not (backup / 'snapshot-ready').is_file():
        raise RuntimeError('Ungültiges oder unvollständiges Backup.')
    for rel in reversed(FILES):
        dst = checked_path(rel)
        previous = backup / rel
        if previous.is_file():
            atomic_write(dst, previous.read_bytes(), previous.stat().st_mode & 0o777)
        elif (backup / 'absent' / rel).is_file():
            dst.unlink(missing_ok=True)
        else:
            raise RuntimeError(f'Eintrag fehlt im Backup: {rel}')


def restart_and_wait():
    since = time.strftime('%Y-%m-%dT%H:%M:%SZ', time.gmtime())
    compose('restart', 'homeassistant')
    deadline = time.monotonic() + 120
    while time.monotonic() < deadline:
        try:
            with urlopen('http://127.0.0.1:8123/', timeout=3) as response:
                if response.status == 200:
                    print('HA antwortet mit HTTP 200. Dashboard jetzt im Browser testen.', flush=True)
                    print(f'Neue Startlogs: docker compose logs --since {since} homeassistant', flush=True)
                    return
        except (URLError, OSError):
            pass
        time.sleep(3)
    raise RuntimeError('Kein HTTP 200 innerhalb von 120 Sekunden.')


def check():
    compose('exec', '-T', 'homeassistant', 'python', '-m', 'homeassistant',
            '--config', '/config', '--script', 'check_config')


def deploy(apply):
    main = checked_path(MAIN)
    old = main.read_bytes().decode('utf-8')
    new = new_main(old)
    if old != new:
        print(''.join(difflib.unified_diff(old.splitlines(keepends=True),
              new.splitlines(keepends=True), fromfile=str(MAIN), tofile=str(MAIN) + ' (Pilot)', n=0)))
    writes = {}
    for rel in PAYLOAD:
        dst = checked_path(rel)
        content = (REPO / 'config' / rel).read_bytes()
        if not dst.exists() or dst.read_bytes() != content:
            writes[rel] = content
    if old != new:
        managed_block_exists = all(marker in old for marker in MARKERS)
        if (
            not managed_block_exists
            and any(checked_path(rel).exists() for rel in PAYLOAD)
        ):
            raise RuntimeError('Pilot-Dateiname existiert ohne verwalteten Block. Keine Datei überschrieben.')
        writes[MAIN] = new.encode('utf-8')
    print('Geplante Dateiänderungen: ' + (', '.join(map(str, writes)) or 'keine'), flush=True)
    if not apply or not writes:
        return
    backup = Path(tempfile.mkdtemp(prefix='deploy-', dir=BACKUPS))
    for rel in FILES:
        src = checked_path(rel)
        if src.exists():
            (backup / rel).parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(src, backup / rel)
        else:
            absent = backup / 'absent' / rel
            absent.parent.mkdir(parents=True, exist_ok=True)
            absent.touch()
    (backup / 'snapshot-ready').touch()
    print(f'Lokales Backup: {backup}', flush=True)
    restarting = False
    try:
        for rel, content in writes.items():
            dst = checked_path(rel)
            atomic_write(dst, content, dst.stat().st_mode & 0o777 if dst.exists() else 0o644)
        check()
        if set(writes) != {PAYLOAD[0]}:
            restarting = True
            restart_and_wait()
        else:
            print('Nur Lovelace-YAML geändert. Im Pilot unter ⋮ → Aktualisieren neu laden.', flush=True)
    except (KeyboardInterrupt, Exception):
        restore(backup)
        print('Vorherige Dateien wiederhergestellt.', flush=True)
        if restarting:
            check()
            restart_and_wait()
        (backup / 'snapshot-ready').rename(backup / 'rolled-back')
        raise


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    group = parser.add_mutually_exclusive_group()
    group.add_argument('--apply', action='store_true', help='Deploy; without an option, show the plan only')
    group.add_argument('--rollback', metavar='BACKUP', type=Path, help='Restore the latest saved snapshot')
    args = parser.parse_args()
    verify_target()
    BACKUPS.mkdir(mode=0o700, exist_ok=True)
    with (BACKUPS / '.lock').open('a') as lock:
        fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        if args.rollback:
            backup = args.rollback.resolve(strict=True)
            if backup.parent != BACKUPS.resolve():
                raise RuntimeError('Backup muss im lokalen Pilot-Backupordner liegen.')
            latest = max((p for p in BACKUPS.glob('deploy-*') if (p / 'snapshot-ready').is_file()),
                         key=lambda p: (p / 'snapshot-ready').stat().st_mtime_ns)
            if backup != latest:
                raise RuntimeError('Nur das jüngste Backup direkt zurückspielen.')
            restore(backup)
            check()
            restart_and_wait()
            (backup / 'snapshot-ready').rename(backup / 'rolled-back')
        else:
            deploy(args.apply)


if __name__ == '__main__':
    try:
        main()
    except (RuntimeError, OSError, subprocess.CalledProcessError) as exc:
        raise SystemExit(f'FEHLER: {exc}') from exc
