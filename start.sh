#!/bin/sh

echo "[ECS] Starting Roblox.Website..."

cd /app || exit 1

# start .NET app
exec dotnet Roblox.Website.dll
