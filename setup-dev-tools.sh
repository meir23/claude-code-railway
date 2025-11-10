#!/bin/bash

# setup-dev-tools.sh
# Sets up development tools for the SSH user

set -e

USERNAME=${SSH_USERNAME:-"myuser"}
USER_HOME="/home/$USERNAME"

echo "Setting up development tools for user: $USERNAME"

# Function to run commands as the SSH user
run_as_user() {
    sudo -u "$USERNAME" bash -c "cd $USER_HOME && $1"
}

# Configure npm prefix to avoid permission issues with global installs
echo "Configuring npm for user installations..."
run_as_user "mkdir -p $USER_HOME/.npm-global"
run_as_user "npm config set prefix '$USER_HOME/.npm-global'"

# Add npm global binaries to PATH
echo 'export PATH="$HOME/.npm-global/bin:$PATH"' >> "$USER_HOME/.bashrc"
echo 'export PATH="$HOME/.npm-global/bin:$PATH"' >> "$USER_HOME/.profile"

# Install Claude Code globally as user (command: claude)
echo "Installing Claude Code..."
run_as_user "npm install -g @anthropic-ai/claude-code"

# --- GIT AND GITHUB SECTIONS HAVE BEEN REMOVED ---

# Create a development directory
run_as_user "mkdir -p $USER_HOME/dev"

# Install common Node.js packages
echo "Installing common Node.js packages..."
run_as_user "npm install -g pnpm yarn create-next-app @expo/cli"

# Set ~/dev as the default directory when logging in via SSH
echo "cd ~/dev" >> "$USER_HOME/.bashrc"
echo "cd ~/dev" >> "$USER_HOME/.profile"

echo "Development tools setup completed for $USERNAME"
