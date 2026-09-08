@echo off
:: setup_db.bat
:: Configura, detecta, repara o reinstala la base de datos MySQL para ST-PRO.
:: Argumentos:
::   %1: Ruta de instalacion de ST-PRO (donde esta schema.sql y update_db.php)
::   %2: Modo [check | repair | reinstall | fresh | remove] (por defecto: auto)

setlocal enabledelayedexpansion

set "INSTALL_DIR=%~1"
set "MODE=%~2"
set "MYSQL=C:\xampp\mysql\bin\mysql.exe"
set "PHP=C:\xampp\php\php.exe"

if "%INSTALL_DIR%"=="" set "INSTALL_DIR=C:\Program Files\ST-PRO"
if "%MODE%"=="" set "MODE=auto"

:: Localizar mysql.exe
if not exist "%MYSQL%" (
    where mysql >nul 2>&1
    if %errorlevel% equ 0 (
        set "MYSQL=mysql"
    ) else (
        echo [ERROR] mysql.exe no encontrado.
        exit /b 1
    )
)

:: ----------------------------------------------------------------------
:: Paso 1: Asegurar que MySQL este corriendo
:: ----------------------------------------------------------------------
call :CHECK_MYSQL_CONN
if not "%MYSQL_ALIVE%"=="1" (
    echo [DB] MySQL no responde. Intentando iniciar MySQL de XAMPP en segundo plano...
    if exist "C:\xampp\mysql_start.bat" (
        start "" /b cmd /c "C:\xampp\mysql_start.bat" >nul 2>&1
    ) else if exist "C:\xampp\mysql\bin\mysqld.exe" (
        start "" /b "C:\xampp\mysql\bin\mysqld.exe" --defaults-file="C:\xampp\mysql\bin\my.ini" --standalone >nul 2>&1
    )

    :: Esperar hasta 20 segundos a que MySQL arranque y acepte conexiones
    for /L %%i in (1,1,20) do (
        if not "!MYSQL_ALIVE!"=="1" (
            timeout /t 1 /nobreak >nul 2>&1
            call :CHECK_MYSQL_CONN
            if "!MYSQL_ALIVE!"=="1" (
                echo [DB] MySQL iniciado y respondiendo (en %%i segundos).
            )
        )
    )
)

if not "%MYSQL_ALIVE%"=="1" (
    echo [ERROR] MySQL no pudo ser iniciado o no responde en el puerto 3306.
    exit /b 1
)

:: ----------------------------------------------------------------------
:: MODO: check (verifica si la base de datos servicio_tecnico existe)
:: ----------------------------------------------------------------------
if /i "%MODE%"=="check" (
    "%MYSQL%" %ROOT_AUTH% --connect-timeout=5 -e "USE servicio_tecnico;" >nul 2>&1
    if %errorlevel% equ 0 (
        echo [DB] La base de datos 'servicio_tecnico' ya existe.
        exit /b 0
    ) else (
        echo [DB] La base de datos 'servicio_tecnico' NO existe.
        exit /b 10
    )
)

:: ----------------------------------------------------------------------
:: MODO: remove (usado por el desinstalador)
:: ----------------------------------------------------------------------
if /i "%MODE%"=="remove" (
    echo [DB] Eliminando base de datos servicio_tecnico y usuario st_user...
    "%MYSQL%" %ROOT_AUTH% -e "DROP DATABASE IF EXISTS servicio_tecnico; DROP USER IF EXISTS 'st_user'@'localhost'; DROP USER IF EXISTS 'st_user'@'127.0.0.1'; DROP USER IF EXISTS 'st_user'@'%%'; FLUSH PRIVILEGES;" >nul 2>&1
    exit /b 0
)

:: ----------------------------------------------------------------------
:: MODO: auto (detecta existencia y ejecuta repair o fresh)
:: ----------------------------------------------------------------------
if /i "%MODE%"=="auto" (
    "%MYSQL%" %ROOT_AUTH% --connect-timeout=5 -e "USE servicio_tecnico;" >nul 2>&1
    if %errorlevel% equ 0 (
        set "MODE=repair"
    ) else (
        set "MODE=fresh"
    )
)

:: ----------------------------------------------------------------------
:: MODO: reinstall (elimina base de datos previa y la crea limpia)
:: ----------------------------------------------------------------------
if /i "%MODE%"=="reinstall" (
    echo [DB] Reinstalando base de datos desde cero...
    "%MYSQL%" %ROOT_AUTH% -e "DROP DATABASE IF EXISTS servicio_tecnico; DROP USER IF EXISTS 'st_user'@'localhost'; DROP USER IF EXISTS 'st_user'@'127.0.0.1'; DROP USER IF EXISTS 'st_user'@'%%'; FLUSH PRIVILEGES;" >nul 2>&1
    set "MODE=fresh"
)

:: ----------------------------------------------------------------------
:: MODO: fresh o repair
:: ----------------------------------------------------------------------
echo [DB] Configurando base de datos 'servicio_tecnico' y credenciales de 'st_user'...

:: 1. Crear base de datos
"%MYSQL%" %ROOT_AUTH% -e "CREATE DATABASE IF NOT EXISTS servicio_tecnico CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"

:: 2. Crear y configurar usuario st_user para localhost, 127.0.0.1 y %
"%MYSQL%" %ROOT_AUTH% -e ^
  "CREATE USER IF NOT EXISTS 'st_user'@'localhost' IDENTIFIED BY 'st_pass123'; ALTER USER 'st_user'@'localhost' IDENTIFIED BY 'st_pass123'; GRANT ALL PRIVILEGES ON servicio_tecnico.* TO 'st_user'@'localhost'; CREATE USER IF NOT EXISTS 'st_user'@'127.0.0.1' IDENTIFIED BY 'st_pass123'; ALTER USER 'st_user'@'127.0.0.1' IDENTIFIED BY 'st_pass123'; GRANT ALL PRIVILEGES ON servicio_tecnico.* TO 'st_user'@'127.0.0.1'; CREATE USER IF NOT EXISTS 'st_user'@'%%' IDENTIFIED BY 'st_pass123'; ALTER USER 'st_user'@'%%' IDENTIFIED BY 'st_pass123'; GRANT ALL PRIVILEGES ON servicio_tecnico.* TO 'st_user'@'%%'; FLUSH PRIVILEGES;"

:: Compatibilidad MySQL 8+ (mysql_native_password si se requiere)
"%MYSQL%" %ROOT_AUTH% -e "ALTER USER 'st_user'@'localhost' IDENTIFIED WITH mysql_native_password BY 'st_pass123'; ALTER USER 'st_user'@'127.0.0.1' IDENTIFIED WITH mysql_native_password BY 'st_pass123'; FLUSH PRIVILEGES;" >nul 2>&1

:: 3. Importar schema.sql
if exist "%INSTALL_DIR%\schema.sql" (
    echo [DB] Importando estructura de tablas (schema.sql)...
    "%MYSQL%" %ROOT_AUTH% servicio_tecnico < "%INSTALL_DIR%\schema.sql"
)

:: 4. Ejecutar update_db.php si existe PHP
if exist "%PHP%" (
    if exist "%INSTALL_DIR%\update_db.php" (
        echo [DB] Aplicando actualizaciones de esquema con PHP...
        "%PHP%" "%INSTALL_DIR%\update_db.php" >nul 2>&1
    )
) else (
    where php >nul 2>&1
    if %errorlevel% equ 0 (
        if exist "%INSTALL_DIR%\update_db.php" (
            php "%INSTALL_DIR%\update_db.php" >nul 2>&1
        )
    )
)

echo [OK] Base de datos 'servicio_tecnico' y usuario 'st_user' listos y verificados.
exit /b 0

:: ======================================================================
:: Subrutina: Comprobar conexion con MySQL y detectar credencial root
:: ======================================================================
:CHECK_MYSQL_CONN
set "MYSQL_ALIVE=0"
set "ROOT_AUTH=-u root"

:: Intento 1: root sin contrasena (estandar XAMPP)
"%MYSQL%" -u root --connect-timeout=2 -e "SELECT 1;" >nul 2>&1
if %errorlevel% equ 0 (
    set "MYSQL_ALIVE=1"
    set "ROOT_AUTH=-u root"
    goto :eof
)

:: Intento 2: root con contrasenas comunes
for %%p in (root admin 1234 123456) do (
    "%MYSQL%" -u root -p%%p --connect-timeout=2 -e "SELECT 1;" >nul 2>&1
    if !errorlevel! equ 0 (
        set "MYSQL_ALIVE=1"
        set "ROOT_AUTH=-u root -p%%p"
        goto :eof
    )
)
goto :eof
