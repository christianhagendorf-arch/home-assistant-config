#!/bin/sh
set -eu

CHAIN="DOCKER-USER"
SOURCE_CIDR="172.19.0.0/16"
DESTINATION="192.168.178.16/32"
PORT="1883"
COMMENT="ha-test-mqtt-readonly"

rule_exists() {
  iptables -C "$CHAIN" -s "$SOURCE_CIDR" -d "$DESTINATION" \
    -p tcp --dport "$PORT" -m conntrack --ctstate NEW,ESTABLISHED \
    -m comment --comment "$COMMENT" -j ACCEPT 2>/dev/null
}

remove_rule() {
  while rule_exists; do
    iptables -D "$CHAIN" -s "$SOURCE_CIDR" -d "$DESTINATION" \
      -p tcp --dport "$PORT" -m conntrack --ctstate NEW,ESTABLISHED \
      -m comment --comment "$COMMENT" -j ACCEPT
  done
}

apply_rule() {
  iptables -nL "$CHAIN" >/dev/null 2>&1 || {
    echo "Missing iptables chain: $CHAIN" >&2
    exit 1
  }
  remove_rule
  iptables -I "$CHAIN" 1 -s "$SOURCE_CIDR" -d "$DESTINATION" \
    -p tcp --dport "$PORT" -m conntrack --ctstate NEW,ESTABLISHED \
    -m comment --comment "$COMMENT" -j ACCEPT
  check_rule
}

check_rule() {
  rule_exists || {
    echo "MQTT firewall exception is missing." >&2
    exit 1
  }

  accept_line=$(iptables -nL "$CHAIN" --line-numbers | awk -v marker="$COMMENT" '$0 ~ marker {print $1; exit}')
  drop_line=$(iptables -nL "$CHAIN" --line-numbers | awk \
    -v source="$SOURCE_CIDR" -v destination="192.168.178.16" \
    '$2 == "DROP" && $0 ~ "172.19.0.0/16" && $0 ~ destination {print $1; exit}')

  [ -n "$accept_line" ] || {
    echo "Unable to determine MQTT exception position." >&2
    exit 1
  }
  if [ -n "$drop_line" ] && [ "$accept_line" -ge "$drop_line" ]; then
    echo "MQTT exception is below the production-host DROP rule." >&2
    exit 1
  fi

  echo "MQTT firewall exception is active at DOCKER-USER line $accept_line."
}

case "${1:-apply}" in
  apply|start)
    apply_rule
    ;;
  check|status)
    check_rule
    ;;
  remove|stop)
    remove_rule
    echo "MQTT firewall exception removed."
    ;;
  *)
    echo "Usage: $0 {apply|check|remove}" >&2
    exit 2
    ;;
esac
