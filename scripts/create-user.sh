#!/bin/bash

# Load config
source ./config.sh

# Get user info
read -p "Username: " username
read -p "SSH Public Key: " ssh_key
read -p "SSH Port (default: 2222): " port
port=${port:-2222}

# Create user folder
mkdir -p "../users/$username"
cd "../users/$username"

# Create volume paths
user_volumes="$BASE_FOLDER/$username"
mkdir -p "$user_volumes/backup_data"
mkdir -p "$user_volumes/logs/ssh"
mkdir -p "$user_volumes/logs/commands" 
mkdir -p "$user_volumes/logs/network"
mkdir -p "$user_volumes/logs/sessions"

# Create compose file
cat > compose.yaml << EOF
services:
  backup-server-$username:
    build: ../..
    environment:
      - SSH_PUBLIC_KEY=$ssh_key
      - SSH_PORT=$port
    ports:
      - "$port:22"
    volumes:
      - $user_volumes/backup_data:/data
      - $user_volumes/logs/ssh:/var/log/ssh
      - $user_volumes/logs/commands:/var/log/commands
      - $user_volumes/logs/network:/var/log/network
      - $user_volumes/logs/sessions:/var/log/sessions
    cap_add:
      - NET_RAW
    security_opt:
      - no-new-privileges:true
    restart: unless-stopped
    read_only: true
    tmpfs:
      - /tmp
      - /run
      - /var/run
EOF

echo "Created user: $username"
echo "Port: $port"
echo "Config: users/$username"
echo "Volumes: $user_volumes/"
echo ""
echo "To start: cd users/$username && docker compose up -d"
echo "To connect: ssh -p $port backupuser@localhost -- --version"