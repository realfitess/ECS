# =========================
# BUILD .NET (Roblox.Website)
# =========================
FROM mcr.microsoft.com/dotnet/sdk:6.0 AS build
WORKDIR /src

COPY . .

RUN dotnet restore services/Roblox/Roblox.Website/Roblox.Website.csproj
RUN dotnet publish services/Roblox/Roblox.Website/Roblox.Website.csproj \
    -c Release \
    -o /app/publish \
    --no-restore


# =========================
# NODE (API - opcjonalne)
# =========================
FROM node:18 AS node
WORKDIR /app/api

# NIE FAILUJE jeśli brak api
COPY api/package*.json ./
RUN if [ -f package.json ]; then npm install; else echo "No node app"; fi

COPY api ./


# =========================
# RUNTIME
# =========================
FROM mcr.microsoft.com/dotnet/aspnet:6.0
WORKDIR /app

# .NET
