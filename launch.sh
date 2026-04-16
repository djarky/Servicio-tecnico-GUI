#!/bin/bash
# ST-PRO Web Launch Script (Linux/macOS)

echo "------------------------------------------"
echo "  ST-PRO: Iniciando Sistema de Servicio"
echo "------------------------------------------"

# Iniciar servidor PHP en segundo plano
php -S localhost:8080 > /dev/null 2>&1 &
PHP_PID=$!

echo "Servidor iniciado en http://localhost:8080 (Proceso: $PHP_PID)"
echo "Presiona Ctrl+C para detener el servidor."

# Esperar un segundo para asegurar el arranque
sleep 1

# Intentar abrir el navegador automáticamente
if which xdg-open > /dev/null; then
  xdg-open "http://localhost:8080"
elif which open > /dev/null; then
  open "http://localhost:8080"
else
  echo ">>> Por favor, abre tu navegador en: http://localhost:8080"
fi

# Mantener el script vivo para que el servidor no se cierre en algunos entornos
wait $PHP_PID
