#!/usr/bin/env bash
set -euo pipefail

# -------------------------
# ARGUMENTS
# -------------------------
if [ $# -ne 3 ]; then
  echo "Usage: $0 <mac> <connector Jx> <strike>"
  exit 1
fi

MAC="$1"
CONNECTOR_RAW="$2"
STRIKE="$3"

CONNECTOR="${CONNECTOR_RAW^^}"

# -------------------------
# TOPICS
# -------------------------
SUB_TOPIC="stat/f2-${MAC}/access-control-mode/+/+"
PUB_TOPIC="cmnd/f2-${MAC}/access-control-mode/${CONNECTOR}/strike-${STRIKE}"

# -------------------------
# AWS IOT SETTINGS
# -------------------------
ENDPOINT="a35lkm5jyds64h-ats.iot.us-east-1.amazonaws.com"
CERT_DIR="$HOME/projects/F2-App/certs"

CA_FILE="$CERT_DIR/AmazonRootCA1.pem"
CERT_FILE=$(ls "$CERT_DIR"/*-certificate.pem.crt 2>/dev/null | head -n1 || true)
KEY_FILE=$(ls "$CERT_DIR"/*-private.pem.key 2>/dev/null | head -n1 || true)

# -------------------------
# VALIDATION
# -------------------------
[ -f "$CA_FILE" ] || { echo "Missing CA file"; exit 2; }
[ -f "$CERT_FILE" ] || { echo "Missing certificate file"; exit 3; }
[ -f "$KEY_FILE" ]  || { echo "Missing private key file"; exit 4; }

# -------------------------
# DEBUG
# -------------------------
echo "Subscribe topic: $SUB_TOPIC"
echo "Publish topic : $PUB_TOPIC"
echo
echo "Listening for responses. Press Ctrl+C to stop."
echo

# -------------------------
# PUBLISH AFTER SHORT DELAY (BACKGROUND)
# -------------------------
(
  sleep 1
  mosquitto_pub \
    -h "$ENDPOINT" \
    -p 8883 \
    --cafile "$CA_FILE" \
    --cert  "$CERT_FILE" \
    --key   "$KEY_FILE" \
    -q 0 \
    -t "$PUB_TOPIC" \
    -n
) &

# -------------------------
# SUBSCRIBE (FOREGROUND)
# -------------------------
mosquitto_sub \
  -h "$ENDPOINT" \
  -p 8883 \
  --cafile "$CA_FILE" \
  --cert  "$CERT_FILE" \
  --key   "$KEY_FILE" \
  -q 0 \
  -t "$SUB_TOPIC" \
  -v
