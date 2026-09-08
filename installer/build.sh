#!/usr/bin/env bash
# build.sh - Compila el instalador ST-PRO para Windows
#
# REQUISITOS (Ubuntu/Debian):
#   sudo apt install nsis nsis-pluginapi imagemagick
#
# REQUISITOS (macOS):
#   brew install makensis imagemagick
#
# USO: Ejecutar desde dentro de la carpeta installer/
#   cd installer/
#   chmod +x build.sh && ./build.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "=============================================="
echo "  ST-PRO - Compilando Instalador para Windows"
echo "=============================================="
echo ""

# ── Verificar makensis ───────────────────────────────────────
if ! command -v makensis &>/dev/null; then
    echo "[ERROR] makensis no encontrado."
    echo "        Instalar con: sudo apt install nsis"
    exit 1
fi

# ── Verificar ImageMagick (para convertir PNG → BMP/ICO) ────
HAS_CONVERT=0
if command -v convert &>/dev/null; then
    HAS_CONVERT=1
fi

mkdir -p assets

# ── Convertir imagenes PNG → BMP (NSIS necesita BMP) ────────
echo "[IMG] Preparando imágenes del wizard..."

if [ $HAS_CONVERT -eq 1 ]; then

    # banner.bmp: imagen lateral del wizard (164x314 px, 24-bit BMP)
    if [ -f "assets/banner.png" ] && [ ! -f "assets/banner.bmp" ]; then
        convert "assets/banner.png" -resize 164x314! -type TrueColor -compress none BMP3:"assets/banner.bmp"
        echo "       banner.png → banner.bmp"
    fi

    # header.bmp: imagen de cabecera (150x57 px, 24-bit BMP)
    if [ -f "assets/header.png" ] && [ ! -f "assets/header.bmp" ]; then
        convert "assets/header.png" -resize 150x57! -type TrueColor -compress none BMP3:"assets/header.bmp"
        echo "       header.png → header.bmp"
    fi

    # icon.ico: ícono del instalador (multi-tamaño)
    if [ -f "assets/icon.png" ] && [ ! -f "assets/icon.ico" ]; then
        convert "assets/icon.png" -define icon:auto-resize=256,128,64,48,32,16 "assets/icon.ico"
        echo "       icon.png → icon.ico"
    fi

else
    echo "[WARN] ImageMagick no encontrado. Las imágenes deben existir ya como .bmp e .ico"
    echo "       sudo apt install imagemagick"
fi

# ── Asegurar composer.phar empaquetado ───────────────────────
if [ ! -f "res/composer.phar" ]; then
    echo "[COMP] Descargando composer.phar para empaquetarlo en el instalador..."
    curl -s -L -o "res/composer.phar" "https://getcomposer.org/composer.phar"
fi

# ── Asegurar librerias vendor preempaquetadas ────────────────
if [ ! -f "res/vendor/autoload.php" ]; then
    echo "[VEND] Preparando dependencias vendor para empaquetado..."
    if [ -f "../vendor/autoload.php" ]; then
        cp -r ../vendor res/vendor
    else
        php res/composer.phar install -d .. --no-dev --optimize-autoloader --no-interaction
        cp -r ../vendor res/vendor
    fi
fi

# ── Verificar archivos requeridos ───────────────────────────
echo ""
echo "[CHECK] Verificando archivos necesarios..."

REQUIRED_FILES=(
    "setup.nsi"
    "assets/banner.bmp"
    "assets/header.bmp"
    "assets/icon.ico"
    "assets/license.txt"
    "scripts/setup_path.bat"
    "scripts/setup_db.bat"
    "scripts/download_file.bat"
    "scripts/install_deps.bat"
    "res/launch.bat"
    "res/silent_launch.vbs"
    "res/composer.phar"
    "res/vendor/autoload.php"
    "../api.php"
    "../schema.sql"
    "../composer.json"
)

MISSING=0
for f in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "$f" ]; then
        echo "       [FALTA] $f"
        MISSING=$((MISSING + 1))
    else
        echo "       [OK]    $f"
    fi
done

if [ $MISSING -gt 0 ]; then
    echo ""
    echo "[ERROR] Faltan $MISSING archivo(s). Revisa la lista anterior."
    exit 1
fi

# ── Compilar con NSIS ───────────────────────────────────────
echo ""
echo "[BUILD] Compilando setup.nsi con makensis..."
echo ""

makensis setup.nsi

echo ""
echo "=============================================="
echo "  Instalador generado: ST-PRO_Setup.exe"
echo "=============================================="
ls -lh ST-PRO_Setup.exe 2>/dev/null || true
echo ""
echo "  Probarlo en Windows con:"
echo "    wine ST-PRO_Setup.exe   (si tienes wine)"
echo "    o copia el .exe a una VM Windows"
echo "=============================================="
