# ---------- BUILD ----------
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS dotnet-build

WORKDIR /src

COPY . .

RUN dotnet restore services/Roblox/Roblox.Website/Roblox.Website.csproj

RUN dotnet publish services/Roblox/Roblox.Website/Roblox.Website.csproj \
    -c Release \
    -o /app/publish \
    --no-restore


# ---------- NODE (jeśli API istnieje) ----------
FROM node:18 AS node-build

WORKDIR /app/api

COPY api/package*.json ./

RUN if [ -f package.json ]; then npm install; else echo "No node app"; fi

COPY api ./

# ---------- RUNTIME ----------
FROM mcr.microsoft.com/dotnet/aspnet:8.0

WORKDIR /app

# app
COPY --from=dotnet-build /app/publish ./website

# node api (optional)
COPY --from=node-build /app/api ./api || true

# folders
RUN mkdir -p \
    /app/api/public/images/thumbnails \
    /app/api/public/images/groups

# start script
COPY start.sh /app/start.sh
RUN chmod +x /app/start.sh

EXPOSE 8080

CMD ["/app/start.sh"]
