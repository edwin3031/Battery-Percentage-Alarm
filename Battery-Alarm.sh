#!/bin/bash

# Detects the directory where the script is located
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
ICONS_DIR="$SCRIPT_DIR/Icons"

# Threshold settings
BATTERY_LOW_THRESHOLD=20 # Low battery percentage
BATTERY_CRITICAL_THRESHOLD=10 # Critical battery percentage
BATTERY_HIGH_THRESHOLD=95 # High battery percentage
DURATION=10000  # Notification duration (milliseconds)
MIN_INTERVAL=60  # Minimum interval between notifications (seconds)

# Initialization of the last occurrence of the notification
last_notification_time=0

# Function to send notifications
show_notification() {
    local msg="$1"
    local icon="$2"
    notify-send -u critical -t "$DURATION" -i "$icon" "$msg"
}

# Function to determine the battery directory
get_battery_directory() {
    if [ -d "/sys/class/power_supply/BAT0" ]; then
        echo "/sys/class/power_supply/BAT0"
    elif [ -d "/sys/class/power_supply/BAT1" ]; then
        echo "/sys/class/power_supply/BAT1"
    else
        show_notification "Error: No BAT0 or BAT1 battery directory found in your operating system." "$ICONS_DIR/error_icon.png"
        exit 1
    fi
}

# Get the battery directory
BATTERY_DIR=$(get_battery_directory)

# Function to get the battery capacity
get_battery_capacity() {
    cat "$BATTERY_DIR/capacity"
}

# Function to get the battery status
get_battery_status() {
    cat "$BATTERY_DIR/status"
}

# Battery status check
check_battery_status() {
    local battery_capacity
    local battery_status

    battery_capacity=$(get_battery_capacity)
    battery_status=$(get_battery_status)

    if [[ $battery_status == "Discharging" && $battery_capacity -lt $BATTERY_CRITICAL_THRESHOLD ]]; then
        show_notification "Warning! Battery is about to run out (${battery_capacity}%)." "$ICONS_DIR/battery_empty_icon.png"
    elif [[ $battery_status == "Discharging" && $battery_capacity -lt $BATTERY_LOW_THRESHOLD ]]; then
        show_notification "Connect your charger. Battery low at (${battery_capacity}%)." "$ICONS_DIR/battery_low_icon.png"
    elif [[ $battery_status == "Charging" && $battery_capacity -gt $BATTERY_HIGH_THRESHOLD ]]; then
        show_notification "Disconnect the charger. Battery at ${battery_capacity}%." "$ICONS_DIR/charging_battery_icon.png"
    fi
}

# Continuous battery status check loop
while true; do
    current_time=$(date +%s)
    time_since_last_notification=$((current_time - last_notification_time))

    if [[ $time_since_last_notification -ge $MIN_INTERVAL ]]; then
        check_battery_status
        last_notification_time=$current_time
    fi

    sleep 10
done