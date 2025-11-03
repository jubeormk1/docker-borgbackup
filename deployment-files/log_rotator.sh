#!/bin/bash

while true; do
    # Rotate command logs if they get too large
    find /var/log/commands -name "*.log" -size +10M -exec mv {} {}.$(date +%Y%m%d_%H%M%S) \; -exec echo "" > {} \;

    # Compress old logs
    find /var/log -name "*.log.*" -mtime +1 -exec gzip {} \;

    # Sleep for an hour before next check
    sleep 3600
done
