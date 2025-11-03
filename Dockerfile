FROM alpine:latest

# Install required packages + monitoring tools (CORRECTED)
RUN apk add --no-cache \
    openssh-server \
    borgbackup \
    shadow \
    sudo \
    tcpdump \
    strace \
    lsof \
    net-tools \
    bash \
    coreutils \
    findutils \
    grep \
    procps

# Create dedicated backup user with restricted access. Folder permissions will be set later on start.sh
RUN adduser -D -s /bin/bash -h /data backupuser && \
    usermod -p '*' backupuser && \
    mkdir -p /data && \
    chmod 755 /data


# Configure SSH server
RUN mkdir -p /run/sshd && \
    ssh-keygen -A

# Create comprehensive logging directory structure
RUN mkdir -p /var/log/ssh && \
    mkdir -p /var/log/commands && \
    mkdir -p /var/log/network && \
    mkdir -p /var/log/sessions && \
    chown -R backupuser:backupuser /var/log

# Install and configure monitoring wrapper scripts
RUN cat > /usr/local/bin/borg_wrapper.sh << 'EOF'
#!/bin/bash
# Log every command executed via SSH
echo "$(date "+%Y-%m-%d %H:%M:%S") | User: $USER | Client: $SSH_CLIENT | Command: $SSH_ORIGINAL_COMMAND" >> /var/log/commands/all_commands.log

# Also log to user-specific file
echo "$(date "+%Y-%m-%d %H:%M:%S") | Client: $SSH_CLIENT | Command: $SSH_ORIGINAL_COMMAND" >> /var/log/commands/user_${USER}.log

# If no command provided, show help
if [ -z "$SSH_ORIGINAL_COMMAND" ]; then
    echo "Borg Backup Server"
    echo "Usage: ssh backupuser@host -- <borg-command>"
    echo "Example: ssh backupuser@host -- --version"
    echo "Example: ssh backupuser@host -- init /data/my-repo"
    exec /usr/bin/borg --help
else
    # Execute the original borg command
    exec /usr/bin/borg $SSH_ORIGINAL_COMMAND
fi
EOF

RUN chmod +x /usr/local/bin/borg_wrapper.sh

# Create log rotation script

RUN cat > /usr/local/bin/log_rotator.sh << 'EOF'
#!/bin/bash

while true; do
    # Rotate command logs if they get too large
    find /var/log/commands -name "*.log" -size +10M -exec mv {} {}.$(date +%Y%m%d_%H%M%S) \; -exec echo "" > {} \;

    # Compress old logs
    find /var/log -name "*.log.*" -mtime +1 -exec gzip {} \;

    # Sleep for an hour before next check
    sleep 3600
done
EOF

RUN chmod +x /usr/local/bin/log_rotator.sh

# Create real-time monitor script

RUN cat > /usr/local/bin/monitor_commands.sh << 'EOF'
#!/bin/bash
echo "Starting real-time command monitoring..."
tail -f /var/log/commands/all_commands.log | while read line; do
    echo "[$(date "+%H:%M:%S")] $line"
    if echo "$line" | grep -q -E "(rm.*-rf|chmod.*777|wget.*http|curl.*http|/bin/sh|/bin/bash|\.\./|/etc/passwd|/etc/shadow)"; then
        echo "SUSPICIOUS ACTIVITY DETECTED: $line"
        echo "ALERT: $(date) - $line" >> /var/log/commands/security_alerts.log
    fi
done

EOF

RUN chmod +x /usr/local/bin/monitor_commands.sh


# Remove any existing SSH config and create our secure config
RUN rm -f /etc/ssh/sshd_config /etc/ssh/sshd_config.d/* 2>/dev/null || true


# RUN mkdir -p /usr/local/ssh

RUN cat > /etc/ssh/sshd_config << 'EOF'
Port 22
PermitRootLogin no
PasswordAuthentication no
PermitEmptyPasswords no
ChallengeResponseAuthentication no
AllowUsers backupuser
StrictModes no
X11Forwarding no
AllowTcpForwarding no
AllowAgentForwarding no
PermitTTY no
PrintMotd no
Protocol 2
LogLevel VERBOSE
Subsystem sftp internal-sftp
SyslogFacility AUTH
LogLevel DEBUG3


# Only apply ForceCommand and Chroot to the backupuser
Match User backupuser
    # ChrootDirectory /data
    AllowTCPForwarding no
    X11Forwarding no
    ForceCommand /usr/local/bin/borg_wrapper.sh
EOF


# Copy the enhanced startup script
COPY start.sh /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/start.sh

EXPOSE 22

CMD ["/usr/local/bin/start.sh"]