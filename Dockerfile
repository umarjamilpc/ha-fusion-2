# Builder: full Debian image (better arm/v7 + native deps under QEMU than slim)
FROM node:22-bookworm AS builder
WORKDIR /app

COPY package.json package-lock.json ./
# npm install (not ci): survives package.json ↔ lockfile drift from Dependabot / manual bumps
RUN npm install --include=dev

COPY . .
RUN npm run build && npm prune --omit=dev

FROM node:22-alpine AS runner
WORKDIR /app

ENV NODE_ENV=production \
    PORT=5050 \
    ADDON=false

COPY --from=builder /app/build ./build
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/server.js .
COPY --from=builder /app/package.json .

EXPOSE 5050

HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 \
    CMD node -e "require('http').get('http://127.0.0.1:'+(process.env.PORT||5050)+'/_api/version',r=>process.exit(r.statusCode===200?0:1)).on('error',()=>process.exit(1))"

CMD ["node", "server.js"]
