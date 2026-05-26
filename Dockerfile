# ---------- BUILD STAGE ----------
FROM mcr.microsoft.com/dotnet/sdk:6.0 AS build

WORKDIR /src

# kopiujemy cały projekt (ważne: NIE psuje /api /services)
COPY . .

# restore + publish
RUN dotnet restore services/Roblox/Roblox.Website/Roblox.Website.csproj

RUN dotnet publish services/Roblox/Roblox.Website/Roblox.Website.csproj \
    -c Release \
    -o /app/publish \
    --no-restore


# ---------- NODE STAGE (opcjonalne API) ----------
FROM node:18 AS node

WORKDIR /app/api

COPY api/package*.json ./

RUN if [ -f package.json ]; then npm install; else echo "No node app"; fi

COPY api ./

# ---------- RUNTIME ----------
FROM mcr.microsoft.com/dotnet/aspnet:6.0

WORKDIR /app

# backend
COPY --from=build /app/publish ./website

# api (jeśli istnieje)
COPY --from=node /app/api ./api || true

# foldery runtime (ważne dla Twoich static files)
RUN mkdir -p \
    /app/api/public/images/thumbnails \
    /app/api/public/images/groups

# start script
COPY start.sh /app/start.sh
RUN chmod +x /app/start.sh

EXPOSE 8080

CMD ["/app/start.sh"]
