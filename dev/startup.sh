#!/bin/bash
# =============================================================================
# Railway Startup Script - startup.sh
# =============================================================================
# Purpose: This script runs when Railway starts your Docker container
# 
# What it does:
# 1. Checks if the volume (/data) exists
# 2. Creates necessary directories in the volume
# 3. Sets proper permissions so your app can write to the volume
# 4. Starts your main application
#
# When does this run?
# - Every time Railway starts/restarts your container
# - Before your main application starts
# - Ensures volume is ready for use
# =============================================================================

echo "🚀 Starting application..."

# -----------------------------------------------------------------------------
# STEP 1: Check if Railway volume is mounted at /data
# -----------------------------------------------------------------------------
# The -d flag checks if "/data" exists AND is a directory
# If Railway successfully mounted the volume, /data will exist
if [ -d "/data" ]; then
    echo "📁 Setting up /data volume permissions..."
    
    # -------------------------------------------------------------------------
    # STEP 2: Create directory structure inside the volume
    # -------------------------------------------------------------------------
    # mkdir -p means:
    # - Create the directory
    # - Create parent directories if needed (-p flag)
    # - Don't error if directory already exists
    #
    # We create three directories:
    # - /data/app        → For application data (configs, databases, etc.)
    # - /data/uploads    → For user-uploaded files
    # - /data/logs       → For application logs
    #
    # Why? These directories will PERSIST even when container restarts!
    mkdir -p /data/app /data/uploads /data/logs
    
    # -------------------------------------------------------------------------
    # STEP 3: Fix permissions so your app user can write
    # -------------------------------------------------------------------------
    # Problem: By default, /data might be owned by root
    # Solution: Change ownership to the current user
    #
    # $(whoami) → Returns current username (e.g., "sameir2")
    # chown -R  → Change ownership recursively (-R = all files inside too)
    #
    # The "2>/dev/null || {...}" part means:
    # - Try to change ownership
    # - If it fails (no sudo permissions), show warning instead of crashing
    # - 2>/dev/null hides the error message
    # - || means "or if that fails, do this instead"
    chown -R $(whoami):$(whoami) /data/app /data/uploads /data/logs 2>/dev/null || {
        echo "⚠️  Could not change ownership, will use home directory"
        # Note: If this fails, your app should fall back to using home directory
    }
    
    echo "✅ Volume setup complete"
else
    # -------------------------------------------------------------------------
    # STEP 4: Handle case where volume is NOT mounted
    # -------------------------------------------------------------------------
    # This could happen if:
    # - Volume configuration was removed
    # - Volume failed to mount
    # - You're running locally without a volume
    echo "⚠️  No /data volume found"
    # Your app should detect this and use an alternative storage location
fi

# -----------------------------------------------------------------------------
# STEP 5: Start your main application
# -----------------------------------------------------------------------------
# exec means:
# - Replace this shell script process with the Python process
# - The script exits, Python becomes the main process (PID 1)
# - Railway monitors the Python process, not this script
#
# Why exec instead of just running python3?
# - Proper signal handling (Ctrl+C, Railway stop commands)
# - Python becomes the main process that Railway manages
# - No zombie processes
echo "🎯 Starting main application..."
exec python3 /app/main.py

# Note: This line is never reached because exec replaces the process
# If you need cleanup after app exits, don't use exec

