#!/bin/sh

echo "[ECS] Starting Roblox.Website..."

# NIE CRASHUJ jeśli folder nie istnieje
if [ -d "/app/website" ]; then
  cd /app/website
fi

# uruchom .NET
exec dotnet Roblox.Website.dll
