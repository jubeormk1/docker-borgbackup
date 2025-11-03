#!/bin/bash
# Log every command executed via SSH
echo "$(date "+%Y-%m-%d %H:%M:%S") | User: $USER | Client: $SSH_CLIENT | Command: $SSH_ORIGINAL_COMMAND" >> /var/log/commands/all_commands.log

# Also log to user-specific file
echo "$(date "+%Y-%m-%d %H:%M:%S") | Client: $SSH_CLIENT | Command: $SSH_ORIGINAL_COMMAND" >> /var/log/commands/user_${USER}.log

# If no command provided, show help
if [ -z "$SSH_ORIGINAL_COMMAND" ]; then
    echo "Backup Server - Available Services"
    echo "==================================="
    echo "Borg Backup: ssh user@host -- borg <command>"
    echo "Rsync: ssh user@host -- rsync <options>"
    echo ""
    echo "Examples:"
    echo "  Borg:  ssh user@host -- borg --version"
    echo "  Rsync: ssh user@host -- rsync -av /local/path/ /data/backup/"
    exit 0
fi

# Parse the command
case "$SSH_ORIGINAL_COMMAND" in
    borg*)
        # Remove 'borg' prefix and execute borg
        command="${SSH_ORIGINAL_COMMAND#borg }"
        exec /usr/bin/borg $command
        ;;
    rsync*)
        # Remove 'rsync' prefix and execute rsync
        command="${SSH_ORIGINAL_COMMAND#rsync }"
        exec /usr/bin/rsync $command
        ;;
    *)
        echo "Error: Unknown command. Use 'borg' or 'rsync' prefix."
        echo "Example: ssh user@host -- borg --version"
        echo "Example: ssh user@host -- rsync --version"
        exit 1
        ;;
esac