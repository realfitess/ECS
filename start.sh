#!/bin/sh

set -e

echo "[ECS] Booting system..."

# =========================
# FIX .NET CRASH (missing folder)
# =========================
mkdir -p /app/api/public/images/thumbnails

# =========================
# NODE START
# =========================
echo "[ECS] Starting Node..."

if [ -f "/app/api/dist/index.js" ]; then
    node /app/api/dist/index.js &
    echo "[ECS] Node: dist/index.js"

elif [ -f "/app/api/index.js" ]; then
    node /app/api/index.js &
    echo "[ECS] Node: index.js"

elif [ -f "/app/api/server.js" ]; then
    node /app/api/server.js &
    echo "[ECS] Node: server.js"

else
    echo "[ECS] Node entrypoint NOT FOUND"
    find /app/api -maxdepth 3 -type f -name "*.js"
fi

# =========================
# .NET START
# =========================
echo "[ECS] Starting ASP.NET..."

cd /app/website

exec dotnet Roblox.Website.dll --urls "http://0.0.0.0:5000"
