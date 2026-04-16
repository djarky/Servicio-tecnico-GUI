#!/bin/bash
# ST-PRO Web: Script de Desinstalación (Linux)

echo "------------------------------------------"
echo "  ST-PRO: PELIGRO - DESINSTALACIÓN"
echo "------------------------------------------"
echo "Este script eliminará:"
echo "1. El usuario de base de datos 'st_user'."
echo "2. La base de datos 'servicio_tecnico' COMPLETA (incluye órdenes y clientes)."
echo "3. La carpeta 'uploads' (incluye fotos de equipos)."
echo "4. La carpeta 'vendor' de Composer."
echo ""
read -p "¿Estás seguro de que deseas continuar? (s/N): " CONFIRM

if [[ $CONFIRM =~ ^[Ss]$ ]]; then
    echo ">>> Eliminando Base de Datos y Usuarios..."
    sudo mysql -e "DROP DATABASE IF EXISTS servicio_tecnico; \
                   DROP USER IF EXISTS 'st_user'@'localhost'; \
                   FLUSH PRIVILEGES;"
    
    if [ $? -eq 0 ]; then
        echo "[OK] MySQL Limpio."
    else
        echo "[ERROR] No se pudo limpiar MySQL. Asegúrate de tener permisos."
    fi

    echo ">>> Eliminando carpetas locales..."
    rm -rf uploads vendor
    echo "[OK] Carpetas eliminadas."

    echo ""
    echo "------------------------------------------"
    echo "  ST-PRO: Desinstalación Completada."
    echo "------------------------------------------"
else
    echo "Desinstalación cancelada."
fi
