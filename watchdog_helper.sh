#!/bin/bash

# Service name for logging
SERVICE_NAME="watchdog_helper"

# Destination to ping
PING_DESTINATION="1.1.1.1"

# File marker for storing timestamp when ping fails
MARKER_FILE="/tmp/ping_failed_marker"

# Reboot timeout after the ping has failed (15 minutes = 900 seconds)
PING_FAIL_TIMEOUT=900

# No action timeout after a reboot (1 hour = 3600 seconds)
REBOOT_GRACE_PERIOD=3600

# Log function to syslog
log_to_syslog() {
    local level="$1"
    local message="$2"
    logger -t "${SERVICE_NAME}[$$]" -p "user.${level}" "$message"
}

# Check if the ping fails
ping_failed() {
    ! ping -c 1 "$PING_DESTINATION" &> /dev/null
}

# Calculate the elapsed time since the marker file was touched
elapsed_time_since_marker() {
    local current_time=$(date +%s)
    local marker_time=$(date +%s -r "$MARKER_FILE")
    echo $((current_time - marker_time))
}

# Main logic starts here

if ping_failed; then
    # If the system has rebooted within the last hour, we don't take any action even if the ping fails.
    if [[ "$(uptime -s)" > "$(date -d "now - $REBOOT_GRACE_PERIOD seconds" +"%Y-%m-%d %H:%M:%S")" ]]; then
        exit 0
    fi
    
    if [[ ! -f "$MARKER_FILE" ]]; then
        touch "$MARKER_FILE"
        log_to_syslog "info" "Ping to ${PING_DESTINATION} failed. Marking the timestamp."
    else
        elapsed_time=$(elapsed_time_since_marker)
        if [[ "$elapsed_time" -gt "$PING_FAIL_TIMEOUT" ]]; then
            log_to_syslog "err" "Ping to ${PING_DESTINATION} failed for more than ${PING_FAIL_TIMEOUT} seconds. System will reboot soon."
            log_to_syslog "info" "Uptime: $(uptime)"
            # We're depending on the watchdog timer, so we exit with an error code.
            exit 1
        fi
    fi
else
    if [[ -f "$MARKER_FILE" ]]; then
        elapsed_time=$(elapsed_time_since_marker)
        # If the ping is restored within the grace period, we reset the marker.
        if [[ "$elapsed_time" -lt "$PING_FAIL_TIMEOUT" ]]; then
            rm -f "$MARKER_FILE"
            log_to_syslog "info" "Ping to ${PING_DESTINATION} restored. Resetting the timestamp."
        fi
    fi
fi
