<?php
require_once 'config.php';

if (!isset($_GET['id'])) {
    die("ID no especificado");
}

$db = getDbConnection();
$stmt = $db->prepare("SELECT o.*, c.nombre as cliente_nombre, c.documento as cliente_doc, c.telefono as cliente_tel, c.direccion as cliente_dir 
                      FROM ordenes o 
                      JOIN clientes c ON o.id_cliente = c.id_cliente 
                      WHERE o.id_orden = ?");
$stmt->execute([$_GET['id']]);
$order = $stmt->fetch();

if (!$order) {
    die("Orden no encontrada");
}

// Fetch Global Config
$config = [];
$cfg_stmt = $db->query("SELECT clave, valor FROM configuracion");
while ($row = $cfg_stmt->fetch()) {
    $config[$row['clave']] = $row['valor'];
}

$moneda = $config['moneda_simbolo'] ?? '$';
$mode = $_GET['mode'] ?? 'large';
$prefix = ($mode === 'ticket') ? 'ticket_' : 'large_';

// Default fonts and sizes based on mode
if ($mode === 'ticket') {
    $fHead = $config['ticket_font_head'] ?? 'Courier New';
    $sHead = ($config['ticket_size_head'] ?? '14') . 'px';
    $fTitle = $config['ticket_font_title'] ?? 'Courier New';
    $sTitle = ($config['ticket_size_title'] ?? '12') . 'px';
    $fBody = $config['ticket_font_body'] ?? 'Courier New';
    $sBody = ($config['ticket_size_body'] ?? '11') . 'px';
    $fCond = $config['ticket_font_cond'] ?? 'Courier New';
    $sCond = ($config['ticket_size_cond'] ?? '9') . 'px';
} else {
    $fHead = $config['large_font_head'] ?? 'Tahoma';
    $sHead = ($config['large_size_head'] ?? '16') . 'px';
    $fTitle = $config['large_font_title'] ?? 'Tahoma';
    $sTitle = ($config['large_size_title'] ?? '14') . 'px';
    $fBody = $config['large_font_body'] ?? 'Tahoma';
    $sBody = ($config['large_size_body'] ?? '13') . 'px';
    $fCond = $config['large_font_cond'] ?? 'Tahoma';
    $sCond = ($config['large_size_cond'] ?? '10') . 'px';
}

$condiciones = $config['condiciones_servicio'] ?? '';
?>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>Orden #<?= $order['id_orden'] ?> - ST-PRO</title>
    <style>
        body { font-family: '<?= $fBody ?>', sans-serif; font-size: <?= $sBody ?>; padding: 20px; color: #333; transition: background 0.3s; }
        .ticket { max-width: 800px; margin: auto; border: 1px solid #ddd; padding: 40px; border-radius: 8px; background: #fff; }
        
        .header { display: flex; justify-content: space-between; border-bottom: 2px solid #2563eb; padding-bottom: 20px; margin-bottom: 20px; }
        .header h1, .header h2 { font-family: '<?= $fHead ?>', sans-serif; font-size: calc(<?= $sHead ?> + 6px); }
        .header p { font-family: '<?= $fHead ?>', sans-serif; font-size: <?= $sHead ?>; }
        
        .details { display: grid; grid-template-columns: 1fr 1fr; gap: 20px; margin-bottom: 30px; }
        
        .section-title { 
            font-family: '<?= $fTitle ?>', sans-serif; 
            font-size: <?= $sTitle ?>; 
            font-weight: bold; 
            text-transform: uppercase; 
            color: #2563eb; 
            margin-bottom: 10px; 
            border-bottom: 1px solid #eee; 
        }
        
        .data-row { margin-bottom: 8px; font-family: '<?= $fBody ?>', sans-serif; font-size: <?= $sBody ?>; }
        .label { color: #666; width: 120px; display: inline-block; }
        
        .conditions-section {
            margin-top: 30px;
            padding: 15px;
            background: #fbfbfb;
            border: 1px dashed #ccc;
            font-family: '<?= $fCond ?>', sans-serif;
            font-size: <?= $sCond ?>;
            color: #555;
            white-space: pre-wrap;
        }

        .footer { margin-top: 40px; text-align: center; border-top: 1px solid #ddd; padding-top: 20px; font-size: 12px; color: #999; }
        
        /* Ticket Mode Styles (Thermal Printer) */
        .mode-ticket { max-width: 300px; padding: 10px; border: 1px dashed #ccc; border-radius: 0; font-size: <?= $sBody ?>; }
        .mode-ticket .header { flex-direction: column; text-align: center; border-bottom: 1px dashed #333; }
        .mode-ticket .header div { text-align: center !important; }
        .mode-ticket .header h1, .mode-ticket .header h2 { font-size: calc(<?= $sHead ?> + 2px); }
        .mode-ticket .details { grid-template-columns: 1fr; gap: 10px; }
        .mode-ticket .label { width: 80px; }
        .mode-ticket .section-title { font-size: <?= $sTitle ?>; margin-top: 10px; }
        .mode-ticket .footer { margin-top: 20px; font-size: 10px; }
        .mode-ticket .data-row { font-size: <?= $sBody ?>; }
        .mode-ticket .conditions-section { font-size: calc(<?= $sCond ?> - 1px); padding: 5px; }

        @media print {
            .no-print { display: none; }
            .ticket { border: none; padding: 0; margin: 0; max-width: 100%; }
            body { padding: 0; background: none; }
            .mode-ticket { max-width: 300px; }
        }
    </style>
</head>
<body class="<?= $mode === 'ticket' ? 'body-ticket' : '' ?>">
    <div class="no-print" style="margin-bottom: 20px; text-align: center;">
        <button onclick="window.print()" style="padding: 10px 20px; background: #2563eb; color: white; border: none; border-radius: 5px; cursor: pointer;">
            Guardar como PDF / Imprimir
        </button>
    </div>

    <div class="ticket <?= $mode === 'ticket' ? 'mode-ticket' : '' ?>">
        <div class="header">
            <div style="display: flex; align-items: center; gap: 15px;">
                <img src="imagenes/logo.png" alt="Logo" style="width: 60px; height: 60px; object-fit: cover;">
                <div>
                    <h1 style="margin: 0; color: #2563eb;">SERVICIO TÉCNICO</h1>
                    <p style="margin: 5px 0;">Comprobante de Orden de Servicio</p>
                </div>
            </div>
            <div style="text-align: right;">
                <h2 style="margin: 0;">ORDEN #<?= $order['id_orden'] ?></h2>
                <p style="margin: 5px 0;">Fecha: <?= $order['fecha'] ?></p>
            </div>
        </div>

        <div class="details">
            <div>
                <div class="section-title">Datos del Cliente</div>
                <div class="data-row"><span class="label">Nombre:</span> <?= $order['cliente_nombre'] ?></div>
                <div class="data-row"><span class="label">Documento:</span> <?= $order['cliente_doc'] ?></div>
                <div class="data-row"><span class="label">Teléfono:</span> <?= $order['cliente_tel'] ?></div>
                <div class="data-row"><span class="label">Dirección:</span> <?= $order['cliente_dir'] ?></div>
            </div>
            <div>
                <div class="section-title">Datos del Equipo</div>
                <div class="data-row"><span class="label">Equipo:</span> <?= $order['tipo_equipo'] ?></div>
                <div class="data-row"><span class="label">Marca:</span> <?= $order['marca'] ?></div>
                <div class="data-row"><span class="label">Modelo:</span> <?= $order['modelo'] ?></div>
                <div class="data-row"><span class="label">Serial:</span> <?= $order['serial'] ?></div>
            </div>
        </div>

        <div style="margin-bottom: 30px;">
            <div class="section-title">Detalles del Servicio</div>
            <div class="data-row"><span class="label">Falla:</span> <?= $order['falla'] ?></div>
            <div class="data-row"><span class="label">Observaciones:</span> <?= $order['observaciones'] ?></div>
            <?php if ($order['reparacion']): ?>
                <div class="data-row"><span class="label">Reparación:</span> <?= $order['reparacion'] ?></div>
            <?php endif; ?>
        </div>

        <div style="display: flex; justify-content: flex-end;">
            <div style="width: 250px; background: #f8fafc; padding: 15px; border-radius: 8px;">
                <div style="display: flex; justify-content: space-between; margin-bottom: 10px;">
                    <span>Presupuesto:</span>
                    <span style="font-weight: bold;"><?= $moneda . number_format($order['presupuesto'], 2) ?></span>
                </div>
                <div style="display: flex; justify-content: space-between; margin-bottom: 10px;">
                    <span>Abono:</span>
                    <span style="font-weight: bold;"><?= $moneda . number_format($order['abono'], 2) ?></span>
                </div>
                <div style="display: flex; justify-content: space-between; border-top: 1px solid #ddd; padding-top: 10px; color: #ef4444; font-size: 18px; font-weight: bold;">
                    <span>Resta:</span>
                    <span><?= $moneda . number_format($order['presupuesto'] - $order['abono'], 2) ?></span>
                </div>
            </div>
        </div>

        <?php if ($condiciones): ?>
        <div class="conditions-section">
            <div style="font-weight: bold; margin-bottom: 5px; text-decoration: underline;">TÉRMINOS Y CONDICIONES DEL SERVICIO:</div>
            <?= htmlspecialchars($condiciones) ?>
        </div>
        <?php endif; ?>

        <div class="footer">
            <p>Gracias por confiar en nuestro servicio técnico.</p>
            <p>Este documento es un comprobante válido para el retiro de su equipo.</p>
        </div>
    </div>

    <script>
        // Trigger print dialog automatically after a short delay
        window.onload = function() {
            setTimeout(() => {
                // window.print();
            }, 500);
        }
    </script>
</body>
</html>
