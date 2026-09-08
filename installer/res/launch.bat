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

:: 2. Iniciar MySQL automaticamente si no esta activo
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

:: 3. Verificar si la base de datos y st_user responden; si no, auto-reparar
if exist "%~dp0setup_db.bat" (
    if exist "C:\xampp\mysql\bin\mysql.exe" (
        "C:\xampp\mysql\bin\mysql.exe" -u st_user -pst_pass123 -h 127.0.0.1 --connect-timeout=2 -e "USE servicio_tecnico;" >nul 2>&1
        if errorlevel 1 (
            call "%~dp0setup_db.bat" "%~dp0" repair >nul 2>&1
        )
    ) else (
        where mysql >nul 2>&1
        if %errorlevel% equ 0 (
            mysql -u st_user -pst_pass123 -h 127.0.0.1 --connect-timeout=2 -e "USE servicio_tecnico;" >nul 2>&1
            if errorlevel 1 (
                call "%~dp0setup_db.bat" "%~dp0" repair >nul 2>&1
            )
        )
    )
)

:: 4. Limpiar procesos previos huerfanos de php.exe que puedan tener el puerto 8080
set PORT=8080
for /f "tokens=5" %%a in ('netstat -ano ^| findstr /R /C:":8080 " 2^>nul') do (
    tasklist /fi "PID eq %%a" 2^>nul | findstr /i "php.exe" >nul 2>&1
    if not errorlevel 1 (
        taskkill /f /pid %%a >nul 2>&1
        timeout /t 1 /nobreak >nul 2>&1
    )
)

:: 5. Si 8080 sigue ocupado por otro servicio, buscar un puerto libre alternativo
netstat -ano | findstr /R /C:":8080 " >nul 2>&1
if %errorlevel% equ 0 (
    netstat -ano | findstr /R /C:":8081 " >nul 2>&1
    if errorlevel 1 (
        set PORT=8081
    ) else (
        netstat -ano | findstr /R /C:":8082 " >nul 2>&1
        if errorlevel 1 (
            set PORT=8082
        ) else (
            set PORT=8000
        )
    )
)

set URL=http://localhost:%PORT%

echo ------------------------------------------
echo   ST-PRO: Iniciando Sistema de Servicio
echo ------------------------------------------

:: 6. Iniciar servidor PHP de forma asincrona
start /b "" php -S 0.0.0.0:%PORT%

:: Detectar IP local
set LOCAL_IP=localhost
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /R /C:"IPv4 Address" /C:"Direcci"') do set LOCAL_IP=%%a
set LOCAL_IP=%LOCAL_IP: =%

echo Servidor iniciado en el puerto %PORT%
echo Accesible localmente en: %URL%
if not "%LOCAL_IP%"=="localhost" (
    echo Accesible en tu red local: http://%LOCAL_IP%:%PORT%
)
echo Por favor, deja esta ventana abierta mientras usas la web.
echo.

:: Esperar 2 segundos para dar tiempo al arranque del servidor
timeout /t 2 >nul

:: Abrir navegador predeterminado
start "" "%URL%"

:: Mantener la consola abierta para ver log y poder cerrarlo
pause

:: 7. Al presionar una tecla para salir, cerrar limpiamente el proceso PHP de esta sesion
for /f "tokens=5" %%a in ('netstat -ano ^| findstr /R /C:":%PORT% " 2^>nul') do (
    tasklist /fi "PID eq %%a" 2^>nul | findstr /i "php.exe" >nul 2>&1
    if not errorlevel 1 (
        taskkill /f /pid %%a >nul 2>&1
    )
)
