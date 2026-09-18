<?php
require_once 'config.php';

$db = getDbConnection();

if (!$db) {
    die("Error de conexión");
}

echo "Iniciando actualización de base de datos...\n";

try {
    // 1. Actualizar ENUM de roles (En MySQL/MariaDB usamos MODIFY COLUMN)
    echo "Actualizando roles de usuarios...\n";
    $db->exec("ALTER TABLE usuarios MODIFY COLUMN rol ENUM('admin', 'empleado', 'user') NOT NULL DEFAULT 'user'");

    // 2. Agregar columnas de auditoría a la tabla ordenes
    echo "Agregando columnas de auditoría a ordenes...\n";
    
    // Verificamos si las columnas ya existen para evitar errores
    $check = $db->query("SHOW COLUMNS FROM ordenes LIKE 'id_usuario_creador'");
    if (!$check->fetch()) {
        $db->exec("ALTER TABLE ordenes ADD COLUMN id_usuario_creador INT AFTER imagen3");
        $db->exec("ALTER TABLE ordenes ADD COLUMN id_usuario_actualizador INT AFTER id_usuario_creador");
        
        // Agregar llaves foráneas
        $db->exec("ALTER TABLE ordenes ADD CONSTRAINT fk_creador FOREIGN KEY (id_usuario_creador) REFERENCES usuarios(id) ON DELETE SET NULL");
        $db->exec("ALTER TABLE ordenes ADD CONSTRAINT fk_actualizador FOREIGN KEY (id_usuario_actualizador) REFERENCES usuarios(id) ON DELETE SET NULL");
    }

    // 3. Agregar columnas de tipo_bloqueo y patron
    echo "Agregando columnas de tipo_bloqueo y patron...\n";
    $checkBloqueo = $db->query("SHOW COLUMNS FROM ordenes LIKE 'tipo_bloqueo'");
    if (!$checkBloqueo->fetch()) {
        $db->exec("ALTER TABLE ordenes ADD COLUMN tipo_bloqueo VARCHAR(20) DEFAULT 'clave' AFTER clave");
    }
    $checkPatron = $db->query("SHOW COLUMNS FROM ordenes LIKE 'patron'");
    if (!$checkPatron->fetch()) {
        $db->exec("ALTER TABLE ordenes ADD COLUMN patron VARCHAR(100) NULL AFTER tipo_bloqueo");
    }

    echo "¡Base de datos actualizada con éxito!\n";

} catch (Exception $e) {
    die("Error: " . $e->getMessage() . "\n");
}
?>
