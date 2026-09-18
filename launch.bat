@echo off
:: ST-PRO Web Launch Script (Windows)

cd /d "%~dp0"

:: 1. Asegurar PHP y MySQL en el PATH de esta sesion
where php >nul 2>&1
if %errorlevel% neq 0 (
    if exist "C:\xampp\php\php.exe" (
        set "PATH=C:\xampp\php;C:\xampp\mysql\bin;%PATH%"
    )
)

:: 2. Limpiar duplicados de extensiones en php.ini si existen
if exist "C:\xampp\php\php.ini" (
    if exist "C:\xampp\php\php.exe" (
        "C:\xampp\php\php.exe" -r "$f='C:/xampp/php/php.ini';if(file_exists($f)){$lines=file($f);$seen=[];$exts=['curl','openssl','zip','pdo_mysql','mysqli','mbstring','fileinfo'];$out=[];$changed=false;foreach($lines as $l){$t=trim($l);$m=false;foreach($exts as $e){if(preg_match('/^[;]?\s*extension\s*=\s*(?:php_)?'.$e.'(?:\.dll)?\s*$/i',$t)){$m=true;if(!isset($seen[$e])){$seen[$e]=true;$out[]='extension='.$e.\"\r\n\";}else{$changed=true;}break;}}if(!$m){$out[]=$l;}}if($changed){file_put_contents($f,implode('',$out));}}" >nul 2>&1
    )
)

:: 3. Iniciar MySQL de XAMPP si no esta activo
if exist "C:\xampp\mysql_start.bat" (
    where mysql >nul 2>&1
    if %errorlevel% equ 0 (
        mysql -u root --connect-timeout=2 -e "SELECT 1;" >nul 2>&1
        if %errorlevel% neq 0 (
            start "" /b cmd /c "C:\xampp\mysql_start.bat" >nul 2>&1
            timeout /t 3 /nobreak >nul 2>&1
        )
    ) else (
        if exist "C:\xampp\mysql\bin\mysql.exe" (
            "C:\xampp\mysql\bin\mysql.exe" -u root --connect-timeout=2 -e "SELECT 1;" >nul 2>&1
            if %errorlevel% neq 0 (
                start "" /b cmd /c "C:\xampp\mysql_start.bat" >nul 2>&1
                timeout /t 3 /nobreak >nul 2>&1
            )
        )
    )
)

:: 4. Seleccionar puerto disponible (8080, 8081, 8082, 8000) de forma lineal
set PORT=8080

netstat -ano | findstr /R /C:":8080 " >nul 2>&1
if %errorlevel% neq 0 goto port_selected

netstat -ano | findstr /R /C:":8081 " >nul 2>&1
if %errorlevel% neq 0 (
    set PORT=8081
    goto port_selected
)

netstat -ano | findstr /R /C:":8082 " >nul 2>&1
if %errorlevel% neq 0 (
    set PORT=8082
    goto port_selected
)

set PORT=8000

:port_selected
set URL=http://localhost:%PORT%

:: 5. Detectar IP local
set LOCAL_IP=localhost
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /R /C:"IPv4 Address" /C:"Direcci"') do set LOCAL_IP=%%a
set LOCAL_IP=%LOCAL_IP: =%

:: 6. Mostrar informacion limpia al usuario ANTES de arrancar el servidor
echo ------------------------------------------
echo   ST-PRO: Iniciando Sistema de Servicio
echo ------------------------------------------
echo Servidor iniciado en el puerto %PORT%
echo Accesible localmente en: %URL%
if not "%LOCAL_IP%"=="localhost" (
    echo Accesible en tu red local: http://%LOCAL_IP%:%PORT%
)
echo Por favor, deja esta ventana abierta mientras usas la web.
echo ------------------------------------------
echo.

:: 7. Iniciar servidor PHP con startup warnings suprimidos para evitar texto corrupto en consola
start /b "" php -d display_startup_errors=0 -S 0.0.0.0:%PORT%

:: 8. Esperar 2 segundos para dar tiempo al arranque del servidor
timeout /t 2 >nul

:: 9. Abrir navegador predeterminado en la URL correcta (ej. http://localhost:8081 si 8080 estaba ocupado)
start "" "%URL%"

:: 10. Mantener la consola abierta mientras se usa la web
pause
