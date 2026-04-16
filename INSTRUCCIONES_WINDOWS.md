# Guía de Instalación y Uso para Windows (ST-PRO)

Esta guía te llevará paso a paso para instalar y ejecutar el sistema de Servicio Técnico (ST-PRO) en cualquier computadora con Windows, incluso si no tienes experiencia previa en programación.

---

## 1. Requisitos Previos

El sistema está construido en **PHP** y utiliza una base de datos **MySQL**. Para que tu computadora de Windows pueda procesar esto, necesitamos instalar algunos programas base. La forma más sencilla de instalar PHP y MySQL juntos es a través de **XAMPP**. También usaremos **Composer** para descargar utilidades del sistema (como la generación de PDFs).

### Paso 1.1: Descargar e Instalar XAMPP
1. Ve a la página oficial: [Descargar XAMPP](https://www.apachefriends.org/es/index.html)
2. Descarga la versión para Windows (preferiblemente que tenga PHP 8.x).
3. Ejecuta el instalador. Cuando te pregunte qué componentes instalar, asegúrate de marcar al menos: **Apache**, **MySQL** y **PHP**.
4. Instálalo en la ruta por defecto (normalmente `C:\xampp`).
5. **Importante:** Una vez instalado, abre el **Panel de Control de XAMPP** (XAMPP Control Panel) y presiona el botón **Start** al lado de "MySQL". Si se pone en verde, la base de datos está corriendo.

### Paso 1.2: Agregar PHP y MySQL a las Variables de Entorno (PATH)
Para que nuestros scripts automáticos (`install.bat`) puedan encontrar PHP y MySQL en tu sistema, debes agregarlos al PATH de Windows:
1. Abre el menú Inicio de Windows, escribe **"Variables de entorno"** y selecciona "Editar las variables de entorno del sistema".
2. En la ventana que se abre, abajo a la derecha, haz clic en **"Variables de entorno..."**.
3. En la sección "Variables del sistema" (la lista de abajo), busca la variable llamada **Path**, selecciónala y presiona **Editar**.
4. Haz clic en **Nuevo** y agrega la ruta de PHP (normalmente `C:\xampp\php`).
5. Haz clic en **Nuevo** y agrega la ruta de MySQL (normalmente `C:\xampp\mysql\bin`).
6. Presiona **Aceptar** en todas las ventanas para guardar los cambios.

### Paso 1.3: Descargar e Instalar Composer
Composer nos ayuda a instalar librerías.
1. Ve a [getcomposer.org/download](https://getcomposer.org/download/) y descarga el instalador de Windows (**Composer-Setup.exe**).
2. Ejecuta el instalador. Cuando te pida elegir el ejecutable de PHP, selecciona él que instalaste en XAMPP (`C:\xampp\php\php.exe`).
3. Termina la instalación (dale a "Siguiente" o "Next" hasta terminar).

---

## 2. Instalación del Sistema ST-PRO

Ahora que tu computadora tiene las herramientas necesarias, podemos instalar el sistema en sí.

1. Abre la carpeta donde tienes los archivos del sistema (donde están `install.bat`, `launch.bat`, etc.).
2. Haz **doble clic sobre el archivo `install.bat`**.
3. Se abrirá una ventana negra (consola / Símbolo del sistema). El script verificará que PHP, MySQL y Composer estén correctamente instalados.
4. Descargará automáticamente unas carpetas llamadas `vendor` (esto es la librería para generar los tickes en PDF) y creará la carpeta `uploads`.
5. El sistema te preguntará: **¿Desea resetear la base de datos? (s/n):**
   - Escribe **`s`** y presiona Enter (para que cree la base de datos).
6. Te preguntará el **Nombre de usuario de MySQL (ADMIN)**. Si instalaste XAMPP y no has cambiado nada, el usuario por defecto es **`root`**. Solo presiona **Enter** para dejarlo por defecto.
7. El sistema creará la base de datos `servicio_tecnico`, creará un usuario seguro llamado `st_user` y aplicará toda la estructura de tablas (`schema.sql`).
8. Finalmente, el script te pedirá **crear el Usuario Administrador** para entrar al sistema web:
   - **Ingresa tu nombre completo**: Ejemplo: *Juan Perez*
   - **Ingresa un nombre de usuario**: Ejemplo: *admin*
   - **Ingresa y confirma la contraseña**: (Escribe una clave que recuerdes para iniciar sesión).
9. El programa dirá "Instalación Completada!". Presiona cualquier tecla para cerrar esa ventana.

### Alternativa: Configurar la Base de Datos y un Usuario Personalizado Manualmente

Si por algún motivo el script anterior falla o quieres crear tu propio usuario con contraseña (`st_user` y `st_pass123`) manualmente, XAMPP te ofrece dos formas de hacerlo:

**Opción A: Ejecutar un comando SQL (Más rápido)**
1. Asegúrate de que MySQL y Apache estén encendidos en el panel de XAMPP.
2. Abre tu navegador y entra a: `http://localhost/phpmyadmin/`
3. Ve a la pestaña superior **SQL**.
4. Borra cualquier texto que haya ahí y pega exactamente este código:
```sql
CREATE DATABASE IF NOT EXISTS servicio_tecnico; 
CREATE USER 'st_user'@'localhost' IDENTIFIED BY 'st_pass123'; 
GRANT ALL PRIVILEGES ON servicio_tecnico.* TO 'st_user'@'localhost'; 
FLUSH PRIVILEGES;
```
5. Pulsa el botón **"Continuar"** en la esquina inferior derecha.

**Opción B: Usar la interfaz gráfica de ventanas**
1. Entra a `http://localhost/phpmyadmin/`.
2. Ve a la pestaña **Bases de datos**, escribe `servicio_tecnico` en el cuadro y presiona "Crear".
3. Ve a la pestaña **Cuentas de usuarios** y haz clic en **"Agregar cuenta de usuario"**.
4. Rellena los datos:
   - Nombre de usuario: `st_user`
   - Nombre del host: Selecciona `Local` (se pondrá `localhost`)
   - Contraseña: Tu contraseña (ej: `st_pass123`)
5. Baja un poco a la sección **Privilegios globales**, marca la casilla que dice **"Chequear todos"**.
6. Haz clic en **"Continuar"** al final de todo.

**Importante:** Recuerda que si creas tu propio usuario en PhpMyAdmin, debes abrir tu archivo `config.php` y actualizarlo con los datos nuevos:
```php
define('DB_USER', 'st_user'); // El usuario que creaste
define('DB_PASS', 'st_pass123'); // La contraseña que pusiste
```

---

## 3. Iniciar el Sistema Diariamente (launch.bat)

Cada vez que quieras abrir el programa para trabajar con él, no tienes que hacer todos los pasos de arriba, solo esto:

1. Asegúrate de que MySQL esté encendido (en el Panel de Control de XAMPP).
2. Ve a la carpeta de tu sistema y haz **doble clic en `launch.bat`**.
3. Esto encenderá el servidor interno de PHP. Verás una ventana negra que dice "Servidor iniciado". **NO cierres esta ventana negra mientras usas el programa.**
4. El script, después de 2 segundos, **abrirá tu navegador de internet automáticamente** (Chrome, Edge, etc.) en la dirección del programa, normalmente `http://localhost:8080`.
5. ¡Listo! Solo ingresa con el usuario y la contraseña que creaste en el paso de instalación.

---

## 4. Apagar el Sistema

Cuando termines tu jornada y quieras apagar el sistema:
1. Ve a la ventana negra que se abrió con `launch.bat` y aprieta cualquier tecla o simplemente ciérrala en la "X".
2. Cierra también tu navegador.
3. Si lo deseas, puedes detener MySQL desde el panel de XAMPP.

---

## Posibles Soluciones a Problemas (Troubleshooting)

- **"PHP / MySQL / Composer no se reconoce como un comando interno o externo"**
  Significa que el Paso 1.2 o 1.3 falló. Asegúrate de haber agregado XAMPP al PATH de Windows y reiniciado tu computadora para que aplique los cambios.
- **La base de datos no se conecta (Error de conexión / MySQL)**
  Confirma en tu XAMPP que MySQL está encendido (en verde) antes de ejecutar `install.bat` o `launch.bat`.
- **Puerto 8080 Ocupado**
  Si el sistema falla al iniciar `launch.bat` porque el puerto 8080 está en uso, puedes abrir el archivo `launch.bat` con un bloc de notas, cambiar donde dice `set PORT=8080` a otro número (ej. `set PORT=8085`), guardarlo y volver a probar.
