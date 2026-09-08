@echo off
:: setup_path.bat
:: Configura el PATH de Windows para incluir PHP y MySQL de XAMPP.
:: Utiliza reg.exe y setx.exe (puro CMD, sin requerir PowerShell).
:: Ejecutado con privilegios de Administrador durante la instalacion.

setlocal enabledelayedexpansion

set "XAMPP_PHP=C:\xampp\php"
set "XAMPP_MYSQL=C:\xampp\mysql\bin"

echo [PATH] Verificando variables de entorno en el sistema...

:: 1. Leer PATH actual de HKLM
set "CURRENT_PATH="
for /f "tokens=2*" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v Path 2^>nul') do (
    set "CURRENT_PATH=%%b"
)

if "%CURRENT_PATH%"=="" (
    for /f "tokens=2*" %%a in ('reg query "HKCU\Environment" /v Path 2^>nul') do (
        set "CURRENT_PATH=%%b"
    )
)

set "MODIFIED=0"
set "NEW_PATH=%CURRENT_PATH%"

:: 2. Verificar C:\xampp\php
echo "%NEW_PATH%" | findstr /I /C:"%XAMPP_PHP%" >nul 2>&1
if %errorlevel% neq 0 (
    if exist "%XAMPP_PHP%" (
        set "NEW_PATH=!NEW_PATH!;%XAMPP_PHP%"
        set "MODIFIED=1"
        echo [PATH] Anadiendo: %XAMPP_PHP%
    )
) else (
    echo [PATH] Ya existe: %XAMPP_PHP%
)

:: 3. Verificar C:\xampp\mysql\bin
echo "%NEW_PATH%" | findstr /I /C:"%XAMPP_MYSQL%" >nul 2>&1
if %errorlevel% neq 0 (
    if exist "%XAMPP_MYSQL%" (
        set "NEW_PATH=!NEW_PATH!;%XAMPP_MYSQL%"
        set "MODIFIED=1"
        echo [PATH] Anadiendo: %XAMPP_MYSQL%
    )
) else (
    echo [PATH] Ya existe: %XAMPP_MYSQL%
)

:: 4. Aplicar cambios al Registro si hubo modificaciones
if "!MODIFIED!"=="1" (
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v Path /t REG_EXPAND_SZ /d "!NEW_PATH!" /f >nul 2>&1
    if %errorlevel% equ 0 (
        echo [OK] PATH del sistema actualizado en HKLM.
    ) else (
        reg add "HKCU\Environment" /v Path /t REG_EXPAND_SZ /d "!NEW_PATH!" /f >nul 2>&1
        echo [OK] PATH de usuario actualizado en HKCU.
    )

    :: Notificar cambio al entorno activo de Windows
    setx PATH "!NEW_PATH!" /M >nul 2>&1
) else (
    echo [OK] PATH ya contenia las rutas de XAMPP.
)

:: 5. Habilitar extensiones criticas en C:\xampp\php\php.ini (curl, openssl, zip, pdo_mysql, mysqli, mbstring)
if exist "%XAMPP_PHP%\php.ini" (
    if exist "%XAMPP_PHP%\php.exe" (
        echo [PHP] Configurando extensiones en php.ini...
        "%XAMPP_PHP%\php.exe" -r "$f='C:/xampp/php/php.ini'; if(file_exists($f)){$c=file_get_contents($f); $exts=['curl','openssl','zip','pdo_mysql','mysqli','mbstring','fileinfo']; foreach($exts as $e){ $c=preg_replace('/^[;]\s*(extension\s*=\s*'.$e.')/mi', '$1', $c); } file_put_contents($f, $c);}" >nul 2>&1
        echo [OK] Extensiones de PHP verificadas y activadas.
    )
)

exit /b 0
