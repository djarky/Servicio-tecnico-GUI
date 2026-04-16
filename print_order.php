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
$mode = $_GET['mode'] ?? 'large';
?>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>Orden #<?= $order['id_orden'] ?> - ST-PRO</title>
    <style>
        body { font-family: 'Inter', sans-serif; padding: 20px; color: #333; transition: background 0.3s; }
        .ticket { max-width: 800px; margin: auto; border: 1px solid #ddd; padding: 40px; border-radius: 8px; background: #fff; }
        .header { display: flex; justify-content: space-between; border-bottom: 2px solid #2563eb; padding-bottom: 20px; margin-bottom: 20px; }
        .details { display: grid; grid-template-columns: 1fr 1fr; gap: 20px; margin-bottom: 30px; }
        .section-title { font-weight: bold; text-transform: uppercase; color: #2563eb; font-size: 14px; margin-bottom: 10px; border-bottom: 1px solid #eee; }
        .data-row { margin-bottom: 8px; font-size: 14px; }
        .label { color: #666; width: 120px; display: inline-block; }
        .footer { margin-top: 50px; text-align: center; border-top: 1px solid #ddd; pt-20; font-size: 12px; color: #999; }
        
        /* Ticket Mode Styles (Thermal Printer) */
        .mode-ticket { max-width: 300px; padding: 10px; border: 1px dashed #ccc; border-radius: 0; font-size: 12px; }
        .mode-ticket .header { flex-direction: column; text-align: center; border-bottom: 1px dashed #333; }
        .mode-ticket .header div { text-align: center !important; }
        .mode-ticket .details { grid-template-columns: 1fr; gap: 10px; }
        .mode-ticket .label { width: 80px; }
        .mode-ticket .section-title { font-size: 12px; margin-top: 10px; }
        .mode-ticket .footer { margin-top: 20px; font-size: 10px; }
        .mode-ticket .data-row { font-size: 12px; }

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
                    <span style="font-weight: bold;">$<?= number_format($order['presupuesto'], 2) ?></span>
                </div>
                <div style="display: flex; justify-content: space-between; margin-bottom: 10px;">
                    <span>Abono:</span>
                    <span style="font-weight: bold;">$<?= number_format($order['abono'], 2) ?></span>
                </div>
                <div style="display: flex; justify-content: space-between; border-top: 1px solid #ddd; padding-top: 10px; color: #ef4444; font-size: 18px; font-weight: bold;">
                    <span>Resta:</span>
                    <span>$<?= number_format($order['presupuesto'] - $order['abono'], 2) ?></span>
                </div>
            </div>
        </div>

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
