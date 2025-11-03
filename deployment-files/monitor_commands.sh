#!/bin/bash
echo "Starting real-time command monitoring..."
tail -f /var/log/commands/all_commands.log | while read line; do
    echo "[$(date "+%H:%M:%S")] $line"
    if echo "$line" | grep -q -E "(rm.*-rf|chmod.*777|wget.*http|curl.*http|/bin/sh|/bin/bash|\.\./|/etc/passwd|/etc/shadow)"; then
        echo "SUSPICIOUS ACTIVITY DETECTED: $line"
        echo "ALERT: $(date) - $line" >> /var/log/commands/security_alerts.log
    fi
done
