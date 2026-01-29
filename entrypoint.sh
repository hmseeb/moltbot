#!/bin/bash
# Fix permissions on the data volume (runs as root initially)
if [ -d /home/node/data ]; then
    chown -R node:node /home/node/data
fi

# Clean up stale session lock files from previous runs
# These can persist across container restarts and cause "session file locked" errors
if [ -d /home/node/data/agents ]; then
    find /home/node/data/agents -name "*.lock" -type f -delete 2>/dev/null
    echo "Cleaned up stale session lock files"
fi

# Switch to node user and run the application
exec gosu node node dist/index.js gateway --bind lan --port ${PORT:-18789}
