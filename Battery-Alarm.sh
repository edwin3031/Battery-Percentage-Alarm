#!/bin/bash

# Function to show notification
show_notification() {
    local msg="$1"
    local icon="$2"
    /usr/bin/notify-send -u low -t "$DURATION" -i "$icon" "$msg"
}

# Function to get battery capacity
get_battery_capacity() {
    local capacity_file
    capacity_file=$(find /sys/class/power_supply/BAT0/ -name 'capacity' | head -n 1)
    if [ -n "$capacity_file" ]; then
        cat "$capacity_file"
    else
        echo "Error: Battery capacity file could not be found." >&2
        exit 1
    fi
}

# Function to get battery status
get_battery_status() {
    local status_file
    status_file=$(find /sys/class/power_supply/BAT0/ -name 'status' | head -n 1)
    if [ -n "$status_file" ]; then
        cat "$status_file"
    else
        echo "Error: Battery status file could not be found.." >&2
        exit 1
    fi
}

# Function to check if the battery is charging
is_battery_charging() {
    local charging=$(cat /sys/class/power_supply/BAT0/status)
    if [[ $charging == "Charging" ]]; then
        return 0
    else
        return 1
    fi
}