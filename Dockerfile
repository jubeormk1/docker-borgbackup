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

# Copy monitoring wrapper scripts

COPY ./deployment-files/borg_wrapper.sh /usr/local/bin/borg_wrapper.sh
RUN chmod +x /usr/local/bin/borg_wrapper.sh

# Copy log rotation script

COPY ./deployment-files/log_rotator.sh /usr/local/bin/log_rotator.sh
RUN chmod +x /usr/local/bin/log_rotator.sh

# Copy real-time monitor script
COPY ./deployment-files/monitor_commands.sh /usr/local/bin/monitor_commands.sh 
RUN chmod +x /usr/local/bin/monitor_commands.sh

# Remove any existing SSH config and create our secure config
RUN rm -f /etc/ssh/sshd_config /etc/ssh/sshd_config.d/* 2>/dev/null || true
COPY ./deployment-files/sshd_config /etc/ssh/sshd_config
RUN chown root:root /etc/ssh/sshd_config

# Copy the enhanced startup script
COPY ./deployment-files/start.sh /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/start.sh

EXPOSE 22

CMD ["/usr/local/bin/start.sh"]