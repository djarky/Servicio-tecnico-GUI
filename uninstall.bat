@echo off
:: ST-PRO Web: Script de Desinstalación (Windows)

echo ------------------------------------------
echo   ST-PRO: PELIGRO - DESINSTALACIÓN
echo ------------------------------------------
echo Este script eliminará:
echo 1. La base de datos 'servicio_tecnico' COMPLETA.
echo 2. El usuario de base de datos 'st_user'.
echo 3. Las carpetas 'uploads' y 'vendor'.
echo.
set /p confirm="¿Estás seguro de que deseas continuar? (s/N): "

if /i not "%confirm%"=="s" goto cancel

set /p dbuser="Nombre de usuario de MySQL (default: root): "
if "%dbuser%"=="" set dbuser=root

echo >>> Eliminando Base de Datos y Usuarios...
mysql -u %dbuser% -p -e "DROP DATABASE IF EXISTS servicio_tecnico; DROP USER IF EXISTS 'st_user'@'localhost'; FLUSH PRIVILEGES;"

if %errorlevel% equ 0 (
    echo [OK] MySQL Limpio.
) else (
    echo [ERROR] No se pudo limpiar MySQL.
)

echo >>> Eliminando carpetas locales...
if exist "uploads" rmdir /s /q "uploads"
if exist "vendor" rmdir /s /q "vendor"
echo [OK] Carpetas eliminadas.

echo.
echo ------------------------------------------
echo   ST-PRO: Desinstalacion Completada.
echo ------------------------------------------
goto end

:cancel
echo Desinstalacion cancelada.

:end
pause
