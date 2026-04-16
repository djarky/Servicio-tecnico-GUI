// app.js - Frontend Logic for ST-PRO WinForms Style

document.addEventListener('DOMContentLoaded', () => {
    initApp();
});

function initApp() {
    setupSetup();
    setupLogin();
    setupCalculations();
    setupSearch();
}

// --- Navigation & Modals ---
function mostrarModal(id) {
    document.getElementById(id).style.display = 'flex';
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
    document.getElementById('f-resta').value = (p - a).toFixed(2);
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
    document.getElementById('f-fecha-reparado').value = o.reparado || '';
    document.getElementById('f-fecha-entregado').value = o.entregado || '';
    
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

function eliminarOrden() {
    const id = document.getElementById('f-id-orden').value;
    if(id && confirm("¿Seguro que desea eliminar la orden " + id + "?")) {
        // Here would go the fetch to delete.
        alert("Orden eliminada (simulación)");
        nuevaOrden();
    }
}

function reimprimir() {
    const id = document.getElementById('f-id-orden').value;
    if(id) {
        let mode = 'large';
        const modeEl = document.querySelector('input[name="print_mode"]:checked');
        if (modeEl) mode = modeEl.value;
        
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


async function fetchReportes() {
    const res = await fetch(`api.php?action=get_orders`);
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
            <td>$${o.presupuesto}</td>
            <td>$${o.abono}</td>
            <td>$${o.presupuesto - o.abono}</td>
            <td>-</td>
            <td>-</td>
        `;
        tbody.appendChild(tr);
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
