#!/usr/bin/env bash
# =============================================================================
# Script de Instalación Única de TeXLive Full en el Volumen Persistente
# =============================================================================
# Uso:
#   bash bin/install-texlive-full.sh [nombre_contenedor]
#
# Por defecto utiliza el contenedor 'sharelatex'.
# =============================================================================

set -e

CONTAINER_NAME="${1:-sharelatex}"

echo "================================================================="
echo " Instalando TeXLive Full (scheme-full) en el contenedor: ${CONTAINER_NAME}"
echo " Los paquetes se guardarán permanentemente en el volumen Docker."
echo "================================================================="

# 1. Configurar el espejo CTAN con CDN para máxima velocidad
echo ">> Configurando espejo CTAN rápido (mirror.ctan.org)..."
docker exec "${CONTAINER_NAME}" tlmgr option repository https://mirror.ctan.org/systems/texlive/tlnet

# 2. Actualizar tlmgr
echo ">> Actualizando tlmgr..."
docker exec "${CONTAINER_NAME}" tlmgr update --self

# 3. Instalar scheme-full (todos los paquetes de CTAN)
echo ">> Descargando e instalando scheme-full (esto puede tomar varios minutos)..."
docker exec "${CONTAINER_NAME}" tlmgr install scheme-full

# 4. Actualizar rutas y generar mapas de fuentes
echo ">> Actualizando mapas de fuentes y cachés..."
docker exec "${CONTAINER_NAME}" tlmgr path add
docker exec "${CONTAINER_NAME}" updmap-sys || true
docker exec "${CONTAINER_NAME}" fc-cache -fv || true
docker exec "${CONTAINER_NAME}" luaotfload-tool --update --force || true

echo "================================================================="
echo " ¡Instalación completa!"
echo " Todos los paquetes de LaTeX están permanentemente en el volumen."
echo " Todos tus próximos deploys tardarán solo segundos."
echo "================================================================="
