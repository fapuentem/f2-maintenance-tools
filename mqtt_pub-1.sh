#!/usr/bin/env bash
set -euo pipefail

# -------------------------
# ARGUMENTS
# -------------------------
if [ $# -ne 4 ]; then
  echo "Usage: $0 <mac> <connector Jx> <strike> <power-flag>"
  echo "Example: $0 48b02df7a37a j3 1 1"
  exit 1
fi

MAC="$1"
CONNECTOR_RAW="$2"
STRIKE="$3"
POWER_FLAG="$4"

# Convert connector to uppercase
CONNECTOR="${CONNECTOR_RAW^^}"

# -------------------------
# BUILD TOPIC
# -------------------------
TOPIC="cmnd/f2-${MAC}/access-control-mode/${CONNECTOR}/strike-${STRIKE}"

# -------------------------
# AWS SETTINGS
# -------------------------
ENDPOINT="a35lkm5jyds64h-ats.iot.us-east-1.amazonaws.com"

# -------------------------
# PAYLOAD
# -------------------------
PAYLOAD="{\"power-flag\": ${POWER_FLAG}}"

# -------------------------
# CERT DIR
# -------------------------
CERT_DIR="/home/nvidia/projects/F2-App/certs"

CA_FILE="$CERT_DIR/AmazonRootCA1.pem"
CERT_FILE=$(find "$CERT_DIR" -name "*-certificate.pem.crt" | head -n1)
KEY_FILE=$(find "$CERT_DIR" -name "*-private.pem.key" | head -n1)

# -------------------------
# VALIDATION
# -------------------------
[ -f "$CA_FILE" ] || { echo "Missing CA file"; exit 2; }
[ -f "$CERT_FILE" ] || { echo "Missing certificate file"; exit 3; }
[ -f "$KEY_FILE" ]  || { echo "Missing private key file"; exit 4; }

# -------------------------
# DEBUG
# -------------------------
echo "Publishing to topic : $TOPIC"
echo "Payload             : $PAYLOAD"
echo

# -------------------------
# PUBLISH MESSAGE
# -------------------------
mosquitto_pub \
  -h "$ENDPOINT" \
  -p 8883 \
  --cafile "$CA_FILE" \
  --cert "$CERT_FILE" \
  --key "$KEY_FILE" \
  -q 0 \
  -t "$TOPIC" \
  -m "$PAYLOAD"
