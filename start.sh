#!/bin/sh

echo "[ECS] Starting Roblox.Website..."

# NIE robimy cd /website, bo go nie ma
cd /app

# uruchomienie aplikacji
exec dotnet Roblox.Website.dll
