#!/bin/sh

echo "[ECS] Starting Roblox.Website..."

cd /app/website || {
  echo "ERROR: /app/website not found"
  ls -la /app
  exit 1
}

exec dotnet Roblox.Website.dll
