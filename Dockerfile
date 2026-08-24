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

# 2. Compilar assets de frontend (Webpack y Pug) con el código actualizado
RUN cd /overleaf/services/web && \
    (yarn run webpack:production || true) && \
    (yarn run precompile-pug || true)

WORKDIR /overleaf
