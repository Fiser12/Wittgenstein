# Dockerfile

# Etapa 1: Instalación de dependencias
FROM node:20-slim AS deps
WORKDIR /app
# Habilitar corepack para pnpm
RUN corepack enable
# Copiar archivos de definición de paquetes
COPY package.json pnpm-lock.yaml* ./
# Instalar dependencias (incluyendo devDependencies necesarias para el build)
RUN pnpm install --frozen-lockfile

# Etapa 2: Construcción de la aplicación
FROM node:20-slim AS builder
WORKDIR /app
RUN corepack enable
COPY --from=deps /app/node_modules ./node_modules
COPY . .
# Asegúrate de que las variables de entorno NEXT_PUBLIC_* necesarias para el build estén disponibles aquí
# Ejemplo: ENV NEXT_PUBLIC_ANALYTICS_ID=...
# Si tienes variables NEXT_PUBLIC en un .env, necesitarías copiarlas y cargarlas o pasarlas al build
RUN pnpm build

# Etapa 3: Imagen final de producción
FROM node:20-slim AS runner
WORKDIR /app
RUN corepack enable

ENV NODE_ENV=production
# Crear un usuario y grupo no-root para seguridad
RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs

# Copiar artefactos necesarios de la etapa de construcción
COPY --from=builder /app/public ./public
COPY --from=builder /app/package.json ./package.json
# Copiar el build de Next.js
COPY --from=builder --chown=nextjs:nodejs /app/.next ./.next
# Copiar las node_modules necesarias para producción
COPY --from=builder --chown=nextjs:nodejs /app/node_modules ./node_modules

# Establecer el directorio HOME para el usuario nextjs
ENV HOME=/app

# Cambiar al usuario no-root
USER nextjs

# Exponer el puerto en el que correrá Next.js
EXPOSE 3000

# Establecer la variable de entorno PORT
ENV PORT=3000

# Comando para iniciar la aplicación Next.js en modo producción
CMD ["pnpm", "start"] 