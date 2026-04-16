<?php
// migrate.php - SQLite to MySQL Migration Script
require_once 'config.php';

// Check if SQLite is available
if (!extension_loaded('sqlite3')) {
    die("La extensión sqlite3 no está habilitada en este servidor PHP.");
}

try {
    $mysql = getDbConnection();
    $sqlite = new PDO('sqlite:ordenes.db');
    $sqlite->setAttribute(PDO::ATTR_ERRMODE, PDO::ATTR_ERRMODE_EXCEPTION);
    $sqlite->setAttribute(PDO::ATTR_DEFAULT_FETCH_MODE, PDO::FETCH_ASSOC);

    echo "--- Iniciando Migración ---\n";

    // 1. Migrate Clients
    echo "Migrando Clientes...\n";
    $clients = $sqlite->query("SELECT * FROM clientes");
    foreach ($clients as $c) {
        $stmt = $mysql->prepare("INSERT INTO clientes (id_cliente, nombre, direccion, documento, telefono) VALUES (?, ?, ?, ?, ?) ON DUPLICATE KEY UPDATE nombre=VALUES(nombre)");
        $stmt->execute([$c['id_cliente'], $c['nombre'], $c['direccion'], $c['documento'], $c['telefono']]);
    }
    echo "Clientes migrados.\n";

    // 2. Migrate Orders
    echo "Migrando Órdenes...\n";
    $orders = $sqlite->query("SELECT * FROM ordenes");
    foreach ($orders as $o) {
        $stmt = $mysql->prepare("INSERT INTO ordenes (id_orden, fecha, id_cliente, tipo_equipo, marca, modelo, serial, clave, accesorios, falla, observaciones, reparacion, abono, presupuesto, estado, reparado, entregado, imagen1, imagen2, imagen3) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)");
        $stmt->execute([
            $o['id_orden'], $o['fecha'], $o['id_cliente'], $o['tipo_equipo'], $o['marca'], $o['modelo'], 
            $o['imei'], // Mapping imei to serial
            $o['clave'], $o['accesorios'], $o['falla'], $o['observaciones'], $o['reparacion'], 
            $o['abono'], $o['presupuesto'], $o['estado_entrega'] ?? 'POR REVISAR', 
            $o['reparado'], $o['entregado'], $o['imagen1'], $o['imagen2'], $o['imagen3']
        ]);
    }
    echo "Órdenes migradas.\n";

    // 3. Migrate Config
    echo "Migrando Configuración...\n";
    $configs = $sqlite->query("SELECT * FROM configuracion");
    foreach ($configs as $cfg) {
        $stmt = $mysql->prepare("INSERT INTO configuracion (clave, valor) VALUES (?, ?) ON DUPLICATE KEY UPDATE valor=VALUES(valor)");
        $stmt->execute([$cfg['clave'], $cfg['valor']]);
    }
    echo "Configuración migrada.\n";

    echo "--- Migración Completada Exitosamente ---\n";

} catch (Exception $e) {
    die("Error durante la migración: " . $e->getMessage());
}
?>
