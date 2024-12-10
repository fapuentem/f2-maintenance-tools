#!/bin/bash

# Extract MAC address from 'ifconfig' command's output
mac_address=$(ifconfig eth2 | grep 'ether' | awk '{print $2}')

# Replace ':' with nothing to get the required format
formatted_mac_address=$(echo $mac_address | tr -d ':')

# Add 'f2_' prefix to the MAC address
result="f2_$formatted_mac_address"

echo $result
