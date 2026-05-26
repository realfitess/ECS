FROM node:18-slim AS api-build
WORKDIR /app/api
COPY services/api/package*.json ./
RUN npm install
COPY services/api/ .

FROM mcr.microsoft.com/dotnet/sdk:6.0 AS website-build
WORKDIR /app/website
COPY services/Roblox/ .
RUN dotnet publish Roblox.Website/Roblox.Website.csproj -c Release -o /app/website/out

FROM mcr.microsoft.com/dotnet/aspnet:6.0
WORKDIR /app

# Install Node.js
RUN apt-get update && apt-get install -y curl && \
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get install -y nodejs redis-server && \
    apt-get clean

# Copy website
COPY --from=website-build /app/website/out ./website

# Copy API
COPY --from=api-build /app/api ./api

# Copy startup script
COPY start.sh .
RUN chmod +x start.sh

EXPOSE 5000 3000

CMD ["./start.sh"]
