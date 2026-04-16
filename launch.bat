@echo off
:: ST-PRO Web Launch Script (Windows)

set PORT=8080
set URL=http://localhost:%PORT%

echo ------------------------------------------
echo   ST-PRO: Iniciando Sistema de Servicio
echo ------------------------------------------

:: Iniciar servidor PHP de forma asíncrona
start /b "" php -S localhost:%PORT%

echo Servidor iniciado en %URL%
echo Por favor, deja esta ventana abierta mientras usas la web.
echo.

:: Esperar 2 segundos para dar tiempo al arranque del servidor
timeout /t 2 >nul

:: Abrir navegador predeterminado
start "" "%URL%"

:: Mantener la consola abierta para ver log y poder cerrarlo
pause
