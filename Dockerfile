FROM mcr.microsoft.com/dotnet/sdk:8.0 AS dotnet-build

WORKDIR /src

COPY services/Roblox/Roblox.Website ./Roblox.Website

RUN dotnet restore Roblox.Website/Roblox.Website.csproj

RUN dotnet publish Roblox.Website/Roblox.Website.csproj \
    -c Release \
    -o /app/publish


FROM mcr.microsoft.com/dotnet/aspnet:8.0

WORKDIR /app

# ✔ FIXED COPY (2 ARGUMENTS!)
COPY --from=dotnet-build /app/publish ./website

RUN mkdir -p /app/api/public/images/thumbnails

COPY start.sh /app/start.sh
RUN chmod +x /app/start.sh

CMD ["/app/start.sh"]
