; ============================================================
; ST-PRO - Servicio Tecnico - Instalador para Windows
; NSIS Modern UI 2 Script
;
; Compilar desde la carpeta installer/ con:
;   makensis setup.nsi
;   o usar build.sh en Linux/WSL
; ============================================================

Unicode True

; SetCompressor DEBE ir antes de cualquier !include o !insertmacro
SetCompressor /SOLID lzma

; ────────────────────────────────────────────────────────────
; DEFINICIONES
; ────────────────────────────────────────────────────────────
!define PRODUCT_NAME      "ST-PRO Servicio Tecnico"
!define PRODUCT_VERSION   "1.0.0"
!define PRODUCT_PUBLISHER "ST-PRO"
!define SHORTCUT_NAME     "ST-PRO - Servicio Tecnico"
!define UNINST_KEY        "Software\Microsoft\Windows\CurrentVersion\Uninstall\STPRO"

; URLs de descarga (versiones estables verificadas)
!define XAMPP_URL        "https://sourceforge.net/projects/xampp/files/XAMPP%20Windows/8.2.12/xampp-windows-x64-8.2.12-0-VS16-installer.exe/download"
!define XAMPP_MIRROR_URL "https://sitsa.dl.sourceforge.net/project/xampp/XAMPP%20Windows/8.2.12/xampp-windows-x64-8.2.12-0-VS16-installer.exe"
!define COMPOSER_URL     "https://getcomposer.org/Composer-Setup.exe"

; Rutas XAMPP por defecto
!define XAMPP_DIR      "C:\xampp"
!define XAMPP_PHP      "C:\xampp\php\php.exe"
!define XAMPP_MYSQL    "C:\xampp\mysql\bin\mysql.exe"
!define XAMPP_MYSQL_START "C:\xampp\mysql_start.bat"

; ────────────────────────────────────────────────────────────
; INCLUDES
; ────────────────────────────────────────────────────────────
!include "MUI2.nsh"
!include "LogicLib.nsh"

; ────────────────────────────────────────────────────────────
; CONFIGURACION MUI (Modern UI 2)
; ────────────────────────────────────────────────────────────
!define MUI_ABORTWARNING
!define MUI_ABORTWARNING_TEXT "¿Seguro que desea cancelar la instalacion de ST-PRO?"

!define MUI_ICON                        "assets\icon.ico"
!define MUI_UNICON                      "assets\icon.ico"

; Imagen lateral (164x314 px) en paginas de Bienvenida y Final
!define MUI_WELCOMEFINISHPAGE_BITMAP    "assets\banner.bmp"

; Imagen superior (150x57 px) en paginas interiores
!define MUI_HEADERIMAGE
!define MUI_HEADERIMAGE_BITMAP          "assets\header.bmp"
!define MUI_HEADERIMAGE_RIGHT

; Pagina de Bienvenida
!define MUI_WELCOMEPAGE_TITLE           "Bienvenido a ST-PRO"
!define MUI_WELCOMEPAGE_TEXT            "Este asistente instalara automaticamente todo lo necesario para usar ST-PRO:$\r$\n$\r$\n  • XAMPP 8.2  (PHP + MySQL)$\r$\n  • Composer   (librerias PDF)$\r$\n  • ST-PRO     (el sistema)$\r$\n$\r$\nSolo haz clic en Siguiente y espera.$\r$\nNo necesitas configurar nada manualmente.$\r$\n$\r$\nNecesitaras conexion a Internet si XAMPP$\r$\no Composer no estan instalados."

; Pagina de Finalizacion
!define MUI_FINISHPAGE_TITLE            "Instalacion Completada"
!define MUI_FINISHPAGE_TEXT             "ST-PRO ha sido instalado correctamente.$\r$\n$\r$\nEncuentra el icono 'ST-PRO' en tu Escritorio$\r$\ny haz doble clic para iniciar el sistema.$\r$\n$\r$\n¡Listo para trabajar!"
!define MUI_FINISHPAGE_RUN
!define MUI_FINISHPAGE_RUN_TEXT         "Iniciar ST-PRO ahora"
!define MUI_FINISHPAGE_RUN_FUNCTION     "LaunchSTPRO"
!define MUI_FINISHPAGE_LINK             "Abrir carpeta de instalacion"
!define MUI_FINISHPAGE_LINK_LOCATION    "$INSTDIR"

; Barra de progreso suave
!define MUI_INSTFILESPAGE_PROGRESSBAR  "smooth"

; ────────────────────────────────────────────────────────────
; PAGINAS DEL WIZARD
; ────────────────────────────────────────────────────────────
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_LICENSE "assets\license.txt"
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

; Paginas del desinstalador
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES

; Idioma Espanol
!insertmacro MUI_LANGUAGE "Spanish"

; ────────────────────────────────────────────────────────────
; ATRIBUTOS DEL INSTALADOR
; ────────────────────────────────────────────────────────────
Name                  "${PRODUCT_NAME} ${PRODUCT_VERSION}"
OutFile               "ST-PRO_Setup.exe"
InstallDir            "$PROGRAMFILES\ST-PRO"
InstallDirRegKey      HKLM "${UNINST_KEY}" "InstallLocation"
ShowInstDetails       show
RequestExecutionLevel admin
BrandingText          "ST-PRO ${PRODUCT_VERSION}"

; ────────────────────────────────────────────────────────────
; SECCION PRINCIPAL
; ────────────────────────────────────────────────────────────
Section "ST-PRO Servicio Tecnico" SEC01

  SetDetailsPrint both

  ; ─────────────────────────────────────────────────────────
  ; EXTRAER SCRIPTS AUXILIARES A TEMP
  ; (usamos puro CMD sin dependencias de PowerShell)
  ; ─────────────────────────────────────────────────────────
  SetOutPath "$TEMP\stpro_setup"
  File "scripts\download_file.bat"
  File "scripts\setup_path.bat"
  File "scripts\setup_db.bat"
  File "scripts\install_deps.bat"

  ; ═══════════════════════════════════════════════════════
  ; PASO 1 — Verificar / Instalar XAMPP
  ; ═══════════════════════════════════════════════════════
  DetailPrint "[ 1 / 7 ]  Verificando XAMPP..."

  IfFileExists "${XAMPP_PHP}" xampp_ok xampp_missing

  xampp_missing:
    DetailPrint "           Descargando XAMPP 8.2 (puede tardar varios minutos)..."
    nsExec::ExecToStack 'cmd /c ""$TEMP\stpro_setup\download_file.bat" "${XAMPP_URL}" "$TEMP\stpro_setup\xampp_installer.exe" 50000000"'
    Pop $R0
    Pop $1
    ${If} $R0 != 0
      DetailPrint "           Intentando servidor espejo de XAMPP..."
      nsExec::ExecToStack 'cmd /c ""$TEMP\stpro_setup\download_file.bat" "${XAMPP_MIRROR_URL}" "$TEMP\stpro_setup\xampp_installer.exe" 50000000"'
      Pop $R0
      Pop $1
    ${EndIf}
    ${If} $R0 != 0
      MessageBox MB_OK|MB_ICONSTOP "No se pudo descargar XAMPP (archivo incompleto o conexion interrumpida).$\r$\n$\r$\nPuede instalar XAMPP manualmente desde:$\r$\nhttps://www.apachefriends.org y volver a ejecutar el instalador."
      Abort
    ${EndIf}
    DetailPrint "           Instalando XAMPP silenciosamente (no cierre esta ventana)..."
    ExecWait '"$TEMP\stpro_setup\xampp_installer.exe" --mode unattended --prefix C:\xampp --launchapps 0' $R0
    ${If} $R0 != 0
      MessageBox MB_OK|MB_ICONSTOP "Error al instalar XAMPP (codigo: $R0).$\r$\nIntente instalar XAMPP manualmente desde apachefriends.org y luego ejecute este instalador de nuevo."
      Abort
    ${EndIf}
    DetailPrint "           XAMPP instalado correctamente en C:\xampp"
    Goto xampp_done

  xampp_ok:
    DetailPrint "           XAMPP ya detectado en C:\xampp"

  xampp_done:

  ; ═══════════════════════════════════════════════════════
  ; PASO 2 — Configurar PATH del sistema (CMD nativo)
  ; ═══════════════════════════════════════════════════════
  DetailPrint "[ 2 / 7 ]  Configurando variables de entorno (PATH)..."
  nsExec::ExecToStack 'cmd /c ""$TEMP\stpro_setup\setup_path.bat""'
  Pop $R0
  Pop $1
  DetailPrint "           PATH verificado y configurado (PHP + MySQL)."

  ; ═══════════════════════════════════════════════════════
  ; PASO 3 — Configurar Composer
  ; ═══════════════════════════════════════════════════════
  DetailPrint "[ 3 / 7 ]  Configurando Composer..."

  ; Extraer composer.phar en TEMP y en INSTDIR
  SetOutPath "$TEMP\stpro_setup"
  File "res\composer.phar"

  SetOutPath "$INSTDIR"
  File "res\composer.phar"

  ; Si existe C:\xampp\php\, copiar composer.phar y crear wrapper composer.bat
  IfFileExists "C:\xampp\php\*.*" 0 +6
    CopyFiles "$TEMP\stpro_setup\composer.phar" "C:\xampp\php\composer.phar"
    FileOpen $0 "C:\xampp\php\composer.bat" w
    FileWrite $0 "@echo off$\r$\n"
    FileWrite $0 '"C:\xampp\php\php.exe" -d memory_limit=512M "%~dp0composer.phar" %*$\r$\n'
    FileClose $0

  ; Crear composer.bat en la carpeta de instalacion
  FileOpen $0 "$INSTDIR\composer.bat" w
  FileWrite $0 "@echo off$\r$\n"
  FileWrite $0 '"C:\xampp\php\php.exe" -d memory_limit=512M "%~dp0composer.phar" %*$\r$\n'
  FileClose $0

  ; Probar que Composer funcione con PHP
  nsExec::ExecToStack 'cmd /c ""C:\xampp\php\php.exe" "$INSTDIR\composer.phar" --version"'
  Pop $R0
  Pop $1

  ${If} $R0 != 0
    ; Intentar descargar version fresca de composer.phar
    DetailPrint "           Descargando composer.phar desde getcomposer.org..."
    nsExec::ExecToStack 'cmd /c ""$TEMP\stpro_setup\download_file.bat" "https://getcomposer.org/composer.phar" "$INSTDIR\composer.phar" 1000000"'
    Pop $R0
    Pop $1

    nsExec::ExecToStack 'cmd /c ""C:\xampp\php\php.exe" "$INSTDIR\composer.phar" --version"'
    Pop $R0
    Pop $1
    ${If} $R0 != 0
      MessageBox MB_OK|MB_ICONSTOP "Error: Composer no pudo ejecutarse con PHP (código: $R0).$\r$\n$\r$\nAsegúrese de que PHP de XAMPP funcione y tenga la extensión OpenSSL habilitada.$\r$\nLa instalación se interrumpirá."
      Abort
    ${EndIf}
  ${EndIf}

  DetailPrint "           Composer verificado y listo."

  ; ═══════════════════════════════════════════════════════
  ; PASO 4 — Copiar archivos de ST-PRO a $INSTDIR
  ; ═══════════════════════════════════════════════════════
  DetailPrint "[ 4 / 7 ]  Copiando archivos de ST-PRO a $INSTDIR..."
  SetOutPath "$INSTDIR"

  ; Archivos del proyecto
  File "..\api.php"
  File "..\app.js"
  File "..\config.ini"
  File "..\config.php"
  File "..\index.php"
  File "..\migrate.php"
  File "..\print_order.php"
  File "..\schema.sql"
  File "..\styles.css"
  File "..\update_db.php"
  File "..\composer.json"
  File "..\composer.lock"

  ; Librerías vendor preempaquetadas (evita fallos de red/SSL/memory-limit durante el setup)
  SetOutPath "$INSTDIR\vendor"
  File /r "res\vendor\*"

  ; Directorios de imagenes y uploads
  SetOutPath "$INSTDIR\imagenes"
  File /r "..\imagenes\*"

  SetOutPath "$INSTDIR\capturas"
  File /r "..\capturas\*"

  CreateDirectory "$INSTDIR\uploads"

  ; Scripts de lanzamiento y herramientas en la carpeta de instalacion
  SetOutPath "$INSTDIR"
  File "res\launch.bat"
  File "res\silent_launch.vbs"
  File "assets\icon.ico"
  File "scripts\setup_db.bat"

  DetailPrint "           Archivos copiados a $INSTDIR"

  ; ═══════════════════════════════════════════════════════
  ; PASO 5 — Verificar e Instalar Dependencias PHP
  ; ═══════════════════════════════════════════════════════
  DetailPrint "[ 5 / 7 ]  Verificando dependencias PHP (vendor/autoload.php)..."

  IfFileExists "$INSTDIR\vendor\autoload.php" deps_ok deps_install

  deps_install:
    DetailPrint "           Generando dependencias adicionales con Composer..."
    CopyFiles "$TEMP\stpro_setup\install_deps.bat" "$INSTDIR\install_deps.bat"
    nsExec::ExecToStack 'cmd /c ""$INSTDIR\install_deps.bat""'
    Pop $R0
    Pop $1
    Delete "$INSTDIR\install_deps.bat"

    ${If} $R0 != 0
      ${Unless} ${FileExists} "$INSTDIR\vendor\autoload.php"
        MessageBox MB_OK|MB_ICONSTOP "Error al instalar dependencias de Composer (código: $R0).$\r$\n$\r$\nDetalle del error:$\r$\n$1$\r$\n$\r$\nVerifique su conexión a Internet o el servicio de PHP.$\r$\nLa instalación se interrumpirá."
        Abort
      ${EndUnless}
    ${EndIf}

  deps_ok:
    DetailPrint "           Dependencias de Composer verificadas y listas (vendor/ OK)."

  ; ═══════════════════════════════════════════════════════
  ; PASO 6 — Iniciar MySQL y Configurar Base de Datos
  ; ═══════════════════════════════════════════════════════
  DetailPrint "[ 6 / 7 ]  Iniciando MySQL y configurando base de datos..."

  ; setup_db.bat inicia MySQL y verifica conexion
  nsExec::ExecToStack 'cmd /c ""$TEMP\stpro_setup\setup_db.bat" "$INSTDIR" check"'
  Pop $R0
  Pop $1

  ${If} $R0 == 1
    MessageBox MB_OK|MB_ICONSTOP "Error: No se pudo conectar al servidor MySQL de XAMPP (puerto 3306).$\r$\n$\r$\nDetalle:$\r$\n$1$\r$\n$\r$\nAsegúrese de que el servicio MySQL pueda iniciar en su PC y que el puerto 3306 no esté bloqueado.$\r$\n$\r$\nLa instalación se interrumpirá."
    Abort
  ${EndIf}

  ${If} $R0 == 0
    ; La base de datos YA EXISTE: Consultar al usuario
    MessageBox MB_YESNO|MB_ICONQUESTION \
      "Se ha detectado una base de datos existente de ST-PRO ('servicio_tecnico').$\r$\n$\r$\n¿Desea CONSERVAR y reparar sus datos actuales?$\r$\n$\r$\n• Sí = Conservar clientes, órdenes y registros (recomendado).$\r$\n• No = Reinstalar desde cero (se eliminarán los datos existentes)." \
      IDYES db_do_repair IDNO db_do_reinstall

    db_do_repair:
      DetailPrint "           Reparando base de datos y conservando registros..."
      nsExec::ExecToStack 'cmd /c ""$TEMP\stpro_setup\setup_db.bat" "$INSTDIR" repair"'
      Pop $R0
      Pop $1
      Goto db_eval_result

    db_do_reinstall:
      DetailPrint "           Reinstalando base de datos desde cero..."
      nsExec::ExecToStack 'cmd /c ""$TEMP\stpro_setup\setup_db.bat" "$INSTDIR" reinstall"'
      Pop $R0
      Pop $1
      Goto db_eval_result

  ${Else}
    ; Base de datos nueva: instalacion limpia
    DetailPrint "           Creando base de datos e importando esquema inicial..."
    nsExec::ExecToStack 'cmd /c ""$TEMP\stpro_setup\setup_db.bat" "$INSTDIR" fresh"'
    Pop $R0
    Pop $1
  ${EndIf}

  db_eval_result:
  ${If} $R0 != 0
    DetailPrint "           Error en MySQL: $1"
    MessageBox MB_OK|MB_ICONSTOP "Error al configurar la base de datos MySQL (código: $R0).$\r$\n$\r$\nDetalle del error:$\r$\n$1$\r$\n$\r$\nNo se pudo crear la base de datos 'servicio_tecnico' o el usuario 'st_user'.$\r$\nLa instalación se interrumpirá."
    Abort
  ${EndIf}

  DetailPrint "           Base de datos 'servicio_tecnico' y usuario 'st_user' listos."

  ; ═══════════════════════════════════════════════════════
  ; PASO 7 — Acceso directo en el Escritorio (apunta a launch.bat)
  ; ═══════════════════════════════════════════════════════
  DetailPrint "[ 7 / 7 ]  Creando acceso directo en el Escritorio..."

  ; Establecer directorio de trabajo a $INSTDIR
  SetOutPath "$INSTDIR"

  ; Acceso directo en el Escritorio apuntando directamente a launch.bat en la carpeta de instalacion
  CreateShortcut "$DESKTOP\${SHORTCUT_NAME}.lnk" \
    "$INSTDIR\launch.bat" \
    "" \
    "$INSTDIR\icon.ico" 0 \
    SW_SHOWNORMAL "" "${PRODUCT_NAME}"

  ; Accesos directos en el Menu Inicio
  CreateDirectory "$SMPROGRAMS\ST-PRO"
  CreateShortcut "$SMPROGRAMS\ST-PRO\${SHORTCUT_NAME}.lnk" \
    "$INSTDIR\launch.bat" \
    "" \
    "$INSTDIR\icon.ico" 0 \
    SW_SHOWNORMAL "" "${PRODUCT_NAME}"

  CreateShortcut "$SMPROGRAMS\ST-PRO\Desinstalar ST-PRO.lnk" \
    "$INSTDIR\Uninstall.exe" "" "$INSTDIR\icon.ico" 0

  ; ─────────────────────────────────────────────────────────
  ; Registro de desinstalacion en Windows
  ; ─────────────────────────────────────────────────────────
  WriteUninstaller "$INSTDIR\Uninstall.exe"
  WriteRegStr   HKLM "${UNINST_KEY}" "DisplayName"      "${PRODUCT_NAME}"
  WriteRegStr   HKLM "${UNINST_KEY}" "UninstallString"  '"$INSTDIR\Uninstall.exe"'
  WriteRegStr   HKLM "${UNINST_KEY}" "InstallLocation"  "$INSTDIR"
  WriteRegStr   HKLM "${UNINST_KEY}" "DisplayVersion"   "${PRODUCT_VERSION}"
  WriteRegStr   HKLM "${UNINST_KEY}" "Publisher"        "${PRODUCT_PUBLISHER}"
  WriteRegStr   HKLM "${UNINST_KEY}" "DisplayIcon"      "$INSTDIR\icon.ico"
  WriteRegDWORD HKLM "${UNINST_KEY}" "NoModify"         1
  WriteRegDWORD HKLM "${UNINST_KEY}" "NoRepair"         1

  DetailPrint "           Acceso directo creado: $INSTDIR\launch.bat"
  DetailPrint ""
  DetailPrint "==========================================="
  DetailPrint "  ¡ST-PRO instalado correctamente!"
  DetailPrint "  Doble clic en el icono del Escritorio"
  DetailPrint "  para iniciar el sistema."
  DetailPrint "==========================================="

SectionEnd

; ────────────────────────────────────────────────────────────
; FUNCION: Lanzar ST-PRO al terminar el wizard
; ────────────────────────────────────────────────────────────
Function LaunchSTPRO
  SetOutPath "$INSTDIR"
  Exec '"$INSTDIR\launch.bat"'
FunctionEnd

; ────────────────────────────────────────────────────────────
; SECCION DE DESINSTALACION
; ────────────────────────────────────────────────────────────
Section "Uninstall"

  ; Preguntar si desea eliminar la base de datos de MySQL
  MessageBox MB_YESNO|MB_ICONQUESTION \
    "¿Desea eliminar también la base de datos 'servicio_tecnico' de MySQL y el usuario 'st_user'?$\r$\n$\r$\n• Sí = Eliminar por completo la base de datos de MySQL.$\r$\n• No = Conservar los datos para futuras instalaciones." \
    IDNO skip_db_removal

  DetailPrint "Eliminando base de datos de MySQL..."
  nsExec::Exec 'cmd /c "if exist C:\xampp\mysql\bin\mysql.exe C:\xampp\mysql\bin\mysql.exe -u root -e \"DROP DATABASE IF EXISTS servicio_tecnico; DROP USER IF EXISTS ''st_user''@''localhost''; FLUSH PRIVILEGES;\""'

  skip_db_removal:

  ; Borrar accesos directos
  Delete "$DESKTOP\${SHORTCUT_NAME}.lnk"
  Delete "$SMPROGRAMS\ST-PRO\${SHORTCUT_NAME}.lnk"
  Delete "$SMPROGRAMS\ST-PRO\Desinstalar ST-PRO.lnk"
  RMDir  "$SMPROGRAMS\ST-PRO"

  ; Borrar directorio de instalacion
  Delete "$INSTDIR\Uninstall.exe"
  RMDir /r "$INSTDIR"

  ; Borrar registros
  DeleteRegKey HKLM "${UNINST_KEY}"

  MessageBox MB_OK "ST-PRO ha sido desinstalado correctamente."

SectionEnd
