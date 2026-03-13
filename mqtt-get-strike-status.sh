#!/usr/bin/env bash
set -euo pipefail

# Arguments
if [ $# -ne 1 ]; then
  echo "Usage: $0 <mac>"
  exit 1
fi

MAC="$1"

# Topic
SUB_TOPIC="stat/f2-${MAC}/access-control-mode/+/+"

# AWS settings
ENDPOINT="a35lkm5jyds64h-ats.iot.us-east-1.amazonaws.com"

CERT_DIR="$HOME/projects/F2-App/certs"

CA_FILE="$CERT_DIR/AmazonRootCA1.pem"
CERT_FILE=$(ls "$CERT_DIR"/*-certificate.pem.crt 2>/dev/null | head -n1 || true)
KEY_FILE=$(ls "$CERT_DIR"/*-private.pem.key 2>/dev/null | head -n1 || true)

# Validation
[ -f "$CA_FILE" ] || { echo "Missing CA file"; exit 2; }
[ -f "$CERT_FILE" ] || { echo "Missing certificate file"; exit 3; }
[ -f "$KEY_FILE" ]  || { echo "Missing private key file"; exit 4; }

echo "Subscribe topic: $SUB_TOPIC"
echo

# Start subscriber
mosquitto_sub \
  -h "$ENDPOINT" \
  -p 8883 \
  --cafile "$CA_FILE" \
  --cert "$CERT_FILE" \
  --key "$KEY_FILE" \
  -q 0 \
  -t "$SUB_TOPIC" \
  -v &

SUB_PID=$!

sleep 1

# Publish topic
for J in J1 J2 J3 J4; do
  for S in 1 2; do

    PUB_TOPIC="cmnd/f2-${MAC}/access-control-mode/${J}/strike-${S}"

    mosquitto_pub \
      -h "$ENDPOINT" \
      -p 8883 \
      --cafile "$CA_FILE" \
      --cert "$CERT_FILE" \
      --key "$KEY_FILE" \
      -q 0 \
      -t "$PUB_TOPIC" \
      -n

    sleep 1

  done
done

wait $SUB_PID
