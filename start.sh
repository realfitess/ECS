#!/bin/bash

# Start Redis
redis-server --daemonize yes

# Start API
cd /app/api
node index.js &

# Start website
cd /app/website
dotnet Roblox.Website.dll --urls "http://0.0.0.0:5000"
