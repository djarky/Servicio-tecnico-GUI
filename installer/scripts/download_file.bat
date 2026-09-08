@echo off
:: download_file.bat
:: Descarga archivos en Windows usando herramientas nativas de consola (CMD puro).
:: Prioridad: curl.exe -> powershell (con soporte TLS 1.2 y redirecciones) -> certutil -> bitsadmin
::
:: Uso: download_file.bat "<URL>" "<ARCHIVO_DESTINO>" [MIN_BYTES]

setlocal enabledelayedexpansion

set "URL=%~1"
set "DEST=%~2"
set "MIN_BYTES=%~3"

if "%URL%"=="" (
    echo [ERROR] Falta parametro URL.
    exit /b 1
)
if "%DEST%"=="" (
    echo [ERROR] Falta parametro DESTINO.
    exit /b 1
)
if "%MIN_BYTES%"=="" set "MIN_BYTES=50000"

:: Crear carpeta contenedora si no existe
for %%F in ("%DEST%") do (
    if not exist "%%~dpF" mkdir "%%~dpF" >nul 2>&1
)

:: Borrar archivo destino previo si existe
if exist "%DEST%" del /f /q "%DEST%" >nul 2>&1

:: ----------------------------------------------------------------------
:: Metodo 1: curl.exe (Nativo en Windows 10 build 1803+ y Windows 11)
:: Soporta redirecciones (-L), no guarda errores 404 (-f), timeout de conexion
:: ----------------------------------------------------------------------
where curl.exe >nul 2>&1
if %errorlevel% equ 0 (
    echo [DL] Descargando con curl (-L -f)...
    curl.exe -f -L -k --retry 3 --connect-timeout 20 -o "%DEST%" "%URL%"
    if exist "%DEST%" (
        for %%A in ("%DEST%") do (
            if %%~zA gtr %MIN_BYTES% (
                echo [OK] Descarga completada con curl (%%~zA bytes).
                exit /b 0
            ) else (
                echo [WARN] Archivo descargado demasiado pequeno (%%~zA bytes). Posible error HTTP.
                del /f /q "%DEST%" >nul 2>&1
            )
        )
    )
)

:: ----------------------------------------------------------------------
:: Metodo 2: PowerShell (Maneja redirecciones 302 de SourceForge y TLS 1.2)
:: ----------------------------------------------------------------------
where powershell.exe >nul 2>&1
if %errorlevel% equ 0 (
    echo [DL] Descargando con powershell (WebClient con TLS 1.2)...
    powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command ^
        "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls11 -bor [Net.SecurityProtocolType]::Tls; $wc = New-Object System.Net.WebClient; $wc.Headers.Add('User-Agent', 'Mozilla/5.0'); $wc.DownloadFile('%URL%', '%DEST%')" >nul 2>&1
    if exist "%DEST%" (
        for %%A in ("%DEST%") do (
            if %%~zA gtr %MIN_BYTES% (
                echo [OK] Descarga completada con powershell (%%~zA bytes).
                exit /b 0
            ) else (
                del /f /q "%DEST%" >nul 2>&1
            )
        )
    )
)

:: ----------------------------------------------------------------------
:: Metodo 3: bitsadmin.exe (Nativo en todas las versiones de Windows)
:: ----------------------------------------------------------------------
where bitsadmin.exe >nul 2>&1
if %errorlevel% equ 0 (
    echo [DL] Descargando con bitsadmin...
    bitsadmin.exe /transfer STPRODownload /download /priority FOREGROUND "%URL%" "%DEST%" >nul 2>&1
    if exist "%DEST%" (
        for %%A in ("%DEST%") do (
            if %%~zA gtr %MIN_BYTES% (
                echo [OK] Descarga completada con bitsadmin (%%~zA bytes).
                exit /b 0
            ) else (
                del /f /q "%DEST%" >nul 2>&1
            )
        )
    )
)

:: ----------------------------------------------------------------------
:: Metodo 4: certutil.exe (Nativo en Windows 7, 8, 8.1, 10, 11)
:: ----------------------------------------------------------------------
where certutil.exe >nul 2>&1
if %errorlevel% equ 0 (
    echo [DL] Descargando con certutil...
    certutil.exe -urlcache -split -f "%URL%" "%DEST%" >nul 2>&1
    if exist "%DEST%" (
        for %%A in ("%DEST%") do (
            if %%~zA gtr %MIN_BYTES% (
                echo [OK] Descarga completada con certutil (%%~zA bytes).
                certutil.exe -urlcache -split -f "%URL%" delete >nul 2>&1
                exit /b 0
            ) else (
                del /f /q "%DEST%" >nul 2>&1
            )
        )
    )
)

echo [ERROR] No se pudo descargar el archivo o el tamano obtenido fue invalido.
exit /b 1
