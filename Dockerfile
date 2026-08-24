# =============================================================================
# Overleaf Custom Code Dockerfile (Optimizada para builds rápidos)
# =============================================================================
# Esta imagen compila tus modificaciones de código fuente (services, libraries)
# sobre la imagen oficial de Overleaf CE en solo ~1 minuto.
#
# NOTA: NO instala paquetes de TeXLive aquí. Todos los paquetes de LaTeX
# residen en el volumen persistente `texlive_data` (Estrategia 2).
# =============================================================================

FROM sharelatex/sharelatex:latest

WORKDIR /overleaf

# 1. Copiar librerías y servicios con tus modificaciones locales
COPY libraries/ /overleaf/libraries/
COPY services/ /overleaf/services/

# 2. Restaurar configuraciones de Server-CE para history-v1 y servicios globales
COPY server-ce/config/production.json /overleaf/services/history-v1/config/production.json
COPY server-ce/config/custom-environment-variables.json /overleaf/services/history-v1/config/custom-environment-variables.json
COPY server-ce/config/settings.js /etc/overleaf/settings.js

# 3. Compilar assets de frontend (Webpack y Pug) con el código actualizado
RUN cd /overleaf/services/web && \
    (yarn run webpack:production || true) && \
    (yarn run precompile-pug || true)

WORKDIR /overleaf
