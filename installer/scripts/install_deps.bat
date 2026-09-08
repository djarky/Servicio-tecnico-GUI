@echo off
:: install_deps.bat
:: Instala las dependencias de Composer (dompdf, etc.) para ST-PRO.
:: Se ejecuta desde el directorio de instalacion de ST-PRO.

setlocal

set "PHP=C:\xampp\php\php.exe"
set "COMPOSER_PHAR=C:\ProgramData\ComposerSetup\bin\composer.phar"
set "COMPOSER_BAT=C:\ProgramData\ComposerSetup\bin\composer.bat"
set "INSTALL_DIR=%~dp0"

cd /d "%INSTALL_DIR%"

echo [COMP] Instalando dependencias PHP en: %INSTALL_DIR%

:: Intentar con composer.bat (instalacion global de Composer)
if exist "%COMPOSER_BAT%" (
    call "%COMPOSER_BAT%" install --no-dev --optimize-autoloader --no-interaction 2>&1
    goto done
)

:: Intentar con composer.phar directamente
if exist "%COMPOSER_PHAR%" (
    "%PHP%" "%COMPOSER_PHAR%" install --no-dev --optimize-autoloader --no-interaction 2>&1
    goto done
)

:: Ultimo recurso: buscar composer en PATH
where composer >nul 2>&1
if %errorlevel% equ 0 (
    composer install --no-dev --optimize-autoloader --no-interaction 2>&1
    goto done
)

echo [WARN] Composer no encontrado. Las dependencias PHP (dompdf) no se instalaron.
echo [WARN] La generacion de PDFs puede no funcionar.

:done
echo [COMP] Proceso de dependencias completado.
exit /b 0
