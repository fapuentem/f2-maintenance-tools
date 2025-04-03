#!/bin/bash

# Usage: ./download_images.sh <CAMERA_FOLDER> <DATE> <START_HOUR> <END_HOUR> <PASSWORD>
# Example: ./download_images.sh RD-lab-exit 20250320 05 10 mypassword

REMOTE_USER="nvidia"
REMOTE_HOST="192.168.1.236"
REMOTE_BASE_DIR="~/projects/F2_Crowd_Scanning/logs"
LOCAL_BASE_DIR="$HOME/Pictures/Crowd-Scanning"

CAMERA_FOLDER="$1"
DATE="$2"
START_HOUR="$3"
END_HOUR="$4"
PASSWORD="$5"

if [[ -z "$CAMERA_FOLDER" || -z "$DATE" || -z "$START_HOUR" || -z "$END_HOUR" || -z "$PASSWORD" ]]; then
    echo "Usage: $0 <CAMERA_FOLDER> <DATE: YYYYMMDD> <START_HOUR: HH> <END_HOUR: HH> <PASSWORD>"
    exit 1
fi

# Validate hour range
if ! [[ "$START_HOUR" =~ ^[0-9]+$ && "$END_HOUR" =~ ^[0-9]+$ && "$START_HOUR" -le "$END_HOUR" && "$START_HOUR" -ge 0 && "$END_HOUR" -le 23 ]]; then
    echo "Error: Invalid hour range. Must be between 0-23."
    exit 1
fi

# Ensure sshpass is installed
if ! command -v sshpass &> /dev/null; then
    echo "Error: sshpass is required but not installed."
    echo "Install it using: sudo apt install sshpass"
    exit 1
fi

# Define the remote and local paths
REMOTE_DIR="$REMOTE_BASE_DIR/$CAMERA_FOLDER"
LOCAL_DIR="$LOCAL_BASE_DIR/$DATE/$CAMERA_FOLDER"
mkdir -p "$LOCAL_DIR"

# If-then condition to process different hour ranges
if [[ "$START_HOUR" -lt 10 && "$END_HOUR" -lt 10 ]]; then
    echo "Processing hours 00-09..."
    for HOUR in $(seq -f "0%g" "$START_HOUR" "$END_HOUR"); do
        REGEX="${DATE}_${HOUR}[0-5][0-9][0-5][0-9]*"
        # echo $REGEX
        echo "Downloading images from $CAMERA_FOLDER for $DATE during hour $HOUR..."
        sshpass -p "$PASSWORD" scp "$REMOTE_USER@$REMOTE_HOST:$REMOTE_DIR/$REGEX" "$LOCAL_DIR/" 2>/dev/null
    done

elif [[ "$START_HOUR" -ge 10 && "$END_HOUR" -ge 10 ]]; then
    echo "Processing hours 10-23..."
    for HOUR in $(seq -f "%02g" "$START_HOUR" "$END_HOUR"); do
        REGEX="${DATE}_${HOUR}[0-5][0-9][0-5][0-9]*"
        # echo $REGEX
        echo "Downloading images from $CAMERA_FOLDER for $DATE during hour $HOUR..."
        sshpass -p "$PASSWORD" scp "$REMOTE_USER@$REMOTE_HOST:$REMOTE_DIR/$REGEX" "$LOCAL_DIR/" 2>/dev/null
    done

else
    echo "Processing mixed hours from 00-23..."
    for HOUR in $(seq "$START_HOUR" "$END_HOUR"); do
        if [[ "$HOUR" -lt 10 ]]; then
            HOUR="0$HOUR"  # Ensure leading zero for SCP pattern
        fi
        REGEX="${DATE}_${HOUR}[0-5][0-9][0-5][0-9]*"
        # echo $REGEX
        echo "Downloading images from $CAMERA_FOLDER for $DATE during hour $HOUR..."
        sshpass -p "$PASSWORD" scp "$REMOTE_USER@$REMOTE_HOST:$REMOTE_DIR/$REGEX" "$LOCAL_DIR/" 2>/dev/null
    done
fi

echo "Download complete. Files saved in: $LOCAL_DIR"
