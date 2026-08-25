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

# 1. Respaldar los assets compilados existentes (public, manifest.json)
RUN cp -r /overleaf/services/web/public /tmp/web_public_backup

# 2. Copiar librerías y servicios con tus modificaciones locales
COPY libraries/ /overleaf/libraries/
COPY services/ /overleaf/services/

# 3. Restaurar los assets compilados en public y configuraciones de Server-CE
RUN cp -rn /tmp/web_public_backup/* /overleaf/services/web/public/ && rm -rf /tmp/web_public_backup
COPY server-ce/config/production.json /overleaf/services/history-v1/config/production.json
COPY server-ce/config/custom-environment-variables.json /overleaf/services/history-v1/config/custom-environment-variables.json
COPY server-ce/config/settings.js /etc/overleaf/settings.js

# 4. Precompilar plantillas Pug (incluyendo la nueva vista de Gestión de Usuarios)
RUN cd /overleaf/services/web && (yarn run precompile-pug || true)

WORKDIR /overleaf
