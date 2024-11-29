#!/bin/bash

# Check if sshpass is installed
if ! command -v sshpass &> /dev/null; then
    echo "sshpass could not be found. Please install sshpass to use this script."
    exit 1
fi

# Check for the correct number of arguments
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <Last Number of IP Address>"
    exit 1
fi

# Assign the first argument to a variable
last_octet="$1"

# Validate the last octet
if ! [[ "$last_octet" =~ ^[0-9]+$ ]] || [ "$last_octet" -lt 0 ] || [ "$last_octet" -gt 255 ]; then
    echo "Invalid IP address octet: $last_octet. Must be between 0 and 255."
    exit 1
fi

# Define the IP address prefix and your password
ip_prefix="192.168.1"
your_password="nvidia" # It's strongly recommended to handle passwords more securely

# SSH into the device using sshpass
sshpass -p "$your_password" ssh nvidia@"$ip_prefix.$last_octet"

