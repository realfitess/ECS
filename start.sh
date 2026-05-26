#!/bin/sh

echo "[ECS] Starting container..."

# FIX .NET crash (thumbnails)
mkdir -p /app/api/public/images/thumbnails/

# ===== NODE START (ECS SAFE FIX) =====
echo "[ECS] Starting Node..."

if [ -f "/app/api/index.js" ]; then
    node /app/api/index.js &
elif [ -f "/app/api/dist/index.js" ]; then
    node /app/api/dist/index.js &
else
    echo "[ECS] ERROR: Cannot find Node entry"
    ls -R /app/api
fi

# ===== .NET START =====
echo "[ECS] Starting ASP.NET..."

cd /app/website
exec dotnet Roblox.Website.dll --urls "http://0.0.0.0:5000"
