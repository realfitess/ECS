# =========================
# BUILD STAGE
# =========================
FROM mcr.microsoft.com/dotnet/sdk:6.0 AS build
WORKDIR /src

# kopiuj cały projekt (ważne!)
COPY . .

# restore + publish
RUN dotnet restore services/Roblox/Roblox.Website/Roblox.Website.csproj
RUN dotnet publish services/Roblox/Roblox.Website/Roblox.Website.csproj \
    -c Release \
    -o /app/publish \
    --no-restore

# =========================
# NODE (API jeśli używasz)
# =========================
FROM node:18 AS node
WORKDIR /app/api

COPY api/package*.json ./
RUN if [ -f package.json ]; then npm install; else echo "No node app"; fi

COPY api ./

# =========================
# RUNTIME
# =========================
FROM mcr.microsoft.com/dotnet/aspnet:6.0 AS final
WORKDIR /app

# app
COPY --from=build /app/publish ./

# node api (jeśli istnieje)
COPY --from=node /app/api ./api || true

# start script
COPY start.sh /app/start.sh
RUN chmod +x /app/start.sh

EXPOSE 80

ENTRYPOINT ["/app/start.sh"]
