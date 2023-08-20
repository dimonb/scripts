#!/bin/bash

TEMP_THRESHOLD=40
FAN_SPEED_THRESHOLD=500
ALERT_FLAG=0

# Function to send an alert and set the flag
alert() {
    local message="$1"
    echo "$message"
    logger -p alert "$message"
    ALERT_FLAG=1
}

# Function to check temperature values
check_temperature() {
    local name="$1"
    local value="$2"
    local threshold="$3"

    if (( $(echo "$value >= $threshold" | bc -l) )); then
        alert "$name temperature is $value°C which is above the threshold of $threshold°C"
    fi
}

# Function to check fan speed values
check_fan() {
    local name="$1"
    local value="$2"
    local threshold="$3"

    if (( value < threshold )); then
        alert "$name speed is $value RPM which is below the threshold of $threshold RPM"
    fi
}

# General function to loop through and check values
check_values() {
    local values="$1"
    local threshold="$2"
    local type="$3"

    IFS=$'\n'  # Set Internal Field Separator to newline for the loop
    for entry in $values; do
        NAME=$(echo $entry | cut -d',' -f1)
        VALUE=$(echo $entry | cut -d',' -f2)

        check_$type "$NAME" "$VALUE" "$threshold"
    done
    unset IFS
}

# Get and check temperatures
TEMPERATURES=$(sensors | grep '°C' | awk -F: '{gsub(/[+°C ]| \([^)]+\)/, "", $2); print $1 "," $2}')
check_values "$TEMPERATURES" "$TEMP_THRESHOLD" "temperature"

# Get and check fan speeds
FAN_SPEEDS=$(sensors | grep 'RPM' | awk -F: '{gsub(/[ RPM]/, "", $2); print $1 "," $2}')
check_values "$FAN_SPEEDS" "$FAN_SPEED_THRESHOLD" "fan"

exit $ALERT_FLAG
