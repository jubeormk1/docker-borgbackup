#!/bin/bash

# Load config
source ./config.sh

username=$1

if [ -z "$username" ]; then
    echo "Usage: ./remove-user.sh <username>"
    exit 1
fi

if [ ! -d "../users/$username" ]; then
    echo "User $username not found"
    exit 1
fi

user_volumes="$BASE_FOLDER/$username"

echo "Removing user: $username"
echo "Removing config: ../users/$username"
echo "Removing volumes: $user_volumes"

# Stop and remove container
cd "../users/$username" && docker compose down

# Remove user config and volumes
cd ..
rm -rf "$username"
rm -rf "$user_volumes"

echo "[X] User $username completely removed"