#!/bin/bash

# Detect the path to the directory where the script is located
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

# Icon directory relative to the script directory
ICONS_DIR="$SCRIPT_DIR/Icons"

# Low, critical and high battery percentage
BATTERY_LOW_THRESHOLD=15
BATTERY_CRITICAL_THRESHOLD=5
BATTERY_HIGH_THRESHOLD=95

# Duration of the notification in milliseconds (10 seconds)
DURATION=90000

# Minimum interval between notifications in seconds (1 minute)
MIN_INTERVAL=60

# Memory usage threshold in percent to free up script memory
MEMORY_THRESHOLD=10

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

# Function to release script memory
release_memory() {
    echo "Freeing script memory..."
    
    # Clean large or no longer needed variables
    unset battery_capacity
    unset battery_status
    
    #Clear cache and buffers associated with the script process
    sync; echo 1 > /proc/sys/vm/drop_caches
}

# Loop to continuously check battery and memory status
while true; do
    # Get current time
    current_time=$(date +%s)
    
    # Check if the minimum interval has elapsed since the last notification
    time_since_last_notification=$((current_time - last_notification_time))
    if [ $time_since_last_notification -ge $MIN_INTERVAL ]; then
        # Check battery status
        check_battery_status
        
        # Update the time of the last notification
        last_notification_time=$(date +%s)
    fi
    
     # Get script memory usage in percentage
    memory_usage=$(ps -o %mem -p $$ | awk 'NR==2 {print $1}')

     # If the script memory usage exceeds the threshold, free memory.
    if (( $(echo "$memory_usage >= $MEMORY_THRESHOLD" | bc -l) )); then
        release_memory
    fi
    
    sleep 1
done