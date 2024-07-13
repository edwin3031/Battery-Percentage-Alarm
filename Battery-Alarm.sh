#!/bin/bash

# Detect the path to the directory where the script is located
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

# Icon directory relative to the script directory
ICONS_DIR="$SCRIPT_DIR/Icons"

# Low, critical and high battery percentage
BATTERY_LOW_THRESHOLD=15
BATTERY_CRITICAL_THRESHOLD=5
BATTERY_HIGH_THRESHOLD=95

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

# Function to check the battery status and display the corresponding notification
check_battery_status() {
    local battery_capacity=$(get_battery_capacity)
    local battery_status=$(get_battery_status)
    
    if [[ $battery_status == "Discharging" && $battery_capacity -lt $BATTERY_CRITICAL_THRESHOLD ]]; then
        if ! is_battery_charging; then
            show_notification "Attention! The battery is about to run out! Battery is at $battery_capacity%." "$ICONS_DIR/battery_empty_icon.png"
            last_notification_time=$(date +%s)
            return
        fi
    elif [[ $battery_status == "Discharging" && $battery_capacity -lt $BATTERY_LOW_THRESHOLD ]]; then
        if ! is_battery_charging; then
            show_notification "Get connected! Battery is at $battery_capacity%." "$ICONS_DIR/battery_low_icon.png"
            last_notification_time=$(date +%s)
            return
        fi
    elif [[ $battery_status == "Charging" && $battery_capacity -gt $BATTERY_HIGH_THRESHOLD ]]; then
    if is_battery_charging; then
        show_notification "Disconnect! The battery is at $battery_capacity%. Please disconnect it." "$ICONS_DIR/charging_battery_icon.png"
        last_notification_time=$(date +%s)
    fi
fi
}