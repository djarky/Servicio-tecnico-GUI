@echo off
:: install_deps.bat - Instala las dependencias de Composer para ST-PRO (dompdf, etc.)
:: Retorna: 0 = Exito, 1 = Falta PHP, 2 = Fallo en Composer

setlocal enabledelayedexpansion

set "INSTALL_DIR=%~dp0"
if "%INSTALL_DIR:~-1%"=="\" set "INSTALL_DIR=%INSTALL_DIR:~0,-1%"

set "PHP=C:\xampp\php\php.exe"

cd /d "%INSTALL_DIR%"

echo [COMPOSER] Verificando PHP y Composer en: %INSTALL_DIR%

:: Si vendor/autoload.php ya existe, dependencias ya estan completas
if exist "%INSTALL_DIR%\vendor\autoload.php" (
    echo [OK] Dependencias ya instaladas en vendor/autoload.php.
    exit /b 0
)

if not exist "%PHP%" (
    where php >nul 2>&1
    if !errorlevel! equ 0 (
        set "PHP=php"
    ) else (
        echo [ERROR] No se encontro php.exe para ejecutar Composer.
        exit /b 1
    )
)

:: 1. Intentar con composer.phar en la carpeta de instalacion
if exist "%INSTALL_DIR%\composer.phar" (
    echo [COMPOSER] Ejecutando composer.phar install...
    "%PHP%" -d memory_limit=512M "%INSTALL_DIR%\composer.phar" install --no-dev --optimize-autoloader --no-interaction
    if !errorlevel! equ 0 goto check_vendor

    echo [COMPOSER] Probando composer.phar update...
    "%PHP%" -d memory_limit=512M "%INSTALL_DIR%\composer.phar" update --no-dev --optimize-autoloader --no-interaction
    if !errorlevel! equ 0 goto check_vendor
)

:: 2. Intentar con composer.phar en C:\xampp\php\
if exist "C:\xampp\php\composer.phar" (
    echo [COMPOSER] Ejecutando C:\xampp\php\composer.phar install...
    "%PHP%" -d memory_limit=512M "C:\xampp\php\composer.phar" install --no-dev --optimize-autoloader --no-interaction
    if !errorlevel! equ 0 goto check_vendor
)

:: 3. Intentar con comando composer global
where composer >nul 2>&1
if !errorlevel! equ 0 (
    echo [COMPOSER] Ejecutando composer global...
    call composer install --no-dev --optimize-autoloader --no-interaction
    if !errorlevel! equ 0 goto check_vendor

    call composer update --no-dev --optimize-autoloader --no-interaction
    if !errorlevel! equ 0 goto check_vendor
)

:check_vendor
if exist "%INSTALL_DIR%\vendor\autoload.php" (
    echo [OK] Dependencias instaladas correctamente (vendor/autoload.php existe).
    exit /b 0
)

echo [ERROR] No se pudo generar la carpeta vendor/. Fallo en la instalacion de dependencias.
exit /b 2
