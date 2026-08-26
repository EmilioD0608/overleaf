# =============================================================================
# Overleaf Custom Code Dockerfile con TeXLive Full Automático
# =============================================================================
# 1. Instala automáticamente TODOS los paquetes de LaTeX (scheme-full) en la
#    primera capa. Docker cachea esta capa para siempre en tu servidor Dokploy.
# 2. Inyecta tus modificaciones de código en la capa superior (builds en 2 segs).
# =============================================================================

FROM sharelatex/sharelatex:latest

# 1. Instalar todos los paquetes de LaTeX (scheme-full) automáticamente durante el build
RUN tlmgr option repository https://mirror.ctan.org/systems/texlive/tlnet && \
    tlmgr update --self && \
    tlmgr install scheme-full && \
    tlmgr path add && \
    updmap-sys || true && \
    fc-cache -fv || true && \
    luaotfload-tool --update --force || true

WORKDIR /overleaf

# 2. Inyectar modificaciones en el servicio Web (Modelo de Usuario, Auth, Admin y Vistas)
COPY services/web/app/src/models/User.mjs /overleaf/services/web/app/src/models/User.mjs
COPY services/web/app/src/Features/Authentication/AuthenticationController.mjs /overleaf/services/web/app/src/Features/Authentication/AuthenticationController.mjs
COPY services/web/app/src/Features/Analytics/AnalyticsManager.mjs /overleaf/services/web/app/src/Features/Analytics/AnalyticsManager.mjs
COPY services/web/app/src/Features/ServerAdmin/AdminController.mjs /overleaf/services/web/app/src/Features/ServerAdmin/AdminController.mjs
COPY services/web/app/src/router.mjs /overleaf/services/web/app/src/router.mjs
COPY services/web/app/views/admin/index.pug /overleaf/services/web/app/views/admin/index.pug

# 3. Inyectar corrección de conexión MongoDB en History
COPY services/history-v1/storage/lib/mongodb.js /overleaf/services/history-v1/storage/lib/mongodb.js

WORKDIR /overleaf
