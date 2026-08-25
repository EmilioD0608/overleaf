# =============================================================================
# Overleaf Custom Code Dockerfile (Ultra Rápida y 100% Segura)
# =============================================================================
# Aplica las modificaciones personalizadas (Gestión de Usuarios, Admin Panel,
# MongoDB fallback) directamente sobre la imagen oficial de Overleaf CE
# sin alterar librerías, dependencias ni bundles compilados (public/manifest.json).
# =============================================================================

FROM sharelatex/sharelatex:latest

WORKDIR /overleaf

# 1. Inyectar modificaciones en el servicio Web (Modelo de Usuario, Auth, Admin y Vistas)
COPY services/web/app/src/models/User.mjs /overleaf/services/web/app/src/models/User.mjs
COPY services/web/app/src/Features/Authentication/AuthenticationController.mjs /overleaf/services/web/app/src/Features/Authentication/AuthenticationController.mjs
COPY services/web/app/src/Features/ServerAdmin/AdminController.mjs /overleaf/services/web/app/src/Features/ServerAdmin/AdminController.mjs
COPY services/web/app/src/router.mjs /overleaf/services/web/app/src/router.mjs
COPY services/web/app/views/admin/index.pug /overleaf/services/web/app/views/admin/index.pug

# 2. Inyectar corrección de conexión MongoDB en History
COPY services/history-v1/storage/lib/mongodb.js /overleaf/services/history-v1/storage/lib/mongodb.js

WORKDIR /overleaf
