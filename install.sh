#!/bin/bash
# ST-PRO Web: Script de Instalación (Linux/Ubuntu/Debian)

echo "------------------------------------------"
echo "  ST-PRO: Iniciando Instalación de Dependencias"
echo "------------------------------------------"

# 1. Actualizar el sistema
echo ">>> Actualizando listas de paquetes..."
sudo apt update

# 2. Instalar PHP, MySQL y extensiones
echo ">>> Instalando PHP, MySQL y extensiones necesarias..."
sudo apt install -y php-cli php-mysql php-sqlite3 mysql-server composer

# 3. Crear carpeta de subidas
echo ">>> Creando carpeta 'uploads'..."
mkdir -p uploads
chmod 777 uploads

# 4. Instalar librerías de Composer (Dompdf)
echo ">>> Instalando Dompdf (Librería para PDF)..."
if [ -f "composer.json" ]; then
    composer update
else
    composer require dompdf/dompdf
fi

# 5. Inicialización de Base de Datos y Usuarios
echo "------------------------------------------"
echo "  ST-PRO: Configuración de Base de Datos"
echo "------------------------------------------"
echo "Se intentará importar el esquema MySQL y configurar el usuario."
echo "A continuación, se te pedirá tu contraseña de superusuario (sudo) para MySQL."

# Intentar crear la base de datos y el usuario en un solo comando
sudo mysql -e "CREATE DATABASE IF NOT EXISTS servicio_tecnico; \
               CREATE USER IF NOT EXISTS 'st_user'@'localhost' IDENTIFIED BY 'st_pass123'; \
               GRANT ALL PRIVILEGES ON servicio_tecnico.* TO 'st_user'@'localhost'; \
               FLUSH PRIVILEGES;" 2>/dev/null

# Importar el esquema directamente
sudo mysql servicio_tecnico < schema.sql

if [ $? -eq 0 ]; then
    echo "[OK] Base de datos e hilos de acceso configurados correctamente."
    
    echo "[INFO] El perfil de administrador será creado cuando abra la aplicación web por primera vez."
else
    echo "[ERROR] No se pudo importar la base de datos. Verifica los permisos de MySQL."
fi

echo "------------------------------------------"
echo "  ST-PRO: Instalación Completada!"
echo "------------------------------------------"
echo "Para arrancar la aplicación, ejecuta: ./launch.sh"
echo "Recuerda configurar tus credenciales en config.php si es necesario."
