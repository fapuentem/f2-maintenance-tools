#!/usr/bin/env bash
set -e

# ARGUMENTS
if [ $# -ne 3 ]; then
  echo "Usage: $0 <mac> <connector Jx> <strike>"
  exit 1
fi

MAC="$1"
CONNECTOR_RAW="$2"
STRIKE="$3"

# NORMALIZE CONNECTOR
CONNECTOR="${CONNECTOR_RAW^^}"

# BUILD TOPIC
TOPIC="cmnd/f2-${MAC}/access-control-mode/${CONNECTOR}/strike-${STRIKE}"

# AWS SETTINGS
ENDPOINT="a35lkm5jyds64h-ats.iot.us-east-1.amazonaws.com"

# CERT DIR
CERT_DIR="$HOME/projects/F2-App/certs"

CA_FILE="$CERT_DIR/AmazonRootCA1.pem"
CERT_FILE="$CERT_DIR"/*-certificate.pem.crt
KEY_FILE="$CERT_DIR"/*-private.pem.key

# VALIDATION
[ -f "$CA_FILE" ] || { echo "Missing CA file"; exit 2; }
ls $CERT_FILE >/dev/null 2>&1 || { echo "Missing certificate file"; exit 3; }
ls $KEY_FILE  >/dev/null 2>&1 || { echo "Missing private key file"; exit 4; }

# DEBUG
echo "Publishing to topic: $TOPIC"

# PUBLISH EMPTY MESSAGE
mosquitto_pub \
  -h "$ENDPOINT" \
  -p 8883 \
  --cafile "$CA_FILE" \
  --cert  $CERT_FILE \
  --key   $KEY_FILE \
  -q 0 \
  -t "$TOPIC" \
  -n
