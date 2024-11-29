#!/bin/bash

# Check if jq is installed
if ! command -v jq &> /dev/null
then
    echo "jq could not be found. Please install jq to use this script."
    exit 1
fi

# Check for the correct number of arguments
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <Connector (J1, J2, J3, J4)>"
    exit 1
fi

# Assign the first argument to a meaningful variable name
connector="$1"

# Define the path to the config.json file
config_file="/home/nvidia/projects/F2-App/config/config.json" # Update this path to the actual config.json file location

# Validate connector input
if [[ ! $connector =~ ^(J1|J2|J3|J4)$ ]]; then
    echo "Invalid connector. Please choose from J1, J2, J3, or J4."
    exit 1
fi

# Use jq to extract the mode for the specified connector from the config file
mode=$(jq -r --arg connector "$connector" '.Connectors[$connector].mode' "$config_file")

# Check if the mode was found
if [ -z "$mode" ]; then
    echo "Mode for $connector could not be found."
    exit 1
fi

# Print the mode
echo "Mode for $connector: $mode"
