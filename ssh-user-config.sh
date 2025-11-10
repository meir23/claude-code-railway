#!/bin/bash

################################################################################
# 🚀 RAILWAY VOLUME PERMISSION SETUP
################################################################################
#
# WHY THIS IS NEEDED:
# ------------------
# Railway mounts volumes with root ownership (UID 0, GID 0) by default.
# This prevents non-root users (like sameir2) from writing to the volume,
# causing "Permission denied" errors when trying to save data, create files,
# or store persistent information.
#
# WHAT THIS DOES:
# --------------
# 1. Detects if a Railway volume is mounted at /home/sameir2/code-project/WORKSPACE
# 2. Changes ownership from root (0:0) to the application user (1000:1000)
# 3. Creates a standard directory structure for organized data storage
# 4. Handles gracefully if volume doesn't exist (for local development)
#
# WHEN IT RUNS:
# ------------
# This runs at container startup, BEFORE SSH configuration and BEFORE the
# application user (sameir2) needs to access the volume. It runs as root
# (the container starts as root) so it has permission to chown the volume.
#
# HOW TO REUSE IN OTHER PROJECTS:
# -------------------------------
# 1. Change VOLUME_PATH to your volume mount point
# 2. Change VOLUME_UID and VOLUME_GID to your application user's UID/GID
# 3. Customize the directory structure in the "Create standard directories" section
# 4. Keep the error suppression (2>/dev/null || true) for graceful failures
#
# EXAMPLE USE CASES:
# -----------------
# - AI agent memory storage (agent_memory/)
# - User file uploads (uploads/)
# - Application logs (logs/)
# - Database files (data/)
# - Temporary caches (cache/)
#
################################################################################

echo "=================================================="
echo "📦 Railway Volume Setup Starting..."
echo "=================================================="

# Volume configuration
VOLUME_PATH="/home/sameir2/code-project/WORKSPACE"
VOLUME_UID=1000  # sameir2 user
VOLUME_GID=1000  # sameir2 group

# Check if volume path exists
if [ -d "$VOLUME_PATH" ]; then
    echo "✅ Volume detected at: $VOLUME_PATH"
    
    # Get current ownership
    CURRENT_OWNER=$(stat -c '%u:%g' "$VOLUME_PATH" 2>/dev/null || echo "unknown")
    echo "📊 Current ownership: $CURRENT_OWNER"
    
    # Fix ownership if needed
    if [ "$CURRENT_OWNER" != "$VOLUME_UID:$VOLUME_GID" ]; then
        echo "🔧 Fixing volume permissions (root → user $VOLUME_UID:$VOLUME_GID)..."
        chown -R "$VOLUME_UID:$VOLUME_GID" "$VOLUME_PATH" 2>/dev/null || true
        
        # Verify ownership change
        NEW_OWNER=$(stat -c '%u:%g' "$VOLUME_PATH" 2>/dev/null || echo "unknown")
        if [ "$NEW_OWNER" = "$VOLUME_UID:$VOLUME_GID" ]; then
            echo "✅ Volume permissions fixed successfully!"
        else
            echo "⚠️  Permission change may have failed (running without root?)"
        fi
    else
        echo "✅ Volume permissions already correct!"
    fi
    
    # Create standard directory structure
    echo "📁 Creating standard directory structure..."
    mkdir -p "$VOLUME_PATH/data" 2>/dev/null || true
    mkdir -p "$VOLUME_PATH/uploads" 2>/dev/null || true
    mkdir -p "$VOLUME_PATH/logs" 2>/dev/null || true
    mkdir -p "$VOLUME_PATH/agent_memory" 2>/dev/null || true
    mkdir -p "$VOLUME_PATH/cache" 2>/dev/null || true
    
    # Fix permissions on newly created directories
    chown -R "$VOLUME_UID:$VOLUME_GID" "$VOLUME_PATH" 2>/dev/null || true
    
    echo "✅ Directory structure created:"
    echo "   📂 $VOLUME_PATH/data/"
    echo "   📂 $VOLUME_PATH/uploads/"
    echo "   📂 $VOLUME_PATH/logs/"
    echo "   📂 $VOLUME_PATH/agent_memory/"
    echo "   📂 $VOLUME_PATH/cache/"
    
else
    echo "⚠️  Volume not found at: $VOLUME_PATH"
    echo "   (This is normal for local development without Railway volumes)"
fi

echo "=================================================="
echo "✅ Volume Setup Complete!"
echo "=================================================="
echo ""

################################################################################
# 🔐 SSH USER CONFIGURATION
################################################################################

# Set SSH_USERNAME and SSH_PASSWORD by default or create an .env file (refer to.env.example)
: ${SSH_USERNAME:="myuser"}
: ${SSH_PASSWORD:="mypassword"}

# Set root password if root login is enabled
: ${ROOT_PASSWORD:=""}
if [ -n "$ROOT_PASSWORD" ]; then
    echo "root:$ROOT_PASSWORD" | chpasswd
    echo "Root password set"
else
    echo "Root password not set"
fi

# Set authorized keys if applicable
: ${AUTHORIZED_KEYS:=""}

# Set Railway environment variables for automatic binding
: ${HOST:="0.0.0.0"}
: ${HOSTNAME:="0.0.0.0"}
export HOST
export HOSTNAME
echo "Railway binding variables set: HOST=$HOST, HOSTNAME=$HOSTNAME"

# Set timezone if provided
: ${TZ:=""}
if [ -n "$TZ" ]; then
    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
    echo "Timezone set to: $TZ"
fi

# Set SSH banner if provided
: ${SSH_BANNER:=""}
if [ -n "$SSH_BANNER" ]; then
    echo "$SSH_BANNER" > /etc/ssh/banner
    echo "Banner /etc/ssh/banner" >> /etc/ssh/sshd_config
    echo "SSH banner configured"
fi

# Check if SSH_USERNAME or SSH_PASSWORD is empty and raise an error
if [ -z "$SSH_USERNAME" ] || [ -z "$SSH_PASSWORD" ]; then
    echo "Error: SSH_USERNAME and SSH_PASSWORD must be set." >&2
    exit 1
fi

# Create the user with the provided username and set the password
if id "$SSH_USERNAME" &>/dev/null; then
    echo "User $SSH_USERNAME already exists"
else
    useradd -ms /bin/bash "$SSH_USERNAME"
    echo "$SSH_USERNAME:$SSH_PASSWORD" | chpasswd
    # Add user to sudo group
    usermod -aG sudo "$SSH_USERNAME"
    echo "User $SSH_USERNAME created with the provided password and added to sudo group"
fi

# Set the authorized keys from the AUTHORIZED_KEYS environment variable (if provided)
if [ -n "$AUTHORIZED_KEYS" ]; then
    mkdir -p /home/$SSH_USERNAME/.ssh
    echo "$AUTHORIZED_KEYS" > /home/$SSH_USERNAME/.ssh/authorized_keys
    chown -R $SSH_USERNAME:$SSH_USERNAME /home/$SSH_USERNAME/.ssh
    chmod 700 /home/$SSH_USERNAME/.ssh
    chmod 600 /home/$SSH_USERNAME/.ssh/authorized_keys
    echo "Authorized keys set for user $SSH_USERNAME"
    # Disable password authentication if authorized keys are provided
    sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
else
    echo "Authorized keys not set"
fi

# Set up development tools and configure environment
echo "Setting up development environment..."
if [ -f "/usr/local/bin/setup-dev-tools.sh" ]; then
    bash /usr/local/bin/setup-dev-tools.sh
else
    echo "Warning: setup-dev-tools.sh not found"
fi

# Create development directory
echo "Setting up development workspace..."
mkdir -p "/home/$SSH_USERNAME/dev"
chown "$SSH_USERNAME:$SSH_USERNAME" "/home/$SSH_USERNAME/dev"

echo "Development environment setup completed"

# Configure logging
: ${LOG_LEVEL:="INFO"}
echo "LogLevel $LOG_LEVEL" >> /etc/ssh/sshd_config
echo "SyslogFacility AUTH" >> /etc/ssh/sshd_config

################################################################################
# 🔑 SSH HOST KEY PERSISTENCE
################################################################################
#
# THE PROBLEM:
# -----------
# Railway "Redeploy" = Complete Container Destruction + Rebuild
# - Every redeploy destroys the old container completely
# - New container generates NEW SSH host keys (server's "identity")
# - Your MacBook remembers the OLD host key from previous connection
# - SSH sees DIFFERENT host key → Security Alert!
# - Result: "WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!"
# - Connection blocked → Manual intervention required EVERY redeploy 😤
#
# THE SOLUTION:
# ------------
# Store SSH host keys in Railway VOLUME (persistent storage) instead of 
# container filesystem (ephemeral). This way, the server maintains the SAME
# "identity" across all redeployments.
#
# HOW IT WORKS:
# ------------
# FIRST DEPLOY:
#   1. No host keys in volume yet
#   2. SSH generates new host keys (in /etc/ssh/)
#   3. Backup these keys to volume
#   4. Start SSH with these keys
#
# EVERY SUBSEQUENT REDEPLOY:
#   1. Host keys EXIST in volume ✅
#   2. Restore keys from volume to /etc/ssh/
#   3. Start SSH with SAME keys ✅
#   4. Your MacBook: "I recognize this server!" ✅
#   5. Connect without warnings! 🎉
#
# WHAT GETS STORED:
# ----------------
# All SSH host key pairs (private + public):
# - ssh_host_rsa_key + ssh_host_rsa_key.pub
# - ssh_host_ecdsa_key + ssh_host_ecdsa_key.pub
# - ssh_host_ed25519_key + ssh_host_ed25519_key.pub
#
# WHY THIS IS SECURE:
# ------------------
# - Keys stored in volume (not in image or git)
# - Proper file permissions (600 for private, 644 for public)
# - Keys generated by SSH (not custom/weak keys)
# - Volume access controlled by Railway
#
# HOW TO REUSE IN OTHER PROJECTS:
# -------------------------------
# 1. Change HOST_KEYS_BACKUP_DIR to your volume path
# 2. Keep the restore/backup logic as-is
# 3. Ensure volume exists and has correct permissions
#
################################################################################

echo ""
echo "=================================================="
echo "🔑 SSH Host Key Persistence Setup Starting..."
echo "=================================================="

# Configuration
HOST_KEYS_BACKUP_DIR="/home/sameir2/code-project/WORKSPACE/ssh_host_keys"
HOST_KEYS_LOCATION="/etc/ssh"

# List of SSH host key files to persist
HOST_KEY_FILES=(
    "ssh_host_rsa_key"
    "ssh_host_rsa_key.pub"
    "ssh_host_ecdsa_key"
    "ssh_host_ecdsa_key.pub"
    "ssh_host_ed25519_key"
    "ssh_host_ed25519_key.pub"
)

# Check if we have a volume to work with
if [ -d "/home/sameir2/code-project/WORKSPACE" ]; then
    echo "✅ Volume detected - Host key persistence enabled"
    
    # Create backup directory if it doesn't exist
    mkdir -p "$HOST_KEYS_BACKUP_DIR" 2>/dev/null || true
    chown -R "$VOLUME_UID:$VOLUME_GID" "$HOST_KEYS_BACKUP_DIR" 2>/dev/null || true
    
    # Check if host keys exist in volume (from previous deployment)
    if [ -f "$HOST_KEYS_BACKUP_DIR/ssh_host_rsa_key" ]; then
        echo "🔄 Restoring SSH host keys from volume..."
        echo "   (This ensures the server keeps the same identity across redeployments)"
        
        # Restore each host key file from volume to /etc/ssh/
        for key_file in "${HOST_KEY_FILES[@]}"; do
            if [ -f "$HOST_KEYS_BACKUP_DIR/$key_file" ]; then
                cp "$HOST_KEYS_BACKUP_DIR/$key_file" "$HOST_KEYS_LOCATION/$key_file" 2>/dev/null || true
                
                # Set proper permissions (private keys: 600, public keys: 644)
                if [[ "$key_file" == *.pub ]]; then
                    chmod 644 "$HOST_KEYS_LOCATION/$key_file" 2>/dev/null || true
                else
                    chmod 600 "$HOST_KEYS_LOCATION/$key_file" 2>/dev/null || true
                fi
                
                echo "   ✅ Restored: $key_file"
            fi
        done
        
        echo "✅ SSH host keys restored successfully!"
        echo "   Your MacBook will recognize this server without warnings! 🎉"
        
    else
        echo "📝 No existing host keys found in volume"
        echo "   Host keys will be generated by SSH server on first start"
        echo "   They will be backed up to volume for future redeployments"
        
        # Note: Host keys will be backed up AFTER SSH server generates them
        # This happens in a background process after SSH starts
        (
            # Wait for SSH to generate the keys (usually takes 1-2 seconds)
            sleep 3
            
            # Backup newly generated host keys to volume
            if [ -f "$HOST_KEYS_LOCATION/ssh_host_rsa_key" ]; then
                echo ""
                echo "💾 Backing up newly generated SSH host keys to volume..."
                
                for key_file in "${HOST_KEY_FILES[@]}"; do
                    if [ -f "$HOST_KEYS_LOCATION/$key_file" ]; then
                        cp "$HOST_KEYS_LOCATION/$key_file" "$HOST_KEYS_BACKUP_DIR/$key_file" 2>/dev/null || true
                        echo "   ✅ Backed up: $key_file"
                    fi
                done
                
                # Fix ownership of backed up keys
                chown -R "$VOLUME_UID:$VOLUME_GID" "$HOST_KEYS_BACKUP_DIR" 2>/dev/null || true
                
                echo "✅ SSH host keys backed up to volume!"
                echo "   Future redeployments will use these same keys! 🔐"
            fi
        ) &
    fi
    
else
    echo "⚠️  No volume detected - Using ephemeral host keys"
    echo "   (This is normal for local development)"
    echo "   Host keys will change on every container restart"
fi

echo "=================================================="
echo "✅ SSH Host Key Setup Complete!"
echo "=================================================="
echo ""

# Start the SSH server
echo "Starting SSH server with log level: $LOG_LEVEL"
exec /usr/sbin/sshd -D