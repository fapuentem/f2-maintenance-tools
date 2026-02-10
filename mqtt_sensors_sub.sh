#!/usr/bin/env bash
set -euo pipefail

# ARGUMENTS
[ "$#" -eq 1 ] || { echo "Usage: $0 <mac>" >&2; exit 1; }

MAC="$1"
MAC_LABEL="F2-${MAC}"
TOPIC="tele/f2-${MAC}/sensor-mode/+/+"

ENDPOINT="a35lkm5jyds64h-ats.iot.us-east-1.amazonaws.com"
CERT_DIR="$HOME/projects/F2-App/certs"

CA_FILE="$CERT_DIR/AmazonRootCA1.pem"
CERT_FILE=$(ls "$CERT_DIR"/*-certificate.pem.crt 2>/dev/null | head -n1 || true)
KEY_FILE=$(ls "$CERT_DIR"/*-private.pem.key 2>/dev/null | head -n1 || true)

[ -f "$CA_FILE" ] || { echo "Missing CA file" >&2; exit 2; }
[ -n "$CERT_FILE" ] || { echo "Missing certificate file" >&2; exit 3; }
[ -n "$KEY_FILE"  ] || { echo "Missing private key file" >&2; exit 4; }

declare -A SENSORS
declare -A CONNECTORS

print_summary() {
  echo
  echo
  echo "Summary:"
  echo
  echo "$MAC_LABEL:"
  echo

  mapfile -t conns < <(printf "%s\n" "${!CONNECTORS[@]}" | sort)

  for c in "${conns[@]}"; do
    mapfile -t nums < <(
      printf "%s\n" "${!SENSORS[@]}" |
      awk -F/ -v c="$c" '$1==c {print $2}' |
      sort -n
    )

    printf "%s: %d sensors ->" "$c" "${#nums[@]}"
    for n in "${nums[@]}"; do
      printf " sensor-%s" "$n"
    done
    echo
  done
}

trap print_summary INT

echo "Subscribing to topic: $TOPIC"
echo "Press Ctrl+C to stop"
echo

while read -r topic payload; do
  # Extract connector and sensor safely
  connector="${topic%/*}"
  connector="${connector##*/}"

  sensor="${topic##*/}"
  num="${sensor#sensor-}"

  key="$connector/$num"

  if [[ -z "${SENSORS[$key]:-}" ]]; then
    SENSORS["$key"]=1
    CONNECTORS["$connector"]=1
    echo "Discovered $connector sensor-$num"
  fi
done < <(
  mosquitto_sub \
    -h "$ENDPOINT" \
    -p 8883 \
    --cafile "$CA_FILE" \
    --cert "$CERT_FILE" \
    --key "$KEY_FILE" \
    -t "$TOPIC" \
    -v
)
