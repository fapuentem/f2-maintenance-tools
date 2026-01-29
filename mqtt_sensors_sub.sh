#!/usr/bin/env bash
set -euo pipefail

# ARGUMENTS
if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <mac>" >&2
  exit 1
fi

MAC="$1"

# BUILD TOPIC (wildcards)
TOPIC="tele/f2-${MAC}/sensor-mode/+/+"

# AWS SETTINGS
ENDPOINT="a35lkm5jyds64h-ats.iot.us-east-1.amazonaws.com"

# CERT DIR
CERT_DIR="$HOME/projects/F2-App/certs"

CA_FILE="$CERT_DIR/AmazonRootCA1.pem"
CERT_GLOB="$CERT_DIR"/*-certificate.pem.crt
KEY_GLOB="$CERT_DIR"/*-private.pem.key

# RESOLVE CERT FILES (single match expected)
CERT_FILE=$(ls $CERT_GLOB 2>/dev/null | head -n 1 || true)
KEY_FILE=$(ls $KEY_GLOB 2>/dev/null | head -n 1 || true)

# VALIDATION
[ -f "$CA_FILE" ] || { echo "Missing CA file: $CA_FILE" >&2; exit 2; }
[ -n "$CERT_FILE" ] || { echo "Missing certificate file in $CERT_DIR" >&2; exit 3; }
[ -n "$KEY_FILE"  ] || { echo "Missing private key file in $CERT_DIR" >&2; exit 4; }

# DEBUG
echo "Subscribing to topic: $TOPIC"
echo "Press Ctrl+C to stop"
echo

# SUBSCRIBE AND DISCOVER (Ctrl+C to stop)
mosquitto_sub \
  -h "$ENDPOINT" \
  -p 8883 \
  --cafile "$CA_FILE" \
  --cert  "$CERT_FILE" \
  --key   "$KEY_FILE" \
  -q 0 \
  -t "$TOPIC" \
  -v \
| awk '
{
  topic = $1
  n = split(topic, p, "/")

  j = p[n-1]   # Jx
  s = p[n]     # sensor-y
  key = j "/" s

  if (!(key in seen)) {
    seen[key] = 1
    count[j]++
    list[j] = list[j] " " s
    printf("Discovered %s %s\n", j, s)
  }
}
END {
  print "\nSummary:"
  for (j in count) {
    printf("  %s: %d sensors ->%s\n", j, count[j], list[j])
  }
}'
