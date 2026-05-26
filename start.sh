#!/bin/sh

echo "[ECS] Starting Roblox.Website..."

cd /app || exit 1

exec dotnet Roblox.Website.dll
