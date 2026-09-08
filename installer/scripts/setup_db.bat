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

setlocal enabledelayedexpansion

set "INSTALL_DIR=%~1"
set "MODE=%~2"
set "MYSQL=C:\xampp\mysql\bin\mysql.exe"

if "%INSTALL_DIR%"=="" set "INSTALL_DIR=%~dp0"
if "%INSTALL_DIR:~-1%"=="\" set "INSTALL_DIR=%INSTALL_DIR:~0,-1%"
if "%MODE%"=="" set "MODE=fresh"

:: 1. Localizar mysql.exe
if not exist "%MYSQL%" (
    where mysql >nul 2>&1
    if !errorlevel! equ 0 (
        set "MYSQL=mysql"
    ) else (
        echo [ERROR] No se encontro mysql.exe en C:\xampp\mysql\bin ni en el PATH.
        exit /b 1
    )
)

:: 2. Asegurar que MySQL este en marcha
"%MYSQL%" -u root --connect-timeout=2 -e "SELECT 1;" >nul 2>&1
if !errorlevel! neq 0 (
    echo [DB] MySQL no responde. Iniciando servicio MySQL de XAMPP...
    if exist "C:\xampp\mysql_start.bat" (
        start "" /b cmd /c "C:\xampp\mysql_start.bat" >nul 2>&1
    ) else if exist "C:\xampp\mysql\bin\mysqld.exe" (
        start "" /b "C:\xampp\mysql\bin\mysqld.exe" --defaults-file="C:\xampp\mysql\bin\my.ini" --standalone >nul 2>&1
    )

    set "MYSQL_READY=0"
    for /L %%i in (1,1,15) do (
        if "!MYSQL_READY!"=="0" (
            ping -n 2 127.0.0.1 >nul
            "%MYSQL%" -u root --connect-timeout=2 -e "SELECT 1;" >nul 2>&1
            if !errorlevel! equ 0 (
                set "MYSQL_READY=1"
                echo [DB] MySQL iniciado y respondiendo (intento %%i).
            )
        )
    )

    if "!MYSQL_READY!"=="0" (
        echo [ERROR] No se pudo conectar a MySQL despues de 15 segundos.
        exit /b 1
    )
)

:: 3. MODO: check (solo verifica si la base de datos existe)
if /i "%MODE%"=="check" (
    "%MYSQL%" -u root --connect-timeout=3 -e "USE servicio_tecnico;" >nul 2>&1
    if !errorlevel! equ 0 (
        echo [DB] La base de datos 'servicio_tecnico' ya existe.
        exit /b 0
    ) else (
        echo [DB] La base de datos 'servicio_tecnico' NO existe.
        exit /b 10
    )
)

:: 4. MODO: remove (usado por el desinstalador)
if /i "%MODE%"=="remove" (
    echo [DB] Eliminando base de datos 'servicio_tecnico' y usuarios...
    set "RM_SQL=%TEMP%\stpro_rm_%RANDOM%.sql"
    echo DROP DATABASE IF EXISTS servicio_tecnico; > "!RM_SQL!"
    echo DROP USER IF EXISTS 'st_user'@'localhost'; >> "!RM_SQL!"
    echo DROP USER IF EXISTS 'st_user'@'127.0.0.1'; >> "!RM_SQL!"
    echo FLUSH PRIVILEGES; >> "!RM_SQL!"
    "%MYSQL%" -u root < "!RM_SQL!" >nul 2>&1
    if exist "!RM_SQL!" del /f /q "!RM_SQL!" >nul 2>&1
    exit /b 0
)

:: 5. MODO: reinstall (limpieza previa antes de crear)
if /i "%MODE%"=="reinstall" (
    echo [DB] Limpiando base de datos previa...
    set "CLR_SQL=%TEMP%\stpro_clr_%RANDOM%.sql"
    echo DROP DATABASE IF EXISTS servicio_tecnico; > "!CLR_SQL!"
    echo DROP USER IF EXISTS 'st_user'@'localhost'; >> "!CLR_SQL!"
    echo DROP USER IF EXISTS 'st_user'@'127.0.0.1'; >> "!CLR_SQL!"
    echo FLUSH PRIVILEGES; >> "!CLR_SQL!"
    "%MYSQL%" -u root < "!CLR_SQL!" >nul 2>&1
    if exist "!CLR_SQL!" del /f /q "!CLR_SQL!" >nul 2>&1
)

:: 6. Creacion de la base de datos y usuario st_user
echo [DB] Configurando base de datos 'servicio_tecnico' y usuario 'st_user'...
set "INIT_SQL=%TEMP%\stpro_init_%RANDOM%.sql"
echo CREATE DATABASE IF NOT EXISTS servicio_tecnico CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci; > "!INIT_SQL!"
echo DROP USER IF EXISTS 'st_user'@'localhost'; >> "!INIT_SQL!"
echo DROP USER IF EXISTS 'st_user'@'127.0.0.1'; >> "!INIT_SQL!"
echo CREATE USER 'st_user'@'localhost' IDENTIFIED BY 'st_pass123'; >> "!INIT_SQL!"
echo CREATE USER 'st_user'@'127.0.0.1' IDENTIFIED BY 'st_pass123'; >> "!INIT_SQL!"
echo GRANT ALL PRIVILEGES ON servicio_tecnico.* TO 'st_user'@'localhost'; >> "!INIT_SQL!"
echo GRANT ALL PRIVILEGES ON servicio_tecnico.* TO 'st_user'@'127.0.0.1'; >> "!INIT_SQL!"
echo FLUSH PRIVILEGES; >> "!INIT_SQL!"

"%MYSQL%" -u root < "!INIT_SQL!"
set "INIT_ERR=!errorlevel!"
if exist "!INIT_SQL!" del /f /q "!INIT_SQL!" >nul 2>&1

if !INIT_ERR! neq 0 (
    echo [ERROR] No se pudo crear la base de datos o el usuario 'st_user' en MySQL (codigo: !INIT_ERR!).
    exit /b 2
)

:: 7. Importar esquema de tablas (schema.sql)
cd /d "%INSTALL_DIR%"
if not exist "schema.sql" (
    echo [ERROR] No se encontro schema.sql en "%INSTALL_DIR%".
    exit /b 3
)

echo [DB] Importando tablas desde schema.sql...
"%MYSQL%" -u root --default-character-set=utf8mb4 servicio_tecnico < "schema.sql"
if !errorlevel! neq 0 (
    echo [DB] Reintentando importacion con pipe...
    type "schema.sql" | "%MYSQL%" -u root --default-character-set=utf8mb4 servicio_tecnico
    if !errorlevel! neq 0 (
        echo [ERROR] Fallo al importar las tablas de schema.sql en MySQL.
        exit /b 3
    )
)

echo [OK] Base de datos 'servicio_tecnico' y usuario 'st_user' configurados exitosamente.
exit /b 0
