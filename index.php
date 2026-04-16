<?php 
require_once 'config.php'; 
// Fix API error responses printing inside HTML
if (isset($_GET['action'])) { /* skip */ } else {
    // We override json header if it gets called from getDbConnection inside index
    header_remove('Content-Type');
}

$db = getDbConnection();
header('Content-Type: text/html'); // Reset properly

global $DB_CONNECTION_ERROR, $config;
if (!$db) {
    echo '<!DOCTYPE html><html lang="es"><head><meta charset="UTF-8"><title>Error de Sistema</title><link rel="stylesheet" href="styles.css"></head><body>';
    echo '<div id="login-overlay" style="display:flex;">';
    echo '<div class="card login-card" style="width: 450px; border-left: 5px solid #ef4444;">';
    echo '<h2 style="color: #ef4444; margin-bottom: 1rem;"><i class="fas fa-exclamation-triangle"></i> Fallo de Base de Datos</h2>';
    echo '<p style="color:#555; text-align:justify; margin-bottom:1rem;">El sistema no pudo conectarse a MySQL / MariaDB. Por favor, asegúrate de haber ejecutado <b>install.bat</b> (en Windows) o <b>install.sh</b> (en Linux) y de que tus credenciales de base de datos sean correctas en <code>config.ini</code>.</p>';
    echo '<div style="background:#fef2f2; padding:10px; border:1px solid #fca5a5; font-size:0.85rem; color:#b91c1c;"><b>Error:</b> '.htmlspecialchars($DB_CONNECTION_ERROR).'</div>';
    echo '<button class="btn btn-primary" style="width: 100%; margin-top: 1rem; background:#333;" onclick="window.location.reload()"><i class="fas fa-sync"></i> Reintentar Conexión</button>';
    echo '</div></div></body></html>';
    exit;
}

$stmt = $db->query("SELECT COUNT(*) FROM usuarios");
$userCount = $stmt ? $stmt->fetchColumn() : 0;
$isSetup = ($userCount == 0);
?>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Servicio Técnico - Pro</title>
    <link rel="stylesheet" href="styles.css">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css">
    <!-- Flatpickr -->
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/flatpickr/dist/flatpickr.min.css">
    <!-- Chart.js -->
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
</head>
<body>
    <!-- Setup Overlay -->
    <div id="setup-overlay" style="display: <?= $isSetup ? 'flex' : 'none' ?>;">
        <div class="card login-card" style="width: 330px;">
            <div style="text-align: center; margin-bottom: 1rem;">
                <img src="imagenes/logo.png" alt="Logo" style="width: 80px; height: 80px; object-fit: cover; border-radius: 50%; border: 2px solid #2563eb; padding: 2px; background: white;">
            </div>
            <h2 style="text-align: center; margin-bottom: 0.5rem; color: #2563eb;">Bienvenido</h2>
            <p style="text-align: center; font-size: 0.85rem; margin-bottom: 1.5rem; color: #555;">No hay usuarios en la base de datos.<br>Crea el Administrador primario.</p>
            <form id="setup-form">
                <div class="form-group">
                    <label>Nombre Completo</label>
                    <input type="text" id="setup-name" required placeholder="Ej: Juan Perez">
                </div>
                <div class="form-group">
                    <label>Usuario Login</label>
                    <input type="text" id="setup-user" required placeholder="admin">
                </div>
                <div class="form-group">
                    <label>Contraseña</label>
                    <input type="password" id="setup-pass" required>
                </div>
                <button type="submit" class="btn btn-primary" style="width: 100%; background: #16a34a;">Registrar y Entrar</button>
                <div id="setup-error" style="color: #ef4444; margin-top: 1rem; font-size: 0.875rem; text-align: center; display: none;"></div>
            </form>
        </div>
    </div>

    <!-- Login Overlay -->
    <div id="login-overlay" style="display: <?= (!$isSetup && !isset($_SESSION['user_id'])) ? 'flex' : 'none' ?>;">
        <div class="card login-card">
            <div style="text-align: center; margin-bottom: 1rem;">
                <img src="imagenes/logo.png" alt="Logo" style="width: 80px; height: 80px; object-fit: cover; border-radius: 50%; border: 2px solid #333; padding: 2px; background: white;">
            </div>
            <h2 style="text-align: center; margin-bottom: 2rem;">Iniciar Sesión</h2>
            <form id="login-form">
                <div class="form-group">
                    <label>Usuario</label>
                    <input type="text" id="login-user" required placeholder="admin">
                </div>
                <div class="form-group">
                    <label>Contraseña</label>
                    <input type="password" id="login-pass" required placeholder="password">
                </div>
                <button type="submit" class="btn btn-primary" style="width: 100%;">Ingresar</button>
                <div id="login-error" style="color: #ef4444; margin-top: 1rem; font-size: 0.875rem; text-align: center; display: none;"></div>
            </form>
        </div>
    </div>

    <!-- Main Window Form -->
    <div class="win-form" style="display: <?= (!$isSetup && isset($_SESSION['user_id'])) ? 'block' : 'none' ?>;" id="main-win-form">
        <!-- Form Area -->
        <div class="win-body">
            
            <div class="top-section">
                <!-- LEfT: Logo/User area -->
                <div class="profile-logo">
                    <div class="logo-box">
                        <img src="imagenes/logo.png" alt="Servicio Técnico Logo" id="user-avatar-img" style="width: 100%; height: 100%; object-fit: cover;">
                    </div>
                </div>

                <!-- MIDDLE: Main Form Panels -->
                <div class="main-form-panels">
                    
                    <!-- DATOS DEL CLIENTE -->
                    <div class="win-panel">
                        <div class="panel-title">DATOS DEL CLIENTE</div>
                        <div class="panel-content">
                            <div class="f-row">
                                <label class="lbl-right" style="width: 130px;">ORDEN DE SERVICIO:</label>
                                <input type="text" id="f-id-orden" style="width: 60px;" readonly>
                                <i class="fas fa-barcode barcode-icon"></i>
                                <label class="lbl-right">FECHA:</label>
                                <div class="d-input-group" style="width: 100px;">
                                    <input type="text" id="f-fecha" value="<?= date('d/m/Y') ?>" style="width: 80px;">
                                    <button type="button" class="btn-cal" onclick="openPicker('f-fecha')"><i class="far fa-calendar-alt"></i></button>
                                </div>
                            </div>
                            <div class="f-row mt-1">
                                <label class="lbl-right" style="width: 130px;">DOCUMENTO:</label>
                                <input type="text" id="f-documento" style="width: 130px;" required>
                                <label class="lbl-right">TELEFONO:</label>
                                <input type="text" id="f-telefono" style="flex: 1;">
                            </div>
                            <div class="f-row mt-1">
                                <label class="lbl-right" style="width: 130px;">NOMBRE Y APELLIDO:</label>
                                <input type="text" id="f-nombre" style="flex: 1;" required>
                            </div>
                            <div class="f-row mt-1">
                                <label class="lbl-right" style="width: 130px;">DIRECCION O CORREO E:</label>
                                <input type="text" id="f-direccion" style="flex: 1;">
                            </div>
                        </div>
                    </div>

                    <!-- DATOS DEL EQUIPO -->
                    <div class="win-panel mt-1">
                        <div class="panel-title">DATOS DEL EQUIPO</div>
                        <div class="panel-content">
                            <div class="f-row" style="margin-bottom: 8px;">
                                <div class="equip-type-box">
                                    <span style="position: absolute; top: -7px; left: 5px; background: #f0f0f0; padding: 0 4px; font-size: 11px;">Tipo de equipo</span>
                                     <label><input type="radio" name="f-tipo" value="Celular"> Celular</label>
                                     <label><input type="radio" name="f-tipo" value="Tablet"> Tablet</label>
                                     <label><input type="radio" name="f-tipo" value="Laptop"> Laptop</label>
                                     <label><input type="radio" name="f-tipo" value="Otro" checked> Otro</label>
                                </div>
                                <input type="text" id="f-tipo-otro" style="flex: 1;">
                            </div>
                            <div class="f-row">
                                <label class="lbl-right" style="width: 50px;">MARCA:</label>
                                <input type="text" id="f-marca" style="flex: 1;">
                                <label class="lbl-right" style="width: 60px;">MODELO:</label>
                                <input type="text" id="f-modelo" style="flex: 1;">
                                <label class="lbl-right" style="width: 60px;">SERIAL:</label>
                                <input type="text" id="f-serial" style="flex: 1;">
                            </div>
                        </div>
                    </div>

                    <!-- DATOS DE LA FALLA -->
                    <div class="win-panel mt-1">
                        <div class="panel-title">DATOS DE LA FALLA</div>
                        <div class="panel-content">
                            <div class="f-row">
                                <label class="lbl-right" style="width: 100px;">FALLA:</label>
                                <input type="text" id="f-falla" style="flex: 1;">
                            </div>
                            <div class="f-row mt-1">
                                <label class="lbl-right" style="width: 100px;">OBSERVACIONES:</label>
                                <input type="text" id="f-observaciones" style="flex: 1;">
                            </div>
                            <div class="f-row mt-1">
                                <label class="lbl-right" style="width: 100px;">REPARACION:</label>
                                <input type="text" id="f-reparacion" style="flex: 1;">
                            </div>
                        </div>
                    </div>

                </div>

                <!-- RIGHT: Buttons and Accesorios -->
                <div class="right-buttons-panel">
                    <div class="btn-grid">
                        <button type="button" class="w-btn" onclick="nuevaOrden()"><i class="fas fa-plus-circle"></i> Nueva Orden</button>
                        <button type="button" class="w-btn" onclick="mostrarModal('modal-condiciones')"><i class="fas fa-tasks"></i> Editar Condiciones</button>
                        
                        <button type="button" class="w-btn" onclick="eliminarOrden()"><i class="far fa-window-close"></i> Eliminar Orden</button>
                        <button type="button" class="w-btn" onclick="mostrarModal('modal-buscar-orden')"><i class="fas fa-search"></i> Buscar Orden</button>
                        
                        <button type="button" class="w-btn" onclick="reimprimir()"><i class="fas fa-print"></i> Reimprimir</button>
                        <button type="button" class="w-btn" onclick="mostrarModal('modal-clientes')"><i class="fas fa-user-friends"></i> Buscar Cliente</button>
                        
                        <button type="button" class="w-btn" onclick="mostrarReporte()"><i class="fas fa-chart-bar"></i> Reporte Servicios</button>
                        <button type="button" class="w-btn" onclick="mostrarModal('modal-config')"><i class="fas fa-wrench"></i> Configuración</button>
                    </div>

                    <div class="accesorios-box mt-1">
                        <label class="lbl-top">ACCESORIOS:</label>
                        <input type="text" id="f-accesorios" style="width: 100%;">
                        
                        <label class="lbl-top mt-1">CLAVE O PATRON:</label>
                        <input type="text" id="f-clave" style="width: 100%;">
                    </div>
                </div>
            </div>

            <!-- BOTTOM SECTION -->
            <div class="bottom-section mt-1">
                <div class="cameras">
                    <div class="cam-slot" onclick="abrirGaleria(1)" title="Fotos/Videos de Entrada (Antes)">
                        <img class="slot-thumb" src="" id="thumb-antes" style="display:none;">
                        <i class="fas fa-history tiny-icon"></i>
                        <i class="fas fa-camera main-cam-icon"></i>
                        <span class="slot-label">ANTES</span>
                        <div class="media-count" id="count-antes">0</div>
                    </div>
                    <div class="cam-slot" onclick="abrirGaleria(2)" title="Fotos/Videos de Proceso (Durante)">
                        <img class="slot-thumb" src="" id="thumb-durante" style="display:none;">
                        <i class="fas fa-tools tiny-icon"></i>
                        <i class="fas fa-camera main-cam-icon"></i>
                        <span class="slot-label">DURANTE</span>
                        <div class="media-count" id="count-durante">0</div>
                    </div>
                    <div class="cam-slot" onclick="abrirGaleria(3)" title="Fotos/Videos de Salida (Después)">
                        <img class="slot-thumb" src="" id="thumb-despues" style="display:none;">
                        <i class="fas fa-check-double tiny-icon"></i>
                        <i class="fas fa-camera main-cam-icon"></i>
                        <span class="slot-label">DESPUÉS</span>
                        <div class="media-count" id="count-despues">0</div>
                    </div>
                </div>

                <div class="save-area">
                    <div class="dates-box">
                        <div class="d-row">
                            <label>FECHA REPARADO:</label>
                            <div class="d-input-group">
                                <input type="text" id="f-fecha-reparado">
                                <button type="button" class="btn-cal" onclick="openPicker('f-fecha-reparado')"><i class="far fa-calendar-alt"></i></button>
                            </div>
                        </div>
                        <div class="d-row mt-1">
                            <label>FECHA ENTREGADO:</label>
                            <div class="d-input-group">
                                <input type="text" id="f-fecha-entregado">
                                <button type="button" class="btn-cal" onclick="openPicker('f-fecha-entregado')"><i class="far fa-calendar-alt"></i></button>
                            </div>
                        </div>
                    </div>
                    
                    <div class="save-btn-box">
                        <button type="button" id="btnGuardarOrden" onclick="guardarOrden()">
                            <i class="far fa-save" style="font-size: 24px;"></i><br>GUARDAR
                        </button>
                    </div>

                    <div class="status-box mt-1" style="grid-column: span 2;">
                        <select id="f-estado" class="cbo-xl">
                            <option value="POR REVISAR">POR REVISAR</option>
                            <option value="REVISADO">REVISADO</option>
                            <option value="REPARADO">REPARADO</option>
                            <option value="ENTREGADO">ENTREGADO</option>
                        </select>
                    </div>
                </div>

                <div class="costs-area">
                    <label class="lbl-top">PRESUPUESTO:</label>
                    <input type="text" id="f-presupuesto" class="txt-right" value="">
                    
                    <label class="lbl-top mt-1">ABONO:</label>
                    <input type="text" id="f-abono" class="txt-right" value="">
                    
                    <label class="lbl-top mt-1">RESTA A PAGAR:</label>
                    <input type="text" id="f-resta" class="txt-right font-red" value="" readonly>
                </div>
            </div>
        </div>
    </div>
    
    <!-- Modales -->
    
    <!-- Modal Búsqueda de Órdenes -->
    <div id="modal-buscar-orden" class="win-modal" style="display: none;">
        <div class="win-modal-content" style="width: 800px;">
            <div class="win-modal-header">
                <span>BUSCAR ORDEN POR CLIENTE</span>
                <button class="win-close" onclick="cerrarModal('modal-buscar-orden')">×</button>
            </div>
            <div class="win-modal-body" style="display: flex; gap: 10px;">
                <div class="search-options" style="width: 150px; background: #f0f0f0; border: 1px solid #ccc; padding: 10px;">
                    <input type="text" id="b-orden-texto" style="width: 100%; margin-bottom: 10px;">
                    <div><label><input type="radio" name="b-criterio" value="documento"> Documento</label></div>
                    <div><label><input type="radio" name="b-criterio" value="telefono"> Telefono</label></div>
                    <div><label><input type="radio" name="b-criterio" value="nombre" checked> Nombre</label></div>
                    <button class="w-btn mt-1" style="width: 100%; background: #add8e6;" onclick="searchOrders()">Buscar</button>
                    <button class="w-btn mt-1" style="width: 100%; background: #add8e6;">Seleccionar</button>
                    <button class="w-btn mt-1" style="width: 100%; background: #add8e6;" onclick="cerrarModal('modal-buscar-orden')">Cancelar</button>
                </div>
                <div class="data-grid" style="flex: 1; border: 1px solid #ccc; background: #fff; height: 300px; overflow-y: auto;">
                    <table class="win-table">
                        <thead>
                            <tr>
                                <th>N° Orden</th>
                                <th>Fecha</th>
                                <th>Cliente</th>
                                <th>Documento</th>
                                <th>Teléfono</th>
                                <th>Tipo</th>
                                <th>Estado</th>
                                <th>Marca</th>
                                <th>Modelo</th>
                            </tr>
                        </thead>
                        <tbody id="b-ordenes-body">
                            <!-- JS fill -->
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </div>
    
    <!-- Modal Gestión Clientes -->
    <div id="modal-clientes" class="win-modal" style="display: none;">
        <div class="win-modal-content" style="width: 600px;">
            <div class="win-modal-header">
                <span>GESTION DE CLIENTES</span>
                <button class="win-close" onclick="cerrarModal('modal-clientes')">×</button>
            </div>
            <div class="win-modal-body" style="display: flex; gap: 10px;">
                <div style="width: 150px; display: flex; flex-direction: column; gap: 5px;">
                    <input type="text" id="filtro-clientes" style="width: 100%; height: 22px; background: #fff;">
                    <button class="w-btn" style="text-align: left; background: #add8e6;"><i class="fas fa-plus-circle"></i> NUEVO</button>
                    <button class="w-btn" style="text-align: left; background: #add8e6;"><i class="fas fa-edit"></i> EDITAR</button>
                    <button class="w-btn" style="text-align: left; background: #add8e6;"><i class="far fa-window-close"></i> ELIMINAR</button>
                    <button class="w-btn mt-auto" style="text-align: left; background: #add8e6;"><i class="fas fa-check-circle"></i> SELECCIONAR</button>
                </div>
                <div class="data-grid" style="flex: 1; border: 1px solid #ccc; background: #fff; height: 300px; overflow-y: auto;">
                    <table class="win-table">
                        <thead>
                            <tr>
                                <th>Nombre</th>
                                <th>Documento</th>
                                <th>Teléfono</th>
                            </tr>
                        </thead>
                        <tbody id="lista-clientes-body">
                            <!-- JS fill -->
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </div>
    
    <!-- Modal Condiciones -->
    <div id="modal-condiciones" class="win-modal" style="display: none;">
        <div class="win-modal-content" style="width: 500px;">
            <div class="win-modal-header">
                <span>CONDICIONES DEL SERVICIO</span>
                <button class="win-close" onclick="cerrarModal('modal-condiciones')">×</button>
            </div>
            <div class="win-modal-body">
                <textarea id="txt-condiciones" style="width: 100%; height: 250px; resize: none;"></textarea>
                <div style="display: flex; justify-content: space-between; margin-top: 10px;">
                    <div>
                        <button class="w-btn" onclick="cerrarModal('modal-condiciones')" style="width: 80px; background: #add8e6;">Cancelar</button>
                        <button class="w-btn" style="width: 80px; background: #add8e6;">Borrar</button>
                    </div>
                    <button class="w-btn" style="width: 150px; background: #add8e6;">Guardar</button>
                </div>
            </div>
        </div>
    </div>
    
    <!-- Modal Configuración -->
    <div id="modal-config" class="win-modal" style="display: none;">
        <div class="win-modal-content" style="width: 450px;">
            <div class="win-modal-header">
                <span>CONFIGURACION</span>
                <button class="win-close" onclick="cerrarModal('modal-config')">×</button>
            </div>
            <div class="win-modal-body">
                <div style="display: flex; gap: 10px;">
                    <div style="flex: 1;">
                        <h4 style="margin: 0 0 5px 0; font-size: 13px;">Microsoft Print to PDF</h4>
                        <div style="border: 1px solid #ccc; background: #fff; height: 150px; overflow-y: auto; padding: 5px; font-size: 11px;">
                            Impresoras Disponibles
                        </div>
                    </div>
                    <div style="flex: 1; display: flex; flex-direction: column; gap: 10px; font-size: 12px;">
                        <div>
                            <label style="font-weight: bold; display: block; margin-bottom: 2px;">Fuente Letra</label>
                            <select style="width: 100%; font-size: 11px;"><option>Courier New</option></select>
                        </div>
                        <div style="display: flex; align-items: center; gap: 5px;">
                            <input type="number" value="9" style="width: 50px; font-size: 11px;">
                            <label style="font-weight: bold;">Tamaño Letra</label>
                        </div>
                        <div style="margin-top: 10px;">
                            <label style="display: block;"><input type="radio" name="print_mode" value="large" checked> Imprimir en Media Carta</label>
                            <label style="display: block; margin-top: 5px;"><input type="radio" name="print_mode" value="ticket"> Imprimir en Ticket</label>
                        </div>
                        <div style="margin-top: 10px;">
                            <label><input type="checkbox" id="chk-auto-print"> Imprimir automáticamente al guardar</label>
                        </div>
                        <button class="w-btn mt-auto" style="background: #add8e6; height: 35px;"><i class="fas fa-plus-circle"></i> GUARDAR</button>
                    </div>
                </div>
            </div>
        </div>
    </div>
    
    <!-- Modal Galería Multimedia -->
    <div id="modal-galeria" class="win-modal" style="display: none;">
        <div class="win-modal-content" style="width: 700px; height: 500px;">
            <div class="win-modal-header">
                <span id="galeria-titulo">GALERÍA MULTIMEDIA</span>
                <button class="win-close" onclick="cerrarModal('modal-galeria')">×</button>
            </div>
            <div id="galeria-body-container" class="win-modal-body" style="display: flex; flex-direction: column; flex: 1; overflow: hidden; padding: 0;">
                <div style="background: #e1e1e1; padding: 10px; border-bottom: 2px solid #a0a0a0; display: flex; gap: 10px; align-items: center;">
                    <button class="w-btn" onclick="document.getElementById('input-subida').click()" style="background: #16a34a; color: white; border-color: #15803d; font-weight: bold;">
                        <i class="fas fa-upload"></i> SUBIR ARCHIVOS
                    </button>
                    <input type="file" id="input-subida" multiple accept="image/*,video/*" style="display: none;" onchange="subirArchivos()">
                    <span style="font-size: 10px; color: #444; font-weight: bold;">ADMITIDOS: JPG, PNG, GIF, MP4, WEBM</span>
                </div>
                
                <div id="galeria-grid" style="flex: 1; overflow-y: auto; padding: 15px; display: grid; grid-template-columns: repeat(auto-fill, minmax(130px, 1fr)); gap: 10px; align-content: start; background: #fff;">
                    <!-- Se llena con JS -->
                </div>

                <div id="galeria-vacia" style="display: none; flex: 1; flex-direction: column; align-items: center; justify-content: center; color: #888; background: #fff;">
                    <i class="fas fa-images" style="font-size: 48px; margin-bottom: 10px;"></i>
                    <p>No hay archivos en este estado.</p>
                </div>
            </div>
        </div>
    </div>

    <!-- View: Reporte de Servicios (Full Screen overlay) -->
    <div id="view-reportes" style="display: none; position: absolute; inset: 0; background: #f0f0f0; z-index: 500;">
        <div style="background: #add8e6; text-align: center; font-weight: bold; font-size: 16px; padding: 5px; border-bottom: 1px solid #ccc; color: white; -webkit-text-stroke: 1px #000;">
            REPORTE DE SERVICIOS
        </div>
        <div style="padding: 10px;">
            <div style="display: flex; gap: 10px; margin-bottom: 10px; align-items: center;">
                <label style="font-size: 11px; font-weight: bold;">Desde:</label>
                <input type="text" id="reporte-desde" style="width: 90px;">
                <label style="font-size: 11px; font-weight: bold;">Hasta:</label>
                <input type="text" id="reporte-hasta" style="width: 90px;">
                <button class="w-btn" id="btn-filtrar-reporte" style="background: #e0ecee; width: 100px;" onclick="fetchReportes()">FILTRAR</button>
                <button class="w-btn" onclick="document.getElementById('view-reportes').style.display = 'none'; document.getElementById('main-win-form').style.display = 'block';" style="margin-left: auto;">Cerrar</button>
            </div>
            <div style="background: #a0a0a0; height: 300px; border: 1px solid #777; overflow-y: auto;">
                <!-- Table for reports -->
                 <table class="win-table" style="background: white; width: 100%;">
                    <thead>
                        <tr>
                            <th>N° Orden</th><th>Fecha</th><th>Cliente</th><th>Tipo Equipo</th><th>Marca</th><th>Modelo</th><th>Falla</th><th>Estado</th><th>Presupuesto</th><th>Abono</th><th>Total</th><th>Fecha Reparación</th><th>Fecha Entrega</th>
                        </tr>
                    </thead>
                    <tbody></tbody>
                </table>
            </div>
            
            <div style="display: flex; margin-top: 10px; gap: 10px; height: 260px;">
                <div style="flex: 1; background: #fff; border: 1px solid #ccc; padding: 10px; display: flex; flex-direction: column; align-items: center;">
                    <span style="font-weight: bold; margin-bottom: 5px; font-size: 11px;">Tipos de Equipo</span>
                    <div style="flex: 1; width: 100%; position: relative;">
                        <canvas id="chart-tipos"></canvas>
                    </div>
                </div>
                <div style="flex: 1; background: #fff; border: 1px solid #ccc; padding: 10px; display: flex; flex-direction: column; align-items: center;">
                    <span style="font-weight: bold; margin-bottom: 5px; font-size: 11px;">Estado de Reparaciones</span>
                    <div style="flex: 1; width: 100%; position: relative;">
                        <canvas id="chart-estados"></canvas>
                    </div>
                </div>
                <div style="flex: 2; background: #fff; border: 1px solid #ccc; padding: 10px; display: flex; flex-direction: column; align-items: center;">
                    <span style="font-weight: bold; margin-bottom: 5px; font-size: 11px;">Ingresos Mensuales</span>
                    <div style="flex: 1; width: 100%; position: relative;">
                        <canvas id="chart-ingresos"></canvas>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <!-- Modal Visor Multimedia -->
    <div id="modal-visor" style="display: none; position: fixed; inset: 0; background: rgba(0,0,0,0.9); z-index: 3000; flex-direction: column; align-items: center; justify-content: center;">
        <div style="position: absolute; top: 20px; right: 20px; z-index: 3001;">
            <button class="visor-btn" onclick="cerrarVisor()"><i class="fas fa-times"></i></button>
        </div>
        
        <div id="visor-content" style="width: 80%; height: 80%; display: flex; align-items: center; justify-content: center; position: relative; overflow: hidden;">
            <!-- Elemento img o video inyectado por JS -->
        </div>

        <!-- Controles -->
        <div id="visor-controls" style="position: absolute; bottom: 20px; background: rgba(0,0,0,0.7); padding: 10px 20px; border-radius: 5px; display: flex; gap: 20px; z-index: 3001;">
            <button class="visor-btn" id="btn-zoom-in" onclick="visorZoom(0.2)" title="Acercar"><i class="fas fa-search-plus"></i></button>
            <button class="visor-btn" id="btn-zoom-out" onclick="visorZoom(-0.2)" title="Alejar"><i class="fas fa-search-minus"></i></button>
            <button class="visor-btn" id="btn-fullscreen" onclick="visorFullscreen()" title="Pantalla Completa"><i class="fas fa-expand"></i></button>
            <button class="visor-btn" id="btn-play-pause" onclick="visorTogglePlay()" style="display: none;" title="Play/Pausa"><i class="fas fa-play"></i></button>
        </div>
    </div>

    <!-- Hidden form for legacy logic in app.js -->
    <form id="order-form" style="display: none;">
         <!-- JS logic will be hooked to these elements by id directly now -->
    </form>

    <script src="https://cdn.jsdelivr.net/npm/flatpickr"></script>
    <script src="https://npmcdn.com/flatpickr/dist/l10n/es.js"></script>
    <script src="app.js"></script>
</body>
</html>
