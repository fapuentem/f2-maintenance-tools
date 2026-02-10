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

# Normalize connector (J1, J2, etc.)
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
CERT_FILE_GLOB="$CERT_DIR"/*-certificate.pem.crt
KEY_FILE_GLOB="$CERT_DIR"/*-private.pem.key

# Resolve globs to concrete files
CERT_FILE=$(ls $CERT_FILE_GLOB 2>/dev/null | head -n 1)
KEY_FILE=$(ls $KEY_FILE_GLOB 2>/dev/null | head -n 1)

# -------------------------
# VALIDATION
# -------------------------
[ -f "$CA_FILE" ] || { echo "Missing CA file"; exit 2; }
[ -f "$CERT_FILE" ] || { echo "Missing certificate file"; exit 3; }
[ -f "$KEY_FILE" ]  || { echo "Missing private key file"; exit 4; }

# -------------------------
# DEBUG INFO
# -------------------------
echo "Subscribe topic: $SUB_TOPIC"
echo "Publish topic : $PUB_TOPIC"
echo
echo "Waiting for messages. Press Ctrl+C to stop"
echo

# -------------------------
# START SUBSCRIBER (BACKGROUND)
# -------------------------
mosquitto_sub \
  -h "$ENDPOINT" \
  -p 8883 \
  --cafile "$CA_FILE" \
  --cert  "$CERT_FILE" \
  --key   "$KEY_FILE" \
  -q 0 \
  -t "$SUB_TOPIC" \
  -v &
SUB_PID=$!

# Ensure subscriber is killed on exit
cleanup() {
  kill "$SUB_PID" 2>/dev/null || true
}
trap cleanup EXIT

# Give the subscriber a moment to connect
sleep 1

# -------------------------
# PUBLISH COMMAND
# -------------------------
mosquitto_pub \
  -h "$ENDPOINT" \
  -p 8883 \
  --cafile "$CA_FILE" \
  --cert  "$CERT_FILE" \
  --key   "$KEY_FILE" \
  -q 0 \
  -t "$PUB_TOPIC" \
  -n

# -------------------------
# WAIT (subscriber keeps running)
# -------------------------
wait "$SUB_PID"
