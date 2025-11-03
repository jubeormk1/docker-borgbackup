#!/bin/bash

# Load config
source ./config.sh

echo "Borg Backup Users:"
echo "====================="
echo "Base Folder: $BASE_FOLDER"
echo ""

for user in ../users/*/; do
    if [ -d "$user" ] && [ -f "$user/compose.yaml" ]; then
        username=$(basename "$user")
        port=$(grep "ports" "$user/compose.yaml" | grep -o '[0-9]*:22' | cut -d: -f1)
        container_name="backup-server-$username"
        volume_path="$BASE_FOLDER/$username"
        
        # Check if running
        if docker ps --format "table {{.Names}}" | grep -q "$container_name"; then
            status="[x] RUNNING"
        else
            status="[ ] STOPPED"
        fi
        
        echo "$status $username"
        echo "   Port: $port"
        echo "   Container: $container_name"
        echo "   Volumes: $volume_path"
        echo ""
    fi
done