# =========================
# 1. BUILD .NET (SDK stage)
# =========================
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS dotnet-build
WORKDIR /src

# 🔥 KLUCZ FIX: kopiujemy CAŁE repo (nie /website, nie /api)
COPY . .

# restore całego projektu (ważne przy multi-project solution)
RUN dotnet restore services/Roblox/Roblox.Website/Roblox.Website.csproj

# publish main website
RUN dotnet publish services/Roblox/Roblox.Website/Roblox.Website.csproj \
    -c Release \
    -o /app/publish \
    --no-restore

# =========================
# 2. NODE BUILD (API)
# =========================
FROM node:18 AS node-build
WORKDIR /app/api

# instalacja zależności
COPY api/package*.json ./
RUN npm install

# kopiowanie API
COPY api ./

# =========================
# 3. RUNTIME (final image)
# =========================
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS runtime
WORKDIR /app

# .NET app
COPY --from=dotnet-build /app/publish ./website

# Node API
COPY --from=node-build /app/api ./api

# =========================
# FIX TWOICH BŁĘDÓW (DIRECTORIES)
# =========================
RUN mkdir -p
