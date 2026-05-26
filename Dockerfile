# =========================
# NODE BUILD (JEŚLI MASZ FRONTEND)
# =========================
FROM node:18 AS node-build

WORKDIR /app/api

# jeśli nie masz api → NIE FAILUJE
COPY api/package*.json ./
RUN if [ -f package.json ]; then npm install; else echo "No node app"; fi

COPY api ./


# =========================
# .NET BUILD
# =========================
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS dotnet-build

WORKDIR /src

# kopiujemy CAŁE repo (ważne!)
COPY . .

# idziemy do właściwego projektu
RUN dotnet restore services/Roblox/Roblox.Website/Roblox.Website.csproj

RUN dotnet publish services/Roblox/Roblox.Website/Roblox.Website.csproj \
    -c Release \
    -o /app/publish \
    --no-restore


# =========================
# RUNTIME
# =========================
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS runtime

WORKDIR /app

# app
COPY --from=dotnet-build /app/publish ./website

# node (opcjonalne)
COPY --from=node-build /app/api ./api || true

# FIX: brakujące foldery (TO BYŁ TWÓJ BŁĄD)
RUN mkdir -p \
    /app/api/public/images/thumbnails \
    /app/api/public/images/groups

COPY start.sh /app/start.sh
RUN chmod +x /app/start.sh

EXPOSE 80

ENTRYPOINT ["/app/start.sh"]
