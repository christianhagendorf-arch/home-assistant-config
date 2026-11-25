# MQTT read-only baseline

## Purpose

Patch 0027 validates a read-only data path from the existing Mosquitto broker to `ha-test` without publishing messages or controlling devices.

## Broker and production context

```text
Broker: 192.168.178.16
Port: 1883
TLS: no
Authentication: none at the current production listener
Zigbee2MQTT base topic: zigbee2mqtt
Production Discovery prefix: homeassistant
```

Security hardening is deliberately deferred to the later production-migration security phase. Patch 0027 does not change Mosquitto, Zigbee2MQTT, production Home Assistant, listeners, ACLs, users, passwords, or TLS.

## Read-only topics

```text
zigbee2mqtt/bridge/state
zigbee2mqtt/temp_arbeitszimmer
zigbee2mqtt/temp_arbeitszimmer/availability
zigbee2mqtt/temp_schlafzimmer
zigbee2mqtt/temp_schlafzimmer/availability
```

## Safety boundaries

The package contains:

- no `command_topic`
- no MQTT publish action
- no automation
- no MQTT light, switch, cover, climate, button, or number
- no production entity replacement

The existing simulated temperature and climate entities remain unchanged.

## MQTT integration rule

The MQTT integration on `ha-test` uses `192.168.178.16:1883` with TLS off and empty username/password. In the tested Home Assistant setup flow, Discovery could only be disabled after the first connection. The initial connection imported 32 devices and 135 entities from retained production discovery messages. Discovery was then disabled, all imported devices were deleted locally from `ha-test`, and a restart confirmed that they did not return. Discovery must remain disabled and the MQTT integration must contain no automatically discovered production devices.

## Physical test

Warm each nearby Sonoff SNZB-02/TH01 sensor separately using a hand or warm breath. Allow 30 seconds to several minutes for a battery-powered device report. Confirm the related MQTT topic, Home Assistant entity, and MQTT diagnosis view all update without manual refresh.

## Persistent ha-test network exception

Patch 0028 installs an idempotent `systemd` service on `ha-test` that restores the narrow Docker-network exception to `192.168.178.16:1883/TCP` after reboot. The existing production-host DROP rule remains authoritative for all other traffic. See `docs/MQTT_INVENTORY.md`.
