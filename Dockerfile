# =========================
# NODE BUILD
# =========================
FROM node:18 AS node

WORKDIR /app/api

COPY api/package*.json ./
RUN npm install

COPY api ./

# jeśli masz TS:
# RUN npm run build


# =========================
# .NET BUILD (FIX PATH)
# =========================
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS dotnet-build

WORKDIR /src

# 🔥 POPRAWNA ŚCIEŻKA Z TWOJEGO REPO
COPY services/Roblox/Roblox.Website ./Roblox.Website

RUN dotnet restore Roblox.Website/Roblox.Website.csproj

RUN dotnet publish Roblox.Website/Roblox.Website.csproj \
    -c Release \
    -o /app/publish


# =========================
# RUNTIME
# =========================
FROM mcr.microsoft.com/dotnet/aspnet:8.0

WORKDIR /app

# .NET app
COPY --from=dotnet-build /app/publish ./website

# Node API
COPY --from=node /app/api ./api

# FIX CRASH DIRECTORY
RUN mkdir -p /app/api/public/images/thumbnails

# start script
COPY start.sh /app/start.sh
RUN chmod +x /app/start.sh

CMD ["/app/start.sh"]
