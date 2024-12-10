#!/bin/bash

# Check if jq is installed
if ! command -v jq &> /dev/null
then
    echo "jq could not be found. Please install jq to use this script."
    exit 1
fi

# Check for correct number of arguments
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <Connector (J1, J2, J3, J4)> <Mode ('access-control-mode', 'alarm-mode', 'sensor-mode')>"
    exit 1
fi

# Assign the first and second argument to meaningful variable names
connector="$1"
mode="$2"

# Define the path to the config.json file
config_file="/home/nvidia/projects/F2-App/config/config.json" # Update this path to the actual config.json file location

# Validate connector input
if [[ ! $connector =~ ^(J1|J2|J3|J4)$ ]]; then
    echo "Invalid connector. Please choose from J1, J2, J3, or J4."
    exit 1
fi

# Validate mode input
if [[ ! $mode =~ ^(access-control-mode|alarm-mode|sensor-mode)$ ]]; then
    echo "Invalid mode. Please choose from 'access-control-mode', 'alarm-mode', or 'sensor-mode'."
    exit 1
fi

# Use jq to update the mode for the specified connector in the config file
jq --arg connector "$connector" --arg mode "$mode" '.Connectors[$connector].mode = $mode' "$config_file" > temp.json && mv temp.json "$config_file"

echo "Configuration updated successfully."
