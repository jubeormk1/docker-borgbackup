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
