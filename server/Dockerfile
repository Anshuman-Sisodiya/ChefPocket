FROM node:22-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install --omit=dev
COPY . .
EXPOSE 8787
ENV PORT=8787
ENV HOST=0.0.0.0
CMD ["node", "server.mjs"]