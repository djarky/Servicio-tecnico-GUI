// app.js - Frontend Logic for ST-PRO WinForms Style

document.addEventListener('DOMContentLoaded', () => {
    initApp();
});

function initApp() {
    setupSetup();
    setupLogin();
    setupCalculations();
    setupSearch();
    setupValidations();
    setupReportPickers();
    fillFontSelectors();
    cargarConfig();
}

let appConfig = { moneda_simbolo: '$' };

const DEFAULT_CONFIGS = {
    large: {
        font_head: 'Tahoma', size_head: '16',
        font_title: 'Tahoma', size_title: '14',
        font_body: 'Tahoma', size_body: '13',
        font_cond: 'Tahoma', size_cond: '10'
    },
    ticket: {
        font_head: 'Courier New', size_head: '14',
        font_title: 'Courier New', size_title: '12',
        font_body: 'Courier New', size_body: '11',
        font_cond: 'Courier New', size_cond: '9'
    }
};

function fillFontSelectors() {
    const fonts = ['Tahoma', 'Arial', 'Courier New', 'Inter', 'Roboto', 'Times New Roman', 'Verdana', 'Georgia'];
    const selects = ['cfg-font-head', 'cfg-font-title', 'cfg-font-body', 'cfg-font-cond'];
    selects.forEach(id => {
        const sel = document.getElementById(id);
        if (sel) {
            sel.innerHTML = fonts.map(f => `<option value="${f}">${f}</option>`).join('');
        }
    });
}

async function cargarConfig() {
    try {
        const res = await fetch('api.php?action=get_config');
        appConfig = await res.json();
        
        // Aplicar a los inputs de moneda y auto-print
        const monedaInput = document.getElementById('cfg-moneda');
        if (monedaInput) monedaInput.value = appConfig.moneda_simbolo || '$';
        
        const chkAuto = document.getElementById('chk-auto-print');
        if (chkAuto) chkAuto.checked = appConfig.auto_print === '1';

        // Cargar modo de impresión predeterminado
        if (appConfig.print_mode) {
            const radio = document.getElementById('cfg-mode-' + appConfig.print_mode);
            if (radio) radio.checked = true;
        }

        // Cargar condiciones
        const txtCond = document.getElementById('txt-condiciones');
        if (txtCond && appConfig.condiciones_servicio) txtCond.value = appConfig.condiciones_servicio;

        // Poblar campos de fuente según el modo seleccionado actualmente en el modal
        updateFontUIByMode();
        
        calculateBalance();
    } catch (err) {
        console.error("Error cargando config:", err);
    }
}

function switchConfigMode() {
    // 1. Guardar los valores actuales de la UI en el objeto appConfig (en memoria)
    // para no perder los cambios al alternar entre modos antes de pulsar GUARDAR.
    const oldMode = document.querySelector('input[name="print_mode_cfg"]:not(:checked)').value;
    const fields = ['font_head', 'size_head', 'font_title', 'size_title', 'font_body', 'size_body', 'font_cond', 'size_cond'];
    
    // Nota: Esta lógica es un poco compleja porque switchConfigMode se dispara DESPUÉS de que el radio cambie.
    // Así que necesitamos saber cuál era el modo anterior. 
    // Por simplicidad, vamos a guardar SIEMPRE lo que haya en la UI en el modo que NO está seleccionado ahora? No.
    // Hagamos que el evento onchange pase el modo anterior o simplemente guardemos el estado antes de cambiar.
}

// Refactorizamos para que sea más robusto
let lastSelectedMode = 'large';

function updateFontUIByMode() {
    const mode = document.querySelector('input[name="print_mode_cfg"]:checked').value;
    const fields = ['font_head', 'size_head', 'font_title', 'size_title', 'font_body', 'size_body', 'font_cond', 'size_cond'];
    
    fields.forEach(f => {
        const key = `${mode}_${f}`;
        const inputId = 'cfg-' + f.replace('_', '-');
        const input = document.getElementById(inputId);
        if (input) {
            input.value = appConfig[key] || DEFAULT_CONFIGS[mode][f];
        }
    });
    lastSelectedMode = mode;
}

function switchConfigMode() {
    // Guardar lo que había antes de cambiar
    const fields = ['font_head', 'size_head', 'font_title', 'size_title', 'font_body', 'size_body', 'font_cond', 'size_cond'];
    fields.forEach(f => {
        const key = `${lastSelectedMode}_${f}`;
        const inputId = 'cfg-' + f.replace('_', '-');
        const input = document.getElementById(inputId);
        if (input) {
            appConfig[key] = input.value;
        }
    });

    // Cargar lo del nuevo modo
    updateFontUIByMode();
}

async function guardarConfig() {
    const mode = document.querySelector('input[name="print_mode_cfg"]:checked').value;
    
    // 1. Sincronizar UI actual con appConfig antes de enviar
    appConfig.moneda_simbolo = document.getElementById('cfg-moneda').value;
    appConfig.auto_print = document.getElementById('chk-auto-print').checked ? '1' : '0';
    appConfig.print_mode = mode;

    const fields = ['font_head', 'size_head', 'font_title', 'size_title', 'font_body', 'size_body', 'font_cond', 'size_cond'];
    fields.forEach(f => {
        const key = `${mode}_${f}`;
        const inputId = 'cfg-' + f.replace('_', '-');
        appConfig[key] = document.getElementById(inputId).value;
    });
    
    try {
        const res = await fetch('api.php?action=save_config', {
            method: 'POST',
            body: JSON.stringify(appConfig)
        });
        const result = await res.json();
        if (result.success) {
            alert("Configuración global guardada correctamente.");
            cerrarModal('modal-config');
            calculateBalance();
        }
    } catch (err) {
        console.error("Error guardando config:", err);
    }
}

async function guardarCondiciones() {
    const text = document.getElementById('txt-condiciones').value;
    const data = { condiciones_servicio: text };
    
    try {
        const res = await fetch('api.php?action=save_config', {
            method: 'POST',
            body: JSON.stringify(data)
        });
        const result = await res.json();
        if (result.success) {
            alert("Condiciones guardadas correctamente");
            appConfig.condiciones_servicio = text;
            cerrarModal('modal-condiciones');
        }
    } catch (err) {
        console.error("Error guardando condiciones:", err);
    }
}

function borrarCondiciones() {
    if (confirm("¿Seguro que desea borrar todas las condiciones?")) {
        document.getElementById('txt-condiciones').value = '';
    }
}

function formatCurrency(amount) {
    const sym = appConfig.moneda_simbolo || '$';
    const val = parseFloat(amount) || 0;
    return `${sym}${val.toFixed(2)}`;
}

// --- Navigation & Modals ---
function mostrarModal(id) {
    document.getElementById(id).style.display = 'flex';
    if (id === 'modal-clientes') {
        searchCustomers();
    }
}

function cerrarModal(id) {
    document.getElementById(id).style.display = 'none';
}

function mostrarReporte() {
    document.getElementById('main-win-form').style.display = 'none';
    document.getElementById('view-reportes').style.display = 'block';
    fetchReportes();
}

// --- Auth & Setup ---
function setupSetup() {
    const setupForm = document.getElementById('setup-form');
    if (setupForm) {
        setupForm.addEventListener('submit', async (e) => {
            e.preventDefault();
            const nombre = document.getElementById('setup-name').value;
            const usuario = document.getElementById('setup-user').value;
            const password = document.getElementById('setup-pass').value;
            
            try {
                const res = await fetch('api.php?action=setup', {
                    method: 'POST',
                    body: JSON.stringify({ nombre, usuario, password })
                });
                const data = await res.json();
                
                if (data.success) {
                    window.location.reload();
                } else {
                    const errorDiv = document.getElementById('setup-error');
                    errorDiv.innerText = data.error || 'Error desconocido';
                    errorDiv.style.display = 'block';
                }
            } catch (err) {
                console.error(err);
            }
        });
    }
}

function setupLogin() {
    const loginForm = document.getElementById('login-form');
    if (loginForm) {
        loginForm.addEventListener('submit', async (e) => {
            e.preventDefault();
            const usuario = document.getElementById('login-user').value;
            const password = document.getElementById('login-pass').value;
            
            try {
                const res = await fetch('api.php?action=login', {
                    method: 'POST',
                    body: JSON.stringify({ usuario, password })
                });
                const data = await res.json();
                
                if (data.success) {
                    window.location.reload();
                } else {
                    const errorDiv = document.getElementById('login-error');
                    errorDiv.innerText = data.error;
                    errorDiv.style.display = 'block';
                }
            } catch (err) {
                console.error(err);
            }
        });
    }
}

async function logout() {
    await fetch('api.php?action=logout');
    window.location.reload();
}

// --- Order Logic ---

function nuevaOrden() {
    // Limpiar campos
    const ids = ['f-id-orden', 'f-documento', 'f-telefono', 'f-nombre', 'f-direccion', 
                 'f-marca', 'f-modelo', 'f-serial', 'f-tipo-otro', 'f-falla', 
                 'f-observaciones', 'f-reparacion', 'f-accesorios', 'f-clave'];
    ids.forEach(id => {
        if(document.getElementById(id)) document.getElementById(id).value = '';
    });
    
    document.getElementById('f-presupuesto').value = '0.00';
    document.getElementById('f-abono').value = '0.00';
    document.getElementById('f-resta').value = '0.00';
    document.querySelector('input[name="f-tipo"][value="Otro"]').checked = true;
    document.getElementById('f-estado').value = 'POR REVISAR';
    
    // Resetear fechas con Flatpickr
    if (fpInstances['f-fecha']) fpInstances['f-fecha'].setDate(new Date());
    if (fpInstances['f-fecha-reparado']) fpInstances['f-fecha-reparado'].clear();
    if (fpInstances['f-fecha-entregado']) fpInstances['f-fecha-entregado'].clear();

    updateMediaCounts(null);
    const counts = ['count-antes', 'count-durante', 'count-despues'];
    counts.forEach(id => document.getElementById(id).innerText = '0');
}

async function guardarOrden() {
    const tipo = document.querySelector('input[name="f-tipo"]:checked').value;
    const tipoFinal = tipo === 'Otro' ? document.getElementById('f-tipo-otro').value : tipo;

    const formData = {
        id_orden: document.getElementById('f-id-orden').value,
        id_cliente: '', // Simplified, if we had it
        documento: document.getElementById('f-documento').value,
        nombre: document.getElementById('f-nombre').value,
        telefono: document.getElementById('f-telefono').value,
        direccion: document.getElementById('f-direccion').value,
        tipo_equipo: tipoFinal,
        marca: document.getElementById('f-marca').value,
        modelo: document.getElementById('f-modelo').value,
        serial: document.getElementById('f-serial').value,
        clave: document.getElementById('f-clave').value,
        accesorios: document.getElementById('f-accesorios').value,
        falla: document.getElementById('f-falla').value,
        observaciones: document.getElementById('f-observaciones').value,
        reparacion: document.getElementById('f-reparacion').value,
        presupuesto: parseFloat(document.getElementById('f-presupuesto').value) || 0,
        abono: parseFloat(document.getElementById('f-abono').value) || 0,
        estado: document.getElementById('f-estado').value,
        reparado: document.getElementById('f-fecha-reparado').value,
        entregado: document.getElementById('f-fecha-entregado').value
    };
    
    if(!formData.nombre || !formData.documento) {
        alert("El nombre y documento son obligatorios.");
        return;
    }

    // Validación de Teléfono antes de guardar
    if (formData.telefono && formData.telefono.length > 0) {
        const digits = formData.telefono.replace(/\D/g, '');
        if (digits.length < 7 && digits.length > 0) {
            if (!confirm("El número de teléfono parece muy corto. ¿Desea guardar de todas formas?")) return;
        }
    }

    // Validación de Formato de Fecha
    const datePattern = /^\d{2}\/\d{2}\/\d{4}$/;
    if (formData.reparado && !datePattern.test(formData.reparado)) {
        alert("El formato de la fecha de reparación no es válido (dd/mm/aaaa).");
        return;
    }
    if (formData.entregado && !datePattern.test(formData.entregado)) {
        alert("El formato de la fecha de entrega no es válido (dd/mm/aaaa).");
        return;
    }

    try {
        const res = await fetch('api.php?action=save_order', {
            method: 'POST',
            body: JSON.stringify(formData)
        });
        
        const result = await res.json();
        if (result.success) {
            alert('Orden guardada correctamente');
            if(result.id_orden) {
                document.getElementById('f-id-orden').value = result.id_orden;
            }
            
            // Auto printing
            if (document.getElementById('chk-auto-print').checked) {
                reimprimir();
            }
        } else {
            alert("Error del servidor: " + (result.error || "Desconocido"));
        }
    } catch(err) {
        console.error(err);
        alert("Error de comunicación o datos: " + err.message);
    }
}

function setupCalculations() {
    const pres = document.getElementById('f-presupuesto');
    const ab = document.getElementById('f-abono');
    
    if (pres) pres.addEventListener('input', calculateBalance);
    if (ab) ab.addEventListener('input', calculateBalance);
}

function calculateBalance() {
    const p = parseFloat(document.getElementById('f-presupuesto').value) || 0;
    const a = parseFloat(document.getElementById('f-abono').value) || 0;
    const resta = p - a;
    document.getElementById('f-resta').value = resta.toFixed(2);
    
    // Actualizar labels o placeholders si los hubiera. 
    // Por ahora el sistema usa inputs, pero podemos añadir el símbolo visualmente fuera si se desea.
}

// --- Validations & Pickers ---
let fpInstances = {};

function setupValidations() {
    // Configuración de Flatpickr para fechas
    const dateConfig = {
        dateFormat: "d/m/Y",
        allowInput: true,
        locale: "es"
    };

    fpInstances['f-fecha'] = flatpickr("#f-fecha", dateConfig);
    fpInstances['f-fecha-reparado'] = flatpickr("#f-fecha-reparado", dateConfig);
    fpInstances['f-fecha-entregado'] = flatpickr("#f-fecha-entregado", dateConfig);

    // Validación de Teléfono (Restricción de caracteres en tiempo real)
    const telInput = document.getElementById('f-telefono');
    if (telInput) {
        telInput.addEventListener('input', (e) => {
            // Permitir: números, espacios, +, -, (, )
            const validPattern = /[^0-9\s+\-()]/g;
            if (validPattern.test(e.target.value)) {
                e.target.value = e.target.value.replace(validPattern, '');
            }
        });
    }

    // Validación de Montos (asegurar números en presupuesto y abono)
    ['f-presupuesto', 'f-abono'].forEach(id => {
        const el = document.getElementById(id);
        if (el) {
            el.addEventListener('blur', (e) => {
                if (isNaN(parseFloat(e.target.value))) {
                    e.target.value = '0.00';
                } else {
                    e.target.value = parseFloat(e.target.value).toFixed(2);
                }
                calculateBalance();
            });
        }
    });
}

function setupReportPickers() {
    const dateConfig = {
        dateFormat: "Y-m-d",
        altFormat: "d/m/Y",
        altInput: true,
        allowInput: true,
        locale: "es",
        onChange: () => {
             // Automatic update when date changes
             fetchReportes();
        }
    };
 
    // Default dates: Jan 1st of current year to Today
    const today = new Date();
    const startOfYear = new Date(today.getFullYear(), 0, 1);
 
    fpInstances['reporte-desde'] = flatpickr("#reporte-desde", {
        ...dateConfig,
        defaultDate: startOfYear
    });
    fpInstances['reporte-hasta'] = flatpickr("#reporte-hasta", {
        ...dateConfig,
        defaultDate: today
    });
}

function openPicker(id) {
    if (fpInstances[id]) {
        fpInstances[id].open();
    }
}

// --- Utils ---
function debounce(func, delay) {
    let timeoutId;
    return (...args) => {
        if (timeoutId) clearTimeout(timeoutId);
        timeoutId = setTimeout(() => {
            func.apply(null, args);
        }, delay);
    };
}

// --- Search Modal Logic ---
function setupSearch() {
    const inputBusqueda = document.getElementById('b-orden-texto');
    if (inputBusqueda) {
        // Debounced search on typing
        inputBusqueda.addEventListener('input', debounce(() => {
            searchOrders();
        }, 300));
    }
    
    // Immediate search on criteria change
    const radios = document.getElementsByName('b-criterio');
    radios.forEach(r => {
        r.addEventListener('change', () => {
            if (inputBusqueda.value.trim() !== '') {
                searchOrders();
            }
        });
    });

    const inputClientes = document.getElementById('filtro-clientes');
    if (inputClientes) {
        inputClientes.addEventListener('input', debounce(() => {
            searchCustomers();
        }, 300));
    }
}

async function searchOrders() {
    const txt = document.getElementById('b-orden-texto').value;
    // Criterio is radio
    const crit = document.querySelector('input[name="b-criterio"]:checked').value;
    
    try {
        const res = await fetch(`api.php?action=get_orders&q=${txt}`);
        const orders = await res.json();
        const tbody = document.getElementById('b-ordenes-body');
        tbody.innerHTML = '';
        
        orders.forEach(o => {
            // Filter locally by crit if backend does basic search
            let match = false;
            if(crit === 'nombre' && o.cliente_nombre.toLowerCase().includes(txt.toLowerCase())) match = true;
            if(crit === 'documento' && o.cliente_doc.includes(txt)) match = true;
            if(crit === 'telefono' && (o.telefono && o.telefono.includes(txt))) match = true;
            if(!txt) match = true;

            if (match) {
                const tr = document.createElement('tr');
                tr.style.cursor = 'pointer';
                tr.onclick = () => loadOrder(o);
                tr.innerHTML = `
                    <td>${o.id_orden}</td>
                    <td>${o.fecha}</td>
                    <td>${o.cliente_nombre}</td>
                    <td>${o.cliente_doc}</td>
                    <td>${o.telefono}</td>
                    <td>${o.tipo_equipo}</td>
                    <td>${o.estado}</td>
                    <td>${o.marca}</td>
                    <td>${o.modelo}</td>
                `;
                tbody.appendChild(tr);
            }
        });
    } catch (err) {
        console.error(err);
    }
}

async function searchCustomers() {
    const txt = document.getElementById('filtro-clientes').value;
    try {
        const res = await fetch(`api.php?action=get_customers&q=${txt}`);
        const customers = await res.json();
        const tbody = document.getElementById('lista-clientes-body');
        tbody.innerHTML = '';
        
        customers.forEach(c => {
            const tr = document.createElement('tr');
            tr.style.cursor = 'pointer';
            tr.onclick = () => loadClient(c);
            tr.innerHTML = `
                <td>${c.nombre}</td>
                <td>${c.documento}</td>
                <td>${c.telefono}</td>
            `;
            tbody.appendChild(tr);
        });
    } catch (err) {
        console.error(err);
    }
}

function loadClient(c) {
    document.getElementById('f-documento').value = c.documento || '';
    document.getElementById('f-nombre').value = c.nombre || '';
    document.getElementById('f-telefono').value = c.telefono || '';
    document.getElementById('f-direccion').value = c.direccion || '';
    cerrarModal('modal-clientes');
}

function loadOrder(o) {
    document.getElementById('f-id-orden').value = o.id_orden;
    document.getElementById('f-documento').value = o.cliente_doc || '';
    document.getElementById('f-nombre').value = o.cliente_nombre || '';
    document.getElementById('f-telefono').value = o.telefono || '';
    document.getElementById('f-direccion').value = o.direccion || '';
    document.getElementById('f-marca').value = o.marca || '';
    document.getElementById('f-modelo').value = o.modelo || '';
    document.getElementById('f-serial').value = o.serial || '';
    document.getElementById('f-clave').value = o.clave || '';
    document.getElementById('f-accesorios').value = o.accesorios || '';
    document.getElementById('f-falla').value = o.falla || '';
    document.getElementById('f-observaciones').value = o.observaciones || '';
    document.getElementById('f-reparacion').value = o.reparacion || '';
    document.getElementById('f-presupuesto').value = o.presupuesto || '0.00';
    document.getElementById('f-abono').value = o.abono || '0.00';
    document.getElementById('f-estado').value = o.estado || 'POR REVISAR';
    
    // Actualizar fechas en Flatpickr
    if (fpInstances['f-fecha']) fpInstances['f-fecha'].setDate(o.fecha || '');
    if (fpInstances['f-fecha-reparado']) fpInstances['f-fecha-reparado'].setDate(o.reparado || '');
    if (fpInstances['f-fecha-entregado']) fpInstances['f-fecha-entregado'].setDate(o.entregado || '');
    
    // check radio
    let radios = document.getElementsByName('f-tipo');
    let found = false;
    for(let i=0; i<radios.length; i++){
        if(radios[i].value === o.tipo_equipo) {
            radios[i].checked = true;
            found = true;
        }
    }
    if(!found) {
        document.querySelector('input[name="f-tipo"][value="Otro"]').checked = true;
        document.getElementById('f-tipo-otro').value = o.tipo_equipo;
    } else {
        document.getElementById('f-tipo-otro').value = '';
    }

    calculateBalance();
    updateMediaCounts(o.id_orden);
    cerrarModal('modal-buscar-orden');
}

async function eliminarOrden() {
    const id = document.getElementById('f-id-orden').value;
    if(!id) {
        alert("Primero debe cargar una orden para eliminarla.");
        return;
    }

    if(confirm("¿Seguro que desea eliminar la orden " + id + "? Esta acción no se puede deshacer.")) {
        try {
            const res = await fetch(`api.php?action=delete_order&id=${id}`);
            const result = await res.json();

            if (result.success) {
                alert("Orden eliminada correctamente.");
                nuevaOrden();
            } else {
                alert("Error al eliminar la orden: " + (result.error || "Desconocido"));
            }
        } catch (err) {
            console.error(err);
            alert("Error de comunicación con el servidor.");
        }
    }
}

function reimprimir() {
    const id = document.getElementById('f-id-orden').value;
    if(id) {
        let mode = appConfig.print_mode || 'large';
        window.open(`print_order.php?id=${id}&mode=${mode}`, '_blank');
    } else {
        alert("Debe cargar una orden para imprimir.");
    }
}

// --- Multimedia Gallery Logic ---
let currentGaleriaEstado = 0;

async function abrirGaleria(estado) {
    const id_orden = document.getElementById('f-id-orden').value;
    if (!id_orden) {
        alert("Debe guardar o cargar una orden primero.");
        return;
    }
    
    currentGaleriaEstado = estado;
    const titulos = {1: 'ANTES (ENTRADA)', 2: 'DURANTE (REPARACIÓN)', 3: 'DESPUÉS (ENTREGA)'};
    document.getElementById('galeria-titulo').innerText = 'GALERÍA: ' + titulos[estado];
    
    mostrarModal('modal-galeria');
    cargarMedia();
}

async function cargarMedia() {
    const id_orden = document.getElementById('f-id-orden').value;
    const grid = document.getElementById('galeria-grid');
    const emptyMsg = document.getElementById('galeria-vacia');
    
    try {
        const res = await fetch(`api.php?action=get_media&id_orden=${id_orden}&estado=${currentGaleriaEstado}`);
        const files = await res.json();
        
        grid.innerHTML = '';
        if (files.length === 0) {
            emptyMsg.style.display = 'flex';
        } else {
            emptyMsg.style.display = 'none';
            files.forEach(f => {
                const item = document.createElement('div');
                item.className = 'media-item';
                
                let preview = '';
                if (f.tipo_archivo === 'image') {
                    preview = `<img src="${f.archivo_ruta}" class="media-thumb" onclick="abrirVisor('${f.archivo_ruta}', 'image')">`;
                } else {
                    preview = `<div class="media-thumb" style="display:flex; align-items:center; justify-content:center; color:white; cursor:pointer;" onclick="abrirVisor('${f.archivo_ruta}', 'video')">
                                <i class="fas fa-video" style="font-size:32px;"></i>
                               </div>`;
                }
                
                item.innerHTML = `
                    ${preview}
                    <div class="media-name">${f.archivo_ruta.split('/').pop()}</div>
                    <div class="media-actions">
                        <span class="btn-del-media" onclick="eliminarArchivo(${f.id})"><i class="fas fa-trash"></i></span>
                    </div>
                `;
                grid.appendChild(item);
            });
        }
    } catch (err) {
        console.error(err);
    }
    updateMediaCounts(id_orden);
}

async function subirArchivos() {
    const id_orden = document.getElementById('f-id-orden').value;
    const input = document.getElementById('input-subida');
    const files = input.files;
    
    if (files.length === 0) return;
    
    for (let i = 0; i < files.length; i++) {
        const formData = new FormData();
        formData.append('id_orden', id_orden);
        formData.append('estado', currentGaleriaEstado);
        formData.append('archivo', files[i]);
        
        try {
            const res = await fetch('api.php?action=upload_media', {
                method: 'POST',
                body: formData
            });
            const result = await res.json();
            if (!result.success) alert("Error subiendo " + files[i].name + ": " + (result.error || 'Desconocido'));
        } catch (err) {
            console.error(err);
        }
    }
    
    input.value = ''; // Reset
    cargarMedia();
}

async function eliminarArchivo(id) {
    if (!confirm("¿Seguro que desea eliminar este archivo?")) return;
    
    try {
        const res = await fetch(`api.php?action=delete_media&id=${id}`);
        const result = await res.json();
        if (result.success) {
            cargarMedia();
        } else {
            alert("Error al eliminar: " + result.error);
        }
    } catch (err) {
        console.error(err);
    }
}

let activeSlideshows = { 1: null, 2: null, 3: null };

async function updateMediaCounts(id_orden) {
    const states = [1, 2, 3];
    const mapIds = {1: 'count-antes', 2: 'count-durante', 3: 'count-despues'};
    const mapThumbs = {1: 'thumb-antes', 2: 'thumb-durante', 3: 'thumb-despues'};
    
    if (!id_orden) {
        states.forEach(st => detenerSlideshow(st, mapThumbs[st], mapIds[st]));
        return;
    }
    
    states.forEach(async (st) => {
        try {
            const res = await fetch(`api.php?action=get_media&id_orden=${id_orden}&estado=${st}`);
            const files = await res.json();
            
            const countEl = document.getElementById(mapIds[st]);
            if (countEl) countEl.innerText = files.length;
            
            iniciarSlideshow(st, files, mapThumbs[st]);
            
        } catch (e) {}
    });
}

function detenerSlideshow(estado, thumbId, countId) {
    if (activeSlideshows[estado]) {
        clearInterval(activeSlideshows[estado]);
        activeSlideshows[estado] = null;
    }
    const thumbEl = document.getElementById(thumbId);
    if(thumbEl) {
        thumbEl.style.display = 'none';
        thumbEl.src = '';
    }
    const countEl = document.getElementById(countId);
    if(countEl) countEl.innerText = '0';
}

function iniciarSlideshow(estado, files, thumbId) {
    // Clear previous interval if any
    if (activeSlideshows[estado]) {
        clearInterval(activeSlideshows[estado]);
        activeSlideshows[estado] = null;
    }
    
    const thumbEl = document.getElementById(thumbId);
    if (!thumbEl) return;
    
    const imagesOnly = files.filter(f => f.tipo_archivo === 'image');
    
    if (imagesOnly.length === 0) {
        thumbEl.style.display = 'none';
        return;
    }
    
    // Show first image immediately
    thumbEl.src = imagesOnly[0].archivo_ruta;
    thumbEl.style.display = 'block';
    
    if (imagesOnly.length > 1) {
        let currentIndex = 0;
        activeSlideshows[estado] = setInterval(() => {
            currentIndex = (currentIndex + 1) % imagesOnly.length;
            thumbEl.src = imagesOnly[currentIndex].archivo_ruta;
        }, 1000); // 1-second delay
    }
}


let chartInstances = {};

async function fetchReportes() {
    const desde = document.getElementById('reporte-desde').value;
    const hasta = document.getElementById('reporte-hasta').value;
    
    // 1. Fetch table data (orders)
    let url = 'api.php?action=get_orders';
    if(desde && hasta) url += `&desde=${desde}&hasta=${hasta}`; // Note: Backend search might need adjustment for dates in get_orders too if we want full sync

    try {
        const res = await fetch(url);
        const orders = await res.json();
        const tbody = document.querySelector('#view-reportes tbody');
        tbody.innerHTML = '';
        
        orders.forEach(o => {
            const tr = document.createElement('tr');
            tr.innerHTML = `
                <td>${o.id_orden}</td>
                <td>${o.fecha}</td>
                <td>${o.cliente_nombre}</td>
                <td>${o.tipo_equipo}</td>
                <td>${o.marca}</td>
                <td>${o.modelo}</td>
                <td>${o.falla}</td>
                <td>${o.estado}</td>
                <td>${formatCurrency(o.presupuesto)}</td>
                <td>${formatCurrency(o.abono)}</td>
                <td>${formatCurrency(o.presupuesto - o.abono)}</td>
                <td>${o.reparado || '-'}</td>
                <td>${o.entregado || '-'}</td>
            `;
            tbody.appendChild(tr);
        });

        // 2. Fetch Aggregated Chart Data
        const resReport = await fetch(`api.php?action=get_report_data&desde=${desde}&hasta=${hasta}`);
        const reportData = await resReport.json();
        renderCharts(reportData);

    } catch (err) {
        console.error("Error fetching report data:", err);
    }
}

function renderCharts(data) {
    const commonOptions = {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
            legend: {
                position: 'right',
                labels: { font: { size: 10 } }
            }
        }
    };

    // --- Tipos de Equipo (Doughnut) ---
    if (chartInstances['tipos']) chartInstances['tipos'].destroy();
    chartInstances['tipos'] = new Chart(document.getElementById('chart-tipos'), {
        type: 'doughnut',
        data: {
            labels: data.tipos.map(i => `${i.label} (${i.value})`),
            datasets: [{
                data: data.tipos.map(i => i.value),
                backgroundColor: ['#2563eb', '#f59e0b', '#10b981', '#ef4444', '#8b5cf6', '#6b7280']
            }]
        },
        options: commonOptions
    });

    // --- Estados de Reparación (Doughnut) ---
    if (chartInstances['estados']) chartInstances['estados'].destroy();
    chartInstances['estados'] = new Chart(document.getElementById('chart-estados'), {
        type: 'doughnut',
        data: {
            labels: data.estados.map(i => `${i.label} (${i.value})`),
            datasets: [{
                data: data.estados.map(i => i.value),
                backgroundColor: ['#f59e0b', '#3b82f6', '#10b981', '#16a34a', '#d1d5db']
            }]
        },
        options: commonOptions
    });

    // --- Ingresos Mensuales (Bar) ---
    if (chartInstances['ingresos']) chartInstances['ingresos'].destroy();
    chartInstances['ingresos'] = new Chart(document.getElementById('chart-ingresos'), {
        type: 'bar',
        data: {
            labels: data.ingresos.map(i => i.label),
            datasets: [{
                label: 'Ingresos Mensuales',
                data: data.ingresos.map(i => i.value),
                backgroundColor: '#3b82f6',
                borderColor: '#2563eb',
                borderWidth: 1
            }]
        },
        options: {
            ...commonOptions,
            plugins: { ...commonOptions.plugins, legend: { display: false } },
            scales: {
                y: { beginAtZero: true, ticks: { callback: value => (appConfig.moneda_simbolo || '$') + value } }
            }
        }
    });
}

// --- Visor Multimedia Nativo ---
let visorCurrentZoom = 1;

function abrirVisor(ruta, tipo) {
    const visor = document.getElementById('modal-visor');
    const content = document.getElementById('visor-content');
    const btnPlay = document.getElementById('btn-play-pause');
    
    visorCurrentZoom = 1;
    content.innerHTML = ''; // Reset
    
    if (tipo === 'image') {
        content.innerHTML = `<img id="visor-media" src="${ruta}" style="transform: scale(${visorCurrentZoom})">`;
        btnPlay.style.display = 'none';
        
    } else if (tipo === 'video') {
        content.innerHTML = `<video id="visor-media" src="${ruta}" controls style="transform: scale(${visorCurrentZoom})">
                             Tu navegador no soporta el reproductor de video.
                             </video>`;
        btnPlay.style.display = 'inline-block';
        btnPlay.innerHTML = '<i class="fas fa-play"></i>';
    }
    
    visor.style.display = 'flex';
}

function cerrarVisor() {
    const visor = document.getElementById('modal-visor');
    const content = document.getElementById('visor-content');
    visor.style.display = 'none';
    content.innerHTML = ''; // Stops videos
}

function visorZoom(factor) {
    const media = document.getElementById('visor-media');
    if (!media) return;
    
    visorCurrentZoom += factor;
    // Limits
    if (visorCurrentZoom < 0.2) visorCurrentZoom = 0.2;
    if (visorCurrentZoom > 5) visorCurrentZoom = 5;
    
    media.style.transform = `scale(${visorCurrentZoom})`;
}

function visorFullscreen() {
    const visor = document.getElementById('modal-visor');
    if (!document.fullscreenElement) {
        visor.requestFullscreen().catch(err => {
            alert(`Error al intentar pantalla completa: ${err.message}`);
        });
    } else {
        document.exitFullscreen();
    }
}

function visorTogglePlay() {
    const video = document.getElementById('visor-media');
    const btnPlay = document.getElementById('btn-play-pause');
    if (!video || video.tagName !== 'VIDEO') return;
    
    if (video.paused) {
        video.play();
        btnPlay.innerHTML = '<i class="fas fa-pause"></i>';
    } else {
        video.pause();
        btnPlay.innerHTML = '<i class="fas fa-play"></i>';
    }
    
    // Auto-update icon if user uses native controls
    video.onplay = () => btnPlay.innerHTML = '<i class="fas fa-pause"></i>';
    video.onpause = () => btnPlay.innerHTML = '<i class="fas fa-play"></i>';
}
