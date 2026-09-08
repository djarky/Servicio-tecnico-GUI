@echo off
:: setup_db.bat - Configuracion de Base de Datos para ST-PRO
:: Modos: check | fresh | repair | reinstall | remove
::
:: Codigos de salida:
::   0  = Exito
::   1  = Error: MySQL no se pudo iniciar o no responde
::   2  = Error: Fallo al crear la base de datos o el usuario st_user
::   3  = Error: Fallo al importar schema.sql
::   10 = Solo en 'check': La base de datos no existe aun

set "INSTALL_DIR=%~1"
set "MODE=%~2"
set "MYSQL=C:\xampp\mysql\bin\mysql.exe"

if "%INSTALL_DIR%"=="" set "INSTALL_DIR=%~dp0"
if "%INSTALL_DIR:~-1%"=="\" set "INSTALL_DIR=%INSTALL_DIR:~0,-1%"
if "%MODE%"=="" set "MODE=fresh"

:: 1. Localizar mysql.exe
if exist "%MYSQL%" goto mysql_found
where mysql >nul 2>&1
if %errorlevel% neq 0 goto err_no_mysql
set "MYSQL=mysql"
goto mysql_found

:mysql_found
:: 2. Asegurar que MySQL este en marcha
"%MYSQL%" -u root --connect-timeout=2 -e "SELECT 1;" >nul 2>&1
if %errorlevel% equ 0 goto mysql_ready

echo [DB] MySQL no responde. Iniciando servicio MySQL de XAMPP...
if exist "C:\xampp\mysql_start.bat" (
    start "" /b cmd /c "C:\xampp\mysql_start.bat" >nul 2>&1
) else (
    if exist "C:\xampp\mysql\bin\mysqld.exe" (
        start "" /b "C:\xampp\mysql\bin\mysqld.exe" --defaults-file="C:\xampp\mysql\bin\my.ini" --standalone >nul 2>&1
    )
)

set WAIT_COUNT=0

:wait_mysql_loop
set /a WAIT_COUNT+=1
if %WAIT_COUNT% gtr 15 goto err_mysql_timeout
ping -n 2 127.0.0.1 >nul
"%MYSQL%" -u root --connect-timeout=2 -e "SELECT 1;" >nul 2>&1
if %errorlevel% neq 0 goto wait_mysql_loop

echo [DB] MySQL iniciado y respondiendo correctamente

:mysql_ready
:: 3. Despacho segun modo
if /i "%MODE%"=="check" goto do_check
if /i "%MODE%"=="remove" goto do_remove
if /i "%MODE%"=="reinstall" goto do_reinstall
if /i "%MODE%"=="repair" goto do_setup_db
if /i "%MODE%"=="fresh" goto do_setup_db
goto do_setup_db

:: --- MODO CHECK ---
:do_check
"%MYSQL%" -u root --connect-timeout=3 -e "USE servicio_tecnico;" >nul 2>&1
if %errorlevel% equ 0 (
    echo [DB] La base de datos 'servicio_tecnico' ya existe
    exit /b 0
)
echo [DB] La base de datos 'servicio_tecnico' NO existe
exit /b 10

:: --- MODO REMOVE ---
:do_remove
echo [DB] Eliminando base de datos 'servicio_tecnico' y usuarios...
"%MYSQL%" -u root -e "DROP DATABASE IF EXISTS servicio_tecnico; DROP USER IF EXISTS 'st_user'@'localhost'; DROP USER IF EXISTS 'st_user'@'127.0.0.1'; FLUSH PRIVILEGES;" >nul 2>&1
exit /b 0

:: --- MODO REINSTALL ---
:do_reinstall
echo [DB] Limpiando base de datos previa...
"%MYSQL%" -u root -e "DROP DATABASE IF EXISTS servicio_tecnico; DROP USER IF EXISTS 'st_user'@'localhost'; DROP USER IF EXISTS 'st_user'@'127.0.0.1'; FLUSH PRIVILEGES;" >nul 2>&1
goto do_setup_db

:: --- MODO FRESH / REPAIR ---
:do_setup_db
echo [DB] Configurando base de datos 'servicio_tecnico' y usuario 'st_user'...
"%MYSQL%" -u root -e "CREATE DATABASE IF NOT EXISTS servicio_tecnico CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci; DROP USER IF EXISTS 'st_user'@'localhost'; DROP USER IF EXISTS 'st_user'@'127.0.0.1'; CREATE USER 'st_user'@'localhost' IDENTIFIED BY 'st_pass123'; CREATE USER 'st_user'@'127.0.0.1' IDENTIFIED BY 'st_pass123'; GRANT ALL PRIVILEGES ON servicio_tecnico.* TO 'st_user'@'localhost'; GRANT ALL PRIVILEGES ON servicio_tecnico.* TO 'st_user'@'127.0.0.1'; FLUSH PRIVILEGES;"
if %errorlevel% neq 0 goto err_create_user

:: Importar esquema
cd /d "%INSTALL_DIR%"
if not exist "schema.sql" goto err_no_schema

echo [DB] Importando tablas desde schema.sql...
"%MYSQL%" -u root --default-character-set=utf8mb4 servicio_tecnico < "schema.sql"
if %errorlevel% equ 0 goto success

echo [DB] Reintentando importacion con pipe...
type "schema.sql" | "%MYSQL%" -u root --default-character-set=utf8mb4 servicio_tecnico
if %errorlevel% equ 0 goto success

goto err_import_schema

:success
echo [OK] Base de datos 'servicio_tecnico' y usuario 'st_user' configurados exitosamente
exit /b 0

:err_no_mysql
echo [ERROR] No se encontro mysql.exe en C:\xampp\mysql\bin ni en el PATH
exit /b 1

:err_mysql_timeout
echo [ERROR] No se pudo conectar a MySQL despues de 15 segundos
exit /b 1

:err_create_user
echo [ERROR] No se pudo crear la base de datos o el usuario 'st_user' en MySQL
exit /b 2

:err_no_schema
echo [ERROR] No se encontro schema.sql en el directorio de instalacion
exit /b 3

:err_import_schema
echo [ERROR] Fallo al importar las tablas de schema.sql en MySQL
exit /b 3
