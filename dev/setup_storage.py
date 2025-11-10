#!/usr/bin/env python3
"""
=============================================================================
Railway Storage Setup Script - setup_storage.py
=============================================================================

PURPOSE:
This script sets up persistent storage directories for your application.
It intelligently detects whether Railway volume is available and writable,
and creates the appropriate directory structure.

WHAT IT DOES:
1. Checks if /data volume exists and is writable
2. Falls back to home directory if volume is not accessible
3. Creates organized directory structure for your app
4. Tests write permissions
5. Generates configuration file with all paths

WHEN TO USE:
- Run this ONCE when setting up your project
- Run again if you add/remove Railway volume
- Run to verify storage setup after deployment

HOW TO USE:
    python3 setup_storage.py

The script will tell you where your storage is located and create
all necessary directories.

=============================================================================
"""

# Standard library imports
import os           # For environment variables and file operations
from pathlib import Path  # Modern way to work with file paths
import time         # For timestamps

def setup_storage():
    """
    Set up storage directories for the application
    
    This function:
    1. Determines the best location for persistent storage
    2. Tests if we can write to that location
    3. Creates a standardized directory structure
    4. Returns paths for use in your application
    
    Returns:
        tuple: (base_path, directories_dict)
            - base_path: Path object pointing to storage root
            - directories_dict: Dictionary mapping names to Path objects
    """
    
    # =========================================================================
    # STEP 1: Determine Storage Location
    # =========================================================================
    # First priority: Try to use Railway volume at /data
    # Second priority: Fall back to user's home directory
    
    volume_path = Path('/data')  # Railway mounts volume here by default
    
    # Check if /data exists (Railway created it)
    if volume_path.exists():
        # =====================================================================
        # STEP 2: Test Write Permissions
        # =====================================================================
        # Volume exists, but can we write to it?
        # We'll try to create a temporary test file
        
        test_file = volume_path / '.write_test'  # Hidden file for testing
        
        try:
            # Try to create the test file
            # .touch() creates an empty file (like Unix 'touch' command)
            test_file.touch()
            
            # Success! Clean up the test file
            test_file.unlink()  # Delete the test file
            
            # We can write to the volume - use it!
            base_path = volume_path
            print(f"✅ Using volume at: {volume_path}")
            print("   This storage will PERSIST across container restarts!")
            
        except PermissionError:
            # ================================================================
            # STEP 3: Handle Permission Denied
            # ================================================================
            # We can see /data but can't write to it
            # This happens when volume is owned by root and we're not root
            
            # Fall back to home directory (we always have permission here)
            base_path = Path.home() / 'persistent_data'
            print(f"⚠️  Can't write to /data (permission denied)")
            print(f"   Using home directory instead: {base_path}")
            print(f"   Note: This is still in the container, so it's temporary!")
            print(f"   Tip: Configure Railway to run startup script as root")
    else:
        # =====================================================================
        # STEP 4: Volume Doesn't Exist
        # =====================================================================
        # /data directory doesn't exist at all
        # Either volume is not configured, or we're running locally
        
        base_path = Path.home() / 'persistent_data'
        print(f"⚠️  No /data volume found")
        print(f"   Using home directory: {base_path}")
        print(f"   Note: Data will be lost on container restart!")
        print(f"   Tip: Add a volume in Railway dashboard")
    
    # =========================================================================
    # STEP 5: Create Directory Structure
    # =========================================================================
    # Now that we have a base path, create organized subdirectories
    # Each directory serves a specific purpose
    
    directories = {
        # app_data: Core application data
        # - Database files (SQLite, etc.)
        # - Application configuration
        # - User preferences
        'app_data': base_path / 'app_data',
        
        # uploads: User-uploaded files
        # - Images, documents, videos
        # - Any file uploaded through your app
        # - Should be backed up regularly
        'uploads': base_path / 'uploads',
        
        # logs: Application logs
        # - Error logs
        # - Access logs
        # - Debug information
        # - Can grow large, monitor disk space
        'logs': base_path / 'logs',
        
        # cache: Temporary cached data
        # - API response cache
        # - Computed results
        # - Can be deleted safely
        'cache': base_path / 'cache',
        
        # agent_memory: AI agent persistent memory
        # - Agent state between runs
        # - Learned patterns
        # - Conversation history
        'agent_memory': base_path / 'agent_memory',
    }
    
    print("\n📁 Creating directories:")
    
    # Loop through each directory we want to create
    for name, path in directories.items():
        # path.mkdir() creates the directory
        # parents=True: Create parent directories if needed
        # exist_ok=True: Don't error if directory already exists
        path.mkdir(parents=True, exist_ok=True)
        
        # Visual feedback showing what was created
        print(f"  ✅ {name}: {path}")
    
    # =========================================================================
    # STEP 6: Create Configuration File
    # =========================================================================
    # Save all paths to a text file for easy reference
    # Your app can read this file to know where everything is
    
    config = base_path / 'config.txt'
    
    # Open file for writing ('w' mode)
    # Using 'with' ensures file is properly closed even if error occurs
    with open(config, 'w') as f:
        # Write base path
        f.write(f"Storage Base: {base_path}\n")
        f.write(f"Created: {time.strftime('%Y-%m-%d %H:%M:%S')}\n")
        f.write("\n")
        
        # Write each directory path
        for name, path in directories.items():
            f.write(f"{name}: {path}\n")
    
    print(f"\n✅ Setup complete! Configuration saved to: {config}")
    print(f"\n💡 You can now drag files to these directories in Cursor!")
    
    # Return values so other code can use these paths
    return base_path, directories


# =============================================================================
# MAIN EXECUTION
# =============================================================================
# This code runs when you execute: python3 setup_storage.py
# The "if __name__ == '__main__':" check ensures this only runs when
# the script is executed directly, not when imported as a module

if __name__ == "__main__":
    # Print header
    print("=" * 60)
    print("  STORAGE SETUP")
    print("=" * 60 + "\n")
    
    # Run the setup function
    base_path, dirs = setup_storage()
    
    # Print usage instructions
    print("\n" + "=" * 60)
    print("  HOW TO USE IN CURSOR")
    print("=" * 60)
    print(f"""
1. Look at Cursor's file explorer (left sidebar)
   - This is the same as Finder on Mac or File Explorer on Windows
   - Shows all files and directories in your project

2. Navigate to: {base_path}
   - Click to expand folders
   - Double-click to open
   - Just like navigating on your Mac!

3. You'll see these folders:
   - app_data/      → Put your databases, configs here
   - uploads/       → User-uploaded files go here
   - logs/          → Application logs
   - cache/         → Temporary cached data
   - agent_memory/  → AI agent memory/state

4. Now you can work EXACTLY like on your Mac:
   
   ✅ Drag files from your Mac to these folders
      - Select file on Mac → Drag to Cursor folder → Drop
      - File uploads to Railway container
      - Your code can access it immediately
   
   ✅ Right-click → New File
      - Creates a new empty file
      - Type the filename
      - Start editing immediately
   
   ✅ Right-click → New Folder
      - Creates a new subdirectory
      - Organize your files
   
   ✅ Edit files normally
      - Click any file to open
      - Edit in Cursor's editor
      - Cmd+S / Ctrl+S to save
   
   ✅ Delete files
      - Right-click → Delete
      - Or select and press Delete key
   
   ✅ Rename files
      - Right-click → Rename
      - Type new name
   
   Everything works EXACTLY like Mac Finder!

5. In your Python code, use these paths:
   
   from pathlib import Path
   
   # Define base storage path
   STORAGE = Path('{base_path}')
   
   # Access specific directories
   uploads = STORAGE / 'uploads'
   logs = STORAGE / 'logs'
   agent_mem = STORAGE / 'agent_memory'
   
   # Example: Save a file
   file_path = uploads / 'myfile.txt'
   with open(file_path, 'w') as f:
       f.write('Hello from Railway!')
   
   # Example: Read a file
   with open(file_path, 'r') as f:
       content = f.read()
       print(content)  # Hello from Railway!
   
   # Example: List files
   for file in uploads.iterdir():
       print(f"Found file: {{file.name}}")

6. Claude Agent SDK or any agent can use these paths:
   
   # Agent example
   MEMORY_DIR = STORAGE / 'agent_memory'
   
   def save_agent_state(agent_id, state):
       memory_file = MEMORY_DIR / f'{{agent_id}}.json'
       with open(memory_file, 'w') as f:
           json.dump(state, f)
   
   def load_agent_state(agent_id):
       memory_file = MEMORY_DIR / f'{{agent_id}}.json'
       if memory_file.exists():
           with open(memory_file, 'r') as f:
               return json.load(f)
       return None
   
   # Works exactly like on your Mac!
""")
    print("=" * 60)
    
    # Additional helpful information
    print("\n💡 PRO TIPS:")
    print("─" * 60)
    print("• Files in Railway volume (/data) PERSIST across restarts")
    print("• Files in home directory are TEMPORARY (lost on restart)")
    print("• Always put important data in the volume directories")
    print("• Use logs/ for debugging - you can tail them in real-time")
    print("• Use cache/ for data that can be regenerated")
    print("• Back up uploads/ regularly if it contains user data")
    print("─" * 60)
