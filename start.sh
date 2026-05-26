#!/bin/sh

set -e

echo "[ECS] Booting container..."

# ==============================
# FIX .NET CRASH (missing folder)
# ==============================
mkdir -p /app/api/public/images/thumbnails

# ==============================
# START NODE API
# ==============================
echo "[ECS] Starting Node API..."

if [ -f "/app/api/index.js" ]; then
    node /app/api/index.js &
    echo "[ECS] Node started: index.js"

elif [ -f "/app/api/dist/index.js" ]; then
    node /app/api/dist/index.js &
    echo "[ECS] Node started: dist/index.js"

elif [ -f "/app/api/server.js" ]; then
    node /app/api/server.js &
    echo "[ECS] Node started: server.js"

else
    echo "[ECS] ERROR: Node entrypoint not found"
    find /app/api -type f -name "*.js"
fi

# ==============================
# START .NET
# ==============================
echo "[ECS] Starting ASP.NET..."

cd /app/website

exec dotnet Roblox.Website.dll --urls "http://0.0.0.0:5000"
