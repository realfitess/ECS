#!/bin/sh

set -e

echo "[ECS] Starting Roblox.Website..."

# FIX crash DirectoryNotFoundException
mkdir -p /app/api/public/images/thumbnails

# move to .NET app
cd /app/website

echo "[ECS] Launching .NET service..."

exec dotnet Roblox.Website.dll --urls "http://0.0.0.0:5000"
