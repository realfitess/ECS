# =========================
# .NET BUILD STAGE
# =========================
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS dotnet-build

WORKDIR /src

# 🔥 TWOJE PRAWDZIWE PATH Z REPO
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

# published app
COPY --from=dotnet-build /app/publish ./website

# FIX: missing runtime folder (crash protection)
RUN mkdir -p /app/api/public/images/thumbnails

# start script
COPY start
