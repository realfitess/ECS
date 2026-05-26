# ===== NODE BUILD STAGE =====
FROM node:18 AS node

WORKDIR /app/api

COPY api/package*.json ./
RUN npm install

COPY api ./

# jeśli masz TS — odkomentuj:
# RUN npm run build


# ===== DOTNET RUNTIME =====
FROM mcr.microsoft.com/dotnet/aspnet:8.0

WORKDIR /app

# API (node)
COPY --from=node /app/api /app/api

# website (.NET)
COPY website /app/website

# FIX: brak folderów static
RUN mkdir -p /app/api/public/images/thumbnails

# start script
COPY start.sh /app/start.sh
RUN chmod +x /app/start.sh

CMD ["/app/start.sh"]
