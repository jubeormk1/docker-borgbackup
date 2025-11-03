#!/bin/bash
# Borg Backup Factory Configuration

# Base folder for all user volumes
BASE_FOLDER="${BASE_FOLDER:-./volumes}"

# You can override this by setting BASE_FOLDER environment variable
# Example: export BASE_FOLDER="/mnt/borg_volumes"