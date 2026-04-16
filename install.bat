@echo off
:: ST-PRO Web: Script de Instalación (Windows)

set PORT=8080
set URL=http://localhost:%PORT%

echo ------------------------------------------
echo   ST-PRO: Iniciando Instalacion de Dependencias
echo ------------------------------------------

:: 1. Verificar PHP
php -v >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] PHP no se encuentra instalado o no esta en el PATH.
    echo Por favor, instala XAMPP, WAMP o descarga PHP manualmente.
    pause
    exit /b 1
)
echo [OK] PHP Detectado.

:: 2. Verificar MySQL
mysql --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [ALERTA] MySQL no se encuentra instalado o no esta en el PATH.
    echo Asegurate de que MySQL este corriendo para que la app funcione.
) else (
    echo [OK] MySQL Detectado.
)

:: 3. Verificar Composer y descargar Dompdf
call composer -v >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Composer no se encuentra instalado o no esta en el PATH.
    echo Por favor, instala Composer desde: https://getcomposer.org/
    pause
    exit /b 1
)
echo [OK] Composer Detectado. Instalando dependencias de terceros...
if exist "composer.json" (
    call composer update
) else (
    call composer require dompdf/dompdf
)

:: 4. Crear carpeta de subidas
if not exist "uploads" (
    echo [OK] Creando carpeta de 'uploads'...
    mkdir uploads
)

:: 5. Inicializacion de la Base de Datos (Opcional)
echo ------------------------------------------
echo   ST-PRO: Configuracion de Base de Datos
echo ------------------------------------------
echo Se intentara preparar la base de datos y el usuario 'st_user'.

set /p confirm="¿Desea resetear la base de datos? (s/n): "
if /i not "%confirm%"=="s" goto end

set /p dbuser="Nombre de usuario de MySQL (ADMIN) (default: root): "
if "%dbuser%"=="" set dbuser=root

echo --- Eliminando Base de Datos y Usuarios...
mysql -u %dbuser% -p -e "DROP DATABASE IF EXISTS servicio_tecnico; DROP USER IF EXISTS 'st_user'@'localhost'; FLUSH PRIVILEGES;"

if %errorlevel% equ 0 (
    echo [OK] MySQL Limpio.
) else (
    echo [ERROR] No se pudo limpiar MySQL.
)

:: Crear base de datos, usuario y dar permisos en un solo bloque
mysql -u %dbuser% -p -e "CREATE DATABASE IF NOT EXISTS servicio_tecnico; CREATE USER IF NOT EXISTS 'st_user'@'localhost' IDENTIFIED BY 'st_pass123'; GRANT ALL PRIVILEGES ON servicio_tecnico.* TO 'st_user'@'localhost'; FLUSH PRIVILEGES;"

:: Importar esquema
mysql -u %dbuser% -p servicio_tecnico < schema.sql

if %errorlevel% equ 0 (
    echo [OK] Base de datos e hilos de acceso configurados correctamente.
    echo [INFO] El primer Administrador sera configurado desde la Web.
) else (
    echo [ERROR] No se pudo importar la base de datos.
)

:end
echo ------------------------------------------
echo   ST-PRO: Instalacion Completada!
echo ------------------------------------------
echo Para arrancar la aplicacion, ejecuta: launch.bat
echo.
pause
