#!/usr/bin/env python3
"""
Example: Using Railway Volume for Persistent Storage
Demonstrates how to read/write files that persist across container restarts
"""
import os
import json
import time
from pathlib import Path

# Configuration
# When Railway volume is mounted, use it. Otherwise, use temporary storage in home
# In production with volume: VOLUME_PATH = '/data'
# For demo without volume: VOLUME_PATH = '/home/sameir2/persistent_data'
VOLUME_PATH = os.environ.get('RAILWAY_VOLUME_MOUNT_PATH', '/home/sameir2/persistent_data')
DATA_DIR = Path(VOLUME_PATH) / 'app_data'
UPLOAD_DIR = Path(VOLUME_PATH) / 'uploads'
LOG_FILE = Path(VOLUME_PATH) / 'app.log'

def setup_storage():
    """Create storage directories if they don't exist"""
    print(f"📁 Setting up storage at: {VOLUME_PATH}")
    
    # Check if volume is available
    if os.path.exists(VOLUME_PATH):
        print(f"✅ Volume path exists: {VOLUME_PATH}")
    else:
        print(f"⚠️  Volume path doesn't exist: {VOLUME_PATH}")
        print("   Creating temporary directory...")
        os.makedirs(VOLUME_PATH, exist_ok=True)
    
    # Create subdirectories
    DATA_DIR.mkdir(parents=True, exist_ok=True)
    UPLOAD_DIR.mkdir(parents=True, exist_ok=True)
    
    print(f"✅ Data directory: {DATA_DIR}")
    print(f"✅ Upload directory: {UPLOAD_DIR}")
    print(f"✅ Log file: {LOG_FILE}")

def write_log(message):
    """Write to persistent log file"""
    timestamp = time.strftime('%Y-%m-%d %H:%M:%S')
    with open(LOG_FILE, 'a') as f:
        f.write(f"[{timestamp}] {message}\n")
    print(f"📝 Logged: {message}")

def save_data(key, value):
    """Save data to persistent storage"""
    file_path = DATA_DIR / f"{key}.json"
    with open(file_path, 'w') as f:
        json.dump({'key': key, 'value': value, 'timestamp': time.time()}, f, indent=2)
    print(f"💾 Saved: {key} = {value}")
    write_log(f"Saved data: {key}")

def load_data(key):
    """Load data from persistent storage"""
    file_path = DATA_DIR / f"{key}.json"
    if file_path.exists():
        with open(file_path, 'r') as f:
            data = json.load(f)
        print(f"📖 Loaded: {key} = {data['value']}")
        return data['value']
    else:
        print(f"❌ Key not found: {key}")
        return None

def list_files():
    """List all files in persistent storage"""
    print("\n" + "="*50)
    print("📂 Files in Persistent Storage:")
    print("="*50)
    
    if DATA_DIR.exists():
        files = list(DATA_DIR.glob('*.json'))
        if files:
            for f in files:
                print(f"  • {f.name}")
        else:
            print("  (no files yet)")
    
    if LOG_FILE.exists():
        size = LOG_FILE.stat().st_size
        print(f"\n📄 Log file: {LOG_FILE.name} ({size} bytes)")
    
    print("="*50 + "\n")

def check_persistence():
    """Check if this is a fresh container or has persisted data"""
    startup_file = DATA_DIR / 'startup_count.json'
    
    if startup_file.exists():
        with open(startup_file, 'r') as f:
            data = json.load(f)
        count = data.get('count', 0) + 1
        print(f"\n🔄 Container restarted! Previous startups: {count-1}")
    else:
        count = 1
        print(f"\n🆕 First startup detected!")
    
    with open(startup_file, 'w') as f:
        json.dump({'count': count, 'last_startup': time.time()}, f, indent=2)
    
    return count

def demo():
    """Demonstrate persistent storage capabilities"""
    print("\n" + "="*60)
    print("  🗄️  RAILWAY VOLUME DEMO - PERSISTENT STORAGE")
    print("="*60 + "\n")
    
    # Setup
    setup_storage()
    
    # Check if data persisted
    startup_count = check_persistence()
    
    # Log startup
    write_log(f"Application started (startup #{startup_count})")
    
    # Save some example data
    print("\n📝 Saving example data...")
    save_data('user_name', 'Sameir')
    save_data('last_login', time.strftime('%Y-%m-%d %H:%M:%S'))
    save_data('counter', startup_count)
    
    # Load data back
    print("\n📖 Loading data back...")
    name = load_data('user_name')
    login = load_data('last_login')
    counter = load_data('counter')
    
    # List all files
    list_files()
    
    # Show persistence info
    print("="*60)
    print("  💡 PERSISTENCE INFORMATION")
    print("="*60)
    print(f"""
Volume Path: {VOLUME_PATH}
Container ID: {os.uname().nodename}
Startup Count: {startup_count}

✅ All files in {VOLUME_PATH} will PERSIST across restarts!
⚠️  Files outside this path are TEMPORARY and will be deleted!

How it works:
1. Railway mounts a volume at {VOLUME_PATH}
2. This volume is backed by persistent storage
3. When container restarts → Volume remains intact
4. New container mounts the SAME volume
5. Your data is preserved!

Like your Mac:
- Mac: Files in /Users/you/ → Always there
- Railway: Files in {VOLUME_PATH} → Always there
    """)
    print("="*60)

if __name__ == "__main__":
    demo()


