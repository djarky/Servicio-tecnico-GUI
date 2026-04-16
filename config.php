<?php
// Cargar configuración desde el archivo INI
$ini_path = __DIR__ . '/config.ini';
$config = parse_ini_file($ini_path, true);

if (!$config) {
    die("Error: No se encontró el archivo config.ini o tiene un error de sintaxis.");
}

// Database Config
define('DB_HOST', $config['database']['host']);
define('DB_NAME', $config['database']['name']);
define('DB_USER', $config['database']['user']); 
define('DB_PASS', $config['database']['pass']); 

// App Constants
define('UPLOAD_DIR', __DIR__ . '/uploads/');
define('BASE_URL', $config['app']['base_url']); 

// Error reporting (Dev mode)
error_reporting(E_ALL);
ini_set('display_errors', 1);

// Database connection
$DB_CONNECTION_ERROR = '';
function getDbConnection() {
    global $DB_CONNECTION_ERROR;
    try {
        $dsn = "mysql:host=" . DB_HOST . ";dbname=" . DB_NAME . ";charset=utf8mb4";
        $options = [
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
            PDO::ATTR_EMULATE_PREPARES => false,
        ];
        return new PDO($dsn, DB_USER, DB_PASS, $options);
    } catch (PDOException $e) {
        $DB_CONNECTION_ERROR = $e->getMessage();
        return null;
    }
}

// Session start if not already started
if (session_status() === PHP_SESSION_NONE) {
    session_start();
}
?>
