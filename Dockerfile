# =========================
# BUILD .NET
# =========================
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS dotnet-build

WORKDIR /src

# kopiujemy wszystko (najbezpieczniejsze przy monorepo)
COPY . .

RUN dotnet restore services/Roblox/Roblox.Website/Roblox.Website.csproj

RUN dotnet publish services/Roblox/Roblox.Website/Roblox.Website.csproj \
    -c Release \
    -o /app/publish \
    --no-restore


# =========================
# NODE (opcjonalnie frontend)
# =========================
FROM node:18 AS node-build

WORKDIR /app/api

# NIE wywalaj builda jak nie ma api
COPY api/package*.json . 2>/dev/null || true
RUN if [ -f package.json ]; then npm install; else echo "No Node API"; fi

COPY api . 2>/dev/null || true
RUN if [ -f package.json ]; then npm run build; fi


# =========================
# RUNTIME
# =========================
FROM mcr.microsoft.com/dotnet/aspnet:8.0

WORKDIR /app

COPY --from=dotnet-build /app/publish ./website

# node output (jeśli istnieje)
COPY --from=node-build /app/api ./api 2>/dev/null || true

RUN mkdir -p /app/api/public/images/thumbnails /app/api/public/images/groups

COPY start.sh /app/start.sh
RUN chmod +x /app/start.sh

EXPOSE 80

ENTRYPOINT ["./start.sh"]
