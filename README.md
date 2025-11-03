# Docker Borg Backup

A secure, containerized Borg Backup server with comprehensive monitoring and SSH access.

**Warning**: Work In Process. Use under your own risk and if you may add an issue.

## Quick Start

### Prerequisites
- Docker and Docker Compose
- SSH key pair for authentication

### Basic Usage

1. **Clone the repo**:
   ```bash
   git clone https://github.com/jubeormk1/docker-borgbackup.git
   cd borg-backup-server
   ```

1. **Clone and configure**:
   ```bash
   cp .env.example .env
   # Edit .env with your SSH public key
   ```

2. **Deploy**:
   ```bash
   docker compose up -d
   ```

3. **Test connection**:
   ```bash
   ssh -p 2222 backupuser@localhost -- --version
   ```

## Project Structure

```
borg-backup-server/
├── compose.yaml            # Main Docker Compose configuration
├── Dockerfile              # Container build instructions
├── start.sh                # Container startup script
├── .env.example            # Environment configuration
├── deployment-files/       # Scripts and config for the container
│   ├── borg-wrapper.sh     # Catches the borg command
│   ├── log_rotator.sh      # Rotate the log files
│   ├── monitor_commands.sh # Monitors the commands sent to the server
│   └── sshd_config.sh      # sshd configuration
└── multi-tenant-scripts/   # Management scripts
   ├── create-user.sh       # Create new user containers
   ├── list-users.sh        # List all users
   ├── remove-user.sh       # Remove user containers
   └── config.sh            # Shared configuration

```

## Multi-User Management

### Create Individual User Containers

```bash
# Create a new user container
./scripts/create-user.sh

# List all users
./scripts/list-users.sh

# Remove a user
./scripts/remove-user.sh username
```

Each user gets:
- Isolated Docker container
- Dedicated SSH port (auto-assigned from 2222+)
- Separate volume storage
- Individual logging and monitoring

### Volume Storage

User data is organized under a base folder (configurable in `scripts/config.sh`):
```
volumes/
├── johndoe/
│   ├── backup_data/     # Borg repositories
│   └── logs/           # Monitoring logs
└── janedoe/
    ├── backup_data/
    └── logs/
```

## Security Features

- **SSH key authentication only** (no passwords)
- **Read-only filesystem** for container security
- **Command restriction** to Borg only via ForceCommand
- **Comprehensive logging** of all activities
- **Network monitoring** with packet capture
- **No privilege escalation** (no-new-privileges)
- **Automatic security alerts** for suspicious commands

## Borg Backup Usage

### Initialize Repository
```bash
ssh -p 2222 backupuser@localhost -- init -e repokey /data/my-repo
```

### Create Backup
```bash
ssh -p 2222 backupuser@localhost -- create --stats /data/my-repo::backup1 ~/documents
```

### List Backups
```bash
ssh -p 2222 backupuser@localhost -- list /data/my-repo
```

### Common Borg Commands
- `--version` - Show Borg version
- `init` - Create new repository
- `create` - Create backup archive
- `list` - List archives in repository
- `info` - Show archive information
- `prune` - Clean up old backups

## Management

### View Logs
```bash
docker compose logs -f
```

### Stop Service
```bash
docker compose down
```

### Update and Rebuild
```bash
docker compose down
docker compose build --no-cache
docker compose up -d
```

## Monitoring

The container includes comprehensive monitoring:
- **Command logging**: All Borg commands with timestamps and source IPs
- **Security alerts**: Automatic detection of suspicious patterns
- **Network capture**: SSH traffic recording
- **Process monitoring**: System activity tracking
- **Session logging**: Connection and user activity

Logs are available in Docker volumes and can be accessed via:
```bash
docker volume inspect borg-backup_ssh_logs
```

## Customization

### Environment Variables (.env)
- `SSH_PUBLIC_KEY`: User's SSH public key for authentication
- `SSH_PORT`: SSH service port (default: 2222)
- `BACKUP_DATA_PATH`: Backup storage path

### Multi-User Base Folder
Edit `scripts/config.sh` to change where user volumes are stored:
```bash
BASE_FOLDER="/mnt/backup_storage"
```

## Troubleshooting

### Connection Issues
- Verify SSH key is correctly set in `.env`
- Check if port 2222 is available
- Confirm Docker container is running: `docker ps`

### Permission Issues
- Ensure volume paths have correct permissions
- Check that SSH key has proper format

### Borg Command Issues
- Always use `--` to separate SSH options from Borg commands
- Repository must be initialized before creating backups

## Notes

- First connection may take longer due to SSH key generation
- All backup data persists in Docker volumes
- Security alerts are logged to `/var/log/commands/security_alerts.log`
- The container automatically restarts on failure

