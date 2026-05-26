# =========================
# BUILD .NET
# =========================
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build

WORKDIR /src

# kopiujemy CAŁE repo (ważne w Twoim przypadku)
COPY . .

# restore
RUN dotnet restore services/Roblox/Roblox.Website/Roblox.Website.csproj

# publish
RUN dotnet publish services/Roblox/Roblox.Website/Roblox.Website.csproj \
    -c Release \
    -o /app/publish \
    --no-restore


# =========================
# RUNTIME
# =========================
FROM mcr.microsoft.com/dotnet/aspnet:8.0

WORKDIR /app

COPY --from=build /app/publish .

# jeśli masz start.sh
COPY start.sh /app/start.sh
RUN chmod +x /app/start.sh

EXPOSE 80

ENTRYPOINT ["./start.sh"]
