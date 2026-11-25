# MQTT inventory

## Scope

This inventory records the observed production MQTT landscape for controlled migration to `ha-test`. It is descriptive only. Patch 0028 does not change the production broker, Zigbee2MQTT, or production Home Assistant.

## Broker

```text
Host: 192.168.178.16
Software: Mosquitto 2.0.12
Listener: TCP 1883
TLS listener: none observed on 8883
Authentication: none on the existing listener
Anonymous access: enabled
Persistence: /var/lib/mosquitto/
```

Production hardening is deferred to the migration security phase. That phase must define external exposure, network segmentation, identities, password handling, ACLs, TLS, backups, and cutover sequencing before changing the current listener.

## Existing clients and discovery

- Zigbee2MQTT 2.6.2 uses `mqtt://192.168.178.16:1883`, MQTT v5, base topic `zigbee2mqtt`, and no username/password.
- Zigbee2MQTT Home Assistant discovery is enabled.
- Production Home Assistant uses `192.168.178.16:1883` without username/password or TLS.
- Retained discovery configurations exist under `homeassistant/#`.
- MQTT Discovery remains disabled on `ha-test`.

## Accepted read-only baseline

### Bridge

```text
State topic: zigbee2mqtt/bridge/state
Observed payload: {"state":"online"}
ha-test entity: binary_sensor.zigbee2mqtt_bridge_readonly
```

### Arbeitszimmer temperature sensor

```text
Device: Sonoff SNZB-02 / TH01
IEEE address: 0x00124b002922556f
Short address observed: 0x20AA
State topic: zigbee2mqtt/temp_arbeitszimmer
Availability topic: zigbee2mqtt/temp_arbeitszimmer/availability
Payload fields: temperature, humidity, battery, voltage, linkquality, last_seen
ha-test entities:
  sensor.office_temperature_mqtt
  sensor.office_battery_mqtt
  sensor.office_linkquality_mqtt
```

### Schlafzimmer temperature sensor

```text
Device: Sonoff SNZB-02 / TH01
IEEE address: 0x00124b002fad0c72
Short address observed: 0xD4B3
State topic: zigbee2mqtt/temp_schlafzimmer
Availability topic: zigbee2mqtt/temp_schlafzimmer/availability
Payload fields: temperature, humidity, battery, voltage, linkquality, last_seen
ha-test entities:
  sensor.bedroom_temperature_mqtt
  sensor.bedroom_battery_mqtt
  sensor.bedroom_linkquality_mqtt
```

## Network boundary on ha-test

The Home Assistant Docker network is `172.19.0.0/16`. The existing `DOCKER-USER` policy blocks this network from production host `192.168.178.16`. Patch 0028 adds one exception before that block:

```text
source:      172.19.0.0/16
destination: 192.168.178.16/32
protocol:    TCP
port:        1883
action:      ACCEPT
```

All other traffic from the Home Assistant Docker network to `192.168.178.16` remains blocked by the existing rule.

This network exception is not an MQTT ACL. The read-only guarantee currently comes from the `ha-test` configuration containing no command topics, publish actions, or actuator entities.

## Inventory backlog

Before writable migration, inventory and assign control ownership for:

- room temperature and humidity sensors
- lights and dimmers
- plugs and appliance power measurement
- roller shutters
- radiator TRVs and Better Thermostat candidates
- floor-heating Sonoff Mini actuators and circulation pump
- motion and window sensors
- washer/dryer automations and notifications
- Zigbee2MQTT bridge and diagnostics

For each item record: physical device, IEEE/MAC identifier, friendly name, state topic, command topic if any, availability topic, discovery unique ID, current production entity, retained-message behavior, and intended owner during migration.

## Patch 0029 inventory workflow

Use `tools/export_mqtt_inventory.py` with two read-only captures: `zigbee2mqtt/bridge/devices` and retained `homeassistant/#` discovery configurations. The generator does not connect to MQTT or publish messages. Generated Markdown and CSV must be reviewed before either is committed. Raw capture files remain outside Git under `patches/` and must not contain broker credentials or Zigbee network keys.
