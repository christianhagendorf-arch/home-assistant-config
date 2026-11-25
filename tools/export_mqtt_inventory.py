#!/usr/bin/env python3
"""Build a redacted MQTT device inventory from read-only capture files.

Inputs are produced with mosquitto_sub on the broker Pi. This program never
connects to MQTT and never publishes data.
"""
from __future__ import annotations

import argparse
import csv
import json
from pathlib import Path
from typing import Any

SENSITIVE_KEYS = {
    "password", "passwd", "token", "network_key", "pan_id", "ext_pan_id",
    "secret", "key", "username", "user",
}
COMPONENTS = {
    "alarm_control_panel", "binary_sensor", "button", "climate", "cover",
    "device_tracker", "event", "fan", "humidifier", "image", "light", "lock",
    "number", "select", "sensor", "siren", "switch", "text", "update",
    "vacuum", "valve", "water_heater",
}


def load_json(path: Path) -> Any:
    return json.loads(path.read_text(encoding="utf-8"))


def parse_discovery(path: Path) -> list[tuple[str, dict[str, Any]]]:
    records: list[tuple[str, dict[str, Any]]] = []
    for number, raw in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        line = raw.strip()
        if not line:
            continue
        topic, separator, payload = line.partition(" ")
        if not separator:
            raise ValueError(f"{path}:{number}: expected '<topic> <json>'")
        data = json.loads(payload)
        if not isinstance(data, dict):
            raise ValueError(f"{path}:{number}: discovery payload is not an object")
        records.append((topic, data))
    return records


def safe_text(value: Any) -> str:
    if value is None:
        return ""
    if isinstance(value, (dict, list)):
        return json.dumps(value, ensure_ascii=False, sort_keys=True)
    return str(value)


def topic_from(value: Any) -> str:
    if isinstance(value, str):
        return value
    if isinstance(value, list):
        return "; ".join(
            item.get("topic", "") for item in value if isinstance(item, dict)
        )
    if isinstance(value, dict):
        return value.get("topic", "")
    return ""


def component_from(topic: str, data: dict[str, Any]) -> str:
    parts = topic.split("/")
    if len(parts) > 1 and parts[1] in COMPONENTS:
        return parts[1]
    return safe_text(data.get("platform"))


def device_key(data: dict[str, Any], topic: str) -> str:
    device = data.get("device") or {}
    identifiers = device.get("identifiers") or []
    if isinstance(identifiers, str):
        identifiers = [identifiers]
    if identifiers:
        return safe_text(identifiers[0])
    return safe_text(data.get("device_id") or data.get("unique_id") or topic)


def command_topics(data: dict[str, Any]) -> list[str]:
    found = []
    for key, value in data.items():
        if key.endswith("command_topic") or key in {
            "set_position_topic", "rgb_command_topic", "brightness_command_topic"
        }:
            if isinstance(value, str) and value:
                found.append(value)
    return sorted(set(found))


def classify(components: set[str], models: str, names: str) -> str:
    text = f"{models} {names}".lower()
    if "climate" in components or any(x in text for x in ("thermostat", "trv", "radiator")):
        return "Heating / climate"
    if "cover" in components:
        return "Roller shutter / cover"
    if "light" in components:
        return "Light"
    if "switch" in components and any(x in text for x in ("plug", "socket", "steck")):
        return "Plug / power"
    if "binary_sensor" in components and any(x in text for x in ("contact", "door", "window", "fenster")):
        return "Door / window contact"
    if "binary_sensor" in components and any(x in text for x in ("motion", "occupancy", "beweg")):
        return "Motion / occupancy"
    if "sensor" in components and any(x in text for x in ("temperature", "temp", "humidity", "th01", "snzb-02")):
        return "Temperature / humidity"
    return "Other / diagnostic"


def build_inventory(devices_data: Any, discovery: list[tuple[str, dict[str, Any]]]) -> list[dict[str, str]]:
    devices: dict[str, dict[str, Any]] = {}
    if isinstance(devices_data, list):
        source_devices = devices_data
    elif isinstance(devices_data, dict):
        source_devices = devices_data.get("devices", [])
    else:
        raise ValueError("bridge devices input must contain a JSON array")

    for item in source_devices:
        if not isinstance(item, dict):
            continue
        ieee = safe_text(item.get("ieee_address"))
        friendly = safe_text(item.get("friendly_name"))
        definition = item.get("definition") or {}
        key = f"zigbee2mqtt_{ieee}" if ieee else friendly
        devices[key] = {
            "key": key,
            "ieee": ieee,
            "friendly": friendly,
            "manufacturer": safe_text(definition.get("vendor") or item.get("manufacturer")),
            "model": safe_text(definition.get("model") or item.get("model_id")),
            "description": safe_text(definition.get("description")),
            "components": set(),
            "entities": set(),
            "state_topics": set(),
            "availability_topics": set(),
            "command_topics": set(),
            "unique_ids": set(),
        }

    for topic, data in discovery:
        key = device_key(data, topic)
        device = data.get("device") or {}
        identifiers = device.get("identifiers") or []
        if isinstance(identifiers, str):
            identifiers = [identifiers]
        if identifiers:
            key = safe_text(identifiers[0])
        entry = devices.setdefault(key, {
            "key": key,
            "ieee": "",
            "friendly": safe_text(device.get("name")),
            "manufacturer": safe_text(device.get("manufacturer")),
            "model": safe_text(device.get("model") or device.get("model_id")),
            "description": "",
            "components": set(), "entities": set(), "state_topics": set(),
            "availability_topics": set(), "command_topics": set(), "unique_ids": set(),
        })
        entry["components"].add(component_from(topic, data))
        entity = data.get("default_entity_id") or data.get("object_id") or data.get("name")
        if entity:
            entry["entities"].add(safe_text(entity))
        if data.get("state_topic"):
            entry["state_topics"].add(safe_text(data["state_topic"]))
        availability = topic_from(data.get("availability") or data.get("availability_topic"))
        if availability:
            entry["availability_topics"].update(x.strip() for x in availability.split(";") if x.strip())
        entry["command_topics"].update(command_topics(data))
        if data.get("unique_id"):
            entry["unique_ids"].add(safe_text(data["unique_id"]))

    rows = []
    for entry in devices.values():
        components = {x for x in entry["components"] if x}
        names = " ".join([entry["friendly"], *entry["entities"]])
        rows.append({
            "category": classify(components, entry["model"], names),
            "friendly_name": entry["friendly"],
            "ieee_address": entry["ieee"],
            "manufacturer": entry["manufacturer"],
            "model": entry["model"],
            "components": ", ".join(sorted(components)),
            "state_topics": "; ".join(sorted(entry["state_topics"])),
            "availability_topics": "; ".join(sorted(entry["availability_topics"])),
            "command_topics": "; ".join(sorted(entry["command_topics"])),
            "command_topic_present": "yes" if entry["command_topics"] else "no",
            "production_entities": "; ".join(sorted(entry["entities"])),
            "discovery_unique_ids": "; ".join(sorted(entry["unique_ids"])),
            "migration_owner": "production",
            "ha_test_status": "inventory only",
            "notes": "",
        })
    return sorted(rows, key=lambda row: (row["category"], row["friendly_name"], row["ieee_address"]))


def write_csv(path: Path, rows: list[dict[str, str]]) -> None:
    fields = list(rows[0]) if rows else [
        "category", "friendly_name", "ieee_address", "manufacturer", "model",
        "components", "state_topics", "availability_topics", "command_topics",
        "command_topic_present", "production_entities", "discovery_unique_ids",
        "migration_owner", "ha_test_status", "notes",
    ]
    with path.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=fields)
        writer.writeheader(); writer.writerows(rows)


def write_markdown(path: Path, rows: list[dict[str, str]]) -> None:
    categories: dict[str, list[dict[str, str]]] = {}
    for row in rows:
        categories.setdefault(row["category"], []).append(row)
    lines = [
        "# Generated MQTT device inventory", "",
        "> Generated from read-only retained Discovery and Zigbee2MQTT bridge-device captures.",
        "> Review before committing. No broker connection or publish operation is performed by the generator.", "",
        f"Physical/logical device records: **{len(rows)}**", "",
    ]
    for category in sorted(categories):
        lines += [f"## {category}", ""]
        for row in categories[category]:
            display = row["friendly_name"] or row["ieee_address"] or "Unnamed device"
            lines += [
                f"### {display}", "",
                f"- IEEE address: `{row['ieee_address'] or 'unknown'}`",
                f"- Manufacturer/model: {row['manufacturer'] or 'unknown'} / {row['model'] or 'unknown'}",
                f"- Components: `{row['components'] or 'unknown'}`",
                f"- State topics: `{row['state_topics'] or 'none found'}`",
                f"- Availability topics: `{row['availability_topics'] or 'none found'}`",
                f"- Command topics present: **{row['command_topic_present']}**",
                f"- Command topics: `{row['command_topics'] or 'none found'}`",
                f"- Production entities: `{row['production_entities'] or 'none found'}`",
                "- Migration owner: production",
                "- ha-test status: inventory only",
                "- Review notes:", "",
            ]
    path.write_text("\n".join(lines), encoding="utf-8", newline="\n")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--devices", type=Path, required=True, help="zigbee2mqtt/bridge/devices JSON capture")
    parser.add_argument("--discovery", type=Path, required=True, help="topic-plus-JSON retained discovery capture")
    parser.add_argument("--output-md", type=Path, required=True)
    parser.add_argument("--output-csv", type=Path, required=True)
    args = parser.parse_args()
    discovery = parse_discovery(args.discovery)
    # Reject known secret-bearing keys if malformed capture accidentally contains configuration secrets.
    for _, payload in discovery:
        if SENSITIVE_KEYS.intersection(payload):
            raise ValueError("Discovery capture contains a sensitive top-level key; aborting")
    rows = build_inventory(load_json(args.devices), discovery)
    args.output_md.parent.mkdir(parents=True, exist_ok=True)
    args.output_csv.parent.mkdir(parents=True, exist_ok=True)
    write_markdown(args.output_md, rows)
    write_csv(args.output_csv, rows)
    print(f"Inventory records: {len(rows)}")
    print(f"Markdown: {args.output_md}")
    print(f"CSV: {args.output_csv}")


if __name__ == "__main__":
    main()
