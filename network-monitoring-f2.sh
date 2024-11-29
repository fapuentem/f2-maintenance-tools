#!/bin/bash

# AWS IoT Core Details
# TOPIC="stat/f2-/"
# CERT_PATH="PATH_TO_CERTIFICATE"
# PRIVATE_KEY_PATH ="PATH_TO_PRIVATE_KEY"
# CA_PATH="PATH_TO_CA_FILE"

CA_PATH='/etc/f2-smart-controller/AmazonRootCA1.pem'
CERT_PATH='/etc/f2-smart-controller/*-certificate.pem.crt'
PRIVATE_KEY_PATH='/etc/f2-smart-controller/*-private.pem.key'

ENDPOINT='a35lkm5jyds64h-ats.iot.us-east-1.amazonaws.com'

# Extract MAC address from 'ifconfig' command's output
mac_address=$(ip link show | grep 'link/ether' | awk '{print $2}' | head -n 2 | tail -1) #$(ifconfig eth0 | grep 'ether' | awk '{print $2}')
echo "Raw MAC Address: $mac_address"

# Replace ':' with nothing to get the required format
formatted_mac_address=$(echo $mac_address | tr -d ':')
echo "Formatted MAC Address: $formatted_mac_address"

# Add 'f2_' prefix to the MAC address
TOPIC="stat/f2-$formatted_mac_address/network"

echo $TOPIC

# Function to check connectivity and publish to AWS IoT Core
publish_connectivity() {
    INTERFACE=$1
    IP=$(ip addr show $INTERFACE | grep 'inet ' | awk '{print $2}' | cut -d/ -f1)

    if [ -z "$IP" ]; then
        STATUS="DOWN"
        SPEED="N/A"
    else
        STATUS="UP"
        # Run speedtest and extract download and upload speed
        SPEED=$(speedtest --secure --simple | awk '{print $2 $3}' | tr '\n' ' ' | awk '{print "Download: " $2 ", Upload: " $3}')
    fi

    # Construct JSON payload
    PAYLOAD="{\"interface\":\"$INTERFACE\",\"status\":\"$STATUS\",\"ip\":\"$IP\",\"speed\":\"$SPEED\"}"

    # Publish to AWS IoT Core
    mosquitto_pub --cafile $CA_PATH --cert $CERT_PATH --key $PRIVATE_KEY_PATH -h $ENDPOINT -p 8883 -q 1 -t $TOPIC -m "$PAYLOAD" --tls-version tlsv1.2
}

# Check and publish connectivity for eth0 and wlan0
publish_connectivity eth0
publish_connectivity wlan0
