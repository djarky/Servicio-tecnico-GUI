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

    echo "¡Base de datos actualizada con éxito!\n";

} catch (Exception $e) {
    die("Error: " . $e->getMessage() . "\n");
}
?>
