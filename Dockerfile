# =========================
# BUILD STAGE
# =========================
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build

WORKDIR /src

# kopiujemy całe repo (monorepo fix)
COPY . .

# restore + publish
RUN dotnet restore services/Roblox/Roblox.Website/Roblox.Website.csproj

RUN dotnet publish services/Roblox/Roblox.Website/Roblox.Website.csproj \
    -c Release \
    -o /app/publish \
    --no-restore


# =========================
# RUNTIME STAGE
# =========================
FROM mcr.microsoft.com/dotnet/aspnet:8.0

WORKDIR /app

# aplikacja trafia bezpośrednio do /app (NIE /website)
COPY --from=build /app/publish .

# start script
COPY start.sh /app/start.sh
RUN chmod +x /app/start.sh

EXPOSE 80

ENTRYPOINT ["/app/start.sh"]
