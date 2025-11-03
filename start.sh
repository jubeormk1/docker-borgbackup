#!/bin/bash

# Set up comprehensive logging
setup_logging() {
    echo "=== Initializing Comprehensive Monitoring System ==="
    
    # Create log directories if they don't exist
    mkdir -p /var/log/ssh
    mkdir -p /var/log/commands
    mkdir -p /var/log/network
    mkdir -p /var/log/sessions
    
    # Set proper permissions
    chown -R backupuser:backupuser /var/log
    chmod 755 /var/log/commands
    chmod 755 /var/log/network
    
    echo "$(date): Logging directories initialized" >> /var/log/ssh/startup.log
}

# Set up SSH key from environment variable
setup_ssh_key() {
    if [ -n "$SSH_PUBLIC_KEY" ]; then
        echo "Configuring SSH public key from environment variable..."
        mkdir -p /data/.ssh
        echo "$SSH_PUBLIC_KEY" > /data/.ssh/authorized_keys
        chmod 700 /data/.ssh
        chmod 600 /data/.ssh/authorized_keys
        chown -R backupuser:backupuser /data/.ssh
        echo "$(date): SSH public key configured from environment" >> /var/log/ssh/startup.log
        echo "SSH key configured successfully"
    else
        echo "WARNING: No SSH_PUBLIC_KEY environment variable set!" >> /var/log/ssh/startup.log
    fi
}

# Link data volume
setup_data_volume() {
    if [ -d /data/.ssh ]; then
        ln -sf /data/.ssh /home/backupuser/.ssh
        echo "Data volume linked successfully"
    else
        echo "WARNING: /data/.ssh directory not found" >> /var/log/ssh/startup.log
    fi
}

# Start network traffic capture
start_network_monitoring() {
    echo "Starting network traffic capture..."
    
    # Start packet capture for SSH traffic
    tcpdump -i any -G 3600 -w "/var/log/network/ssh_traffic_%Y%m%d_%H%M%S.pcap" port 22 &
    
    # Log network connections
    bash -c 'while true; do 
        echo "=== Network Connections - $(date) ===" >> /var/log/network/connections.log
        netstat -tunap | grep -E "(ssh|:22)" >> /var/log/network/connections.log
        sleep 30
    done' &
    
    echo "$(date): Network monitoring started" >> /var/log/ssh/startup.log
    echo "Network monitoring active"
}

# Start process monitoring
start_process_monitoring() {
    echo "Starting process monitoring..."
    
    # Monitor process creation and execution
    bash -c 'while true; do
        echo "=== Active Processes - $(date) ===" >> /var/log/sessions/process_monitor.log
        ps aux >> /var/log/sessions/process_monitor.log
        echo "=== Open Files ===" >> /var/log/sessions/process_monitor.log
        lsof -i :22 >> /var/log/sessions/process_monitor.log 2>/dev/null
        sleep 60
    done' &
    
    echo "$(date): Process monitoring started" >> /var/log/ssh/startup.log
    echo "Process monitoring active"
}

# Start real-time command monitoring
start_command_monitoring() {
    echo "Starting real-time command analysis..."
    
    # Start the log rotator
    /usr/local/bin/log_rotator.sh &
    
    # Start real-time command analyzer
    bash -c '
    tail -f /var/log/commands/all_commands.log | while read line; do
        timestamp=$(date "+%Y-%m-%d %H:%M:%S")
        echo "[REALTIME] $timestamp - $line"
        
        # Detect suspicious patterns
        if echo "$line" | grep -q -E "(rm.*-rf|chmod.*777|wget.*http|curl.*http|/bin/sh|/bin/bash|\.\./|/etc/passwd|/etc/shadow)"; then
            echo "🚨 ALERT: SUSPICIOUS COMMAND DETECTED - $line" >> /var/log/commands/security_alerts.log
            echo "🚨 ALERT: SUSPICIOUS COMMAND DETECTED - $line"
        fi
        
        # Detect rapid command execution (potential automation)
        echo "$(date +%s):$line" >> /var/log/commands/timing.log
    done' &
    
    echo "$(date): Real-time command monitoring started" >> /var/log/ssh/startup.log
    echo "Real-time command monitoring active"
}

# Start session logging and analysis
start_session_monitoring() {
    echo "Starting session tracking..."
    
    # Log active sessions periodically
    bash -c 'while true; do
        echo "=== Active Sessions - $(date) ===" >> /var/log/sessions/active_sessions.log
        who >> /var/log/sessions/active_sessions.log
        echo "=== SSH Connections ===" >> /var/log/sessions/active_sessions.log
        netstat -tunap | grep :22 >> /var/log/sessions/active_sessions.log
        echo "=== System Load ===" >> /var/log/sessions/active_sessions.log
        uptime >> /var/log/sessions/active_sessions.log
        sleep 60
    done' &
    
    echo "$(date): Session monitoring started" >> /var/log/ssh/startup.log
}

# Set up data directory permissions
setup_data_permissions() {
    echo "Setting up data directory permissions..."
    
    # Ensure /data exists and has correct permissions
    mkdir -p /data
    chown backupuser:backupuser /data
    chmod 755 /data
    
    # Create .ssh directory if it doesn't exist
    mkdir -p /data/.ssh
    chown backupuser:backupuser /data/.ssh
    chmod 700 /data/.ssh
    
    echo "$(date): Data directory permissions configured" >> /var/log/ssh/startup.log
}

# Display startup banner and status
show_startup_status() {
    echo ""
    echo "=== Backup Server with Comprehensive Monitoring ==="
    echo "Startup Time: $(date)"
    echo "Logging Locations:"
    echo "  - Commands: /var/log/commands/"
    echo "  - SSH: /var/log/ssh/"
    echo "  - Network: /var/log/network/"
    echo "  - Sessions: /var/log/sessions/"
    echo ""
    echo "Monitoring Features:"
    echo "  [x] Real-time command logging"
    echo "  [x] Suspicious pattern detection"
    echo "  [x] Network traffic capture"
    echo "  [x] Process monitoring"
    echo "  [x] Session tracking"
    echo "  [x] Automatic log rotation"
    echo ""
    echo "Starting SSH server..."
    echo "================================================"
}



# Main execution
main() {
    # Initialize all systems
    setup_logging
    setup_ssh_key
    setup_data_permissions
    setup_data_volume
    start_network_monitoring
    start_process_monitoring
    start_command_monitoring
    start_session_monitoring
    show_startup_status
    
    # Log final startup message
    echo "$(date): All monitoring systems initialized, starting SSH server" >> /var/log/ssh/startup.log
    
    # Start SSH server with maximum logging
   exec /usr/sbin/sshd -D -e -f /etc/ssh/sshd_config
    # while true; do sleep 1000; done # Placeholder to keep container running
}

# Capture any errors
trap 'echo "ERROR: Startup script failed at line $LINENO" >> /var/log/ssh/startup.log; exit 1' ERR

# Run main function
main "$@"