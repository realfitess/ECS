FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build

WORKDIR /src

# kopiujemy CAŁE repo (kluczowe)
COPY . .

# wybieramy główny projekt
RUN dotnet restore services/Roblox/Roblox.Website/Roblox.Website.csproj

RUN dotnet publish services/Roblox/Roblox.Website/Roblox.Website.csproj \
    -c Release \
    -o /app/publish \
    --no-restore


FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS runtime

WORKDIR /app

COPY --from=build /app/publish .

# statyczne rzeczy jeśli istnieją
RUN mkdir -p /app/static || true

COPY start.sh /app/start.sh
RUN chmod +x /app/start.sh

EXPOSE 80

ENTRYPOINT ["./start.sh"]
