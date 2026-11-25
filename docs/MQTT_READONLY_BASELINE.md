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

The MQTT integration on `ha-test` must use `192.168.178.16:1883` with TLS off and empty username/password. MQTT Discovery must be disabled before the connection is accepted. If the setup flow does not offer a way to keep Discovery disabled before connecting, cancel setup and do not proceed.

## Physical test

Warm each nearby Sonoff SNZB-02/TH01 sensor separately using a hand or warm breath. Allow 30 seconds to several minutes for a battery-powered device report. Confirm the related MQTT topic, Home Assistant entity, and MQTT diagnosis view all update without manual refresh.
