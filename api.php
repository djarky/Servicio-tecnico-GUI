<?php
require_once 'config.php';

header('Content-Type: application/json');

// Get POST data
$data = json_decode(file_get_contents('php://input'), true);
$method = $_SERVER['REQUEST_METHOD'];
$action = isset($_GET['action']) ? $_GET['action'] : '';

$db = getDbConnection();

if (!$db) {
    global $DB_CONNECTION_ERROR;
    http_response_code(500);
    echo json_encode(['error' => 'Error de BD: ' . $DB_CONNECTION_ERROR]);
    exit;
}

// Simple Auth check
function checkAuth($role = null) {
    if (!isset($_SESSION['user_id'])) {
        http_response_code(401);
        echo json_encode(['error' => 'No autorizado']);
        exit;
    }
    if ($role && $_SESSION['role'] !== $role) {
        http_response_code(403);
        echo json_encode(['error' => 'Permisos insuficientes']);
        exit;
    }
}

switch ($action) {
    case 'setup':
        $stmt = $db->query("SELECT COUNT(*) FROM usuarios");
        if ($stmt->fetchColumn() > 0) {
            http_response_code(403);
            echo json_encode(['error' => 'Ya existe un administrador en el sistema.']);
            exit;
        }
        $nombre = $data['nombre'] ?? '';
        $usuario = $data['usuario'] ?? '';
        $password = $data['password'] ?? '';
        
        $hash = password_hash($password, PASSWORD_DEFAULT);
        $stmt = $db->prepare("INSERT INTO usuarios (nombre, usuario, password, rol) VALUES (?, ?, ?, 'admin')");
        if ($stmt->execute([$nombre, $usuario, $hash])) {
            $_SESSION['user_id'] = $db->lastInsertId();
            $_SESSION['nombre'] = $nombre;
            $_SESSION['role'] = 'admin';
            echo json_encode(['success' => true]);
        } else {
            http_response_code(500);
            echo json_encode(['error' => 'Error de base de datos creando usuario']);
        }
        break;

    case 'login':
        $usuario = $data['usuario'] ?? '';
        $password = $data['password'] ?? '';
        
        $stmt = $db->prepare("SELECT * FROM usuarios WHERE usuario = ?");
        $stmt->execute([$usuario]);
        $user = $stmt->fetch();
        
        if ($user && password_verify($password, $user['password'])) {
            $_SESSION['user_id'] = $user['id'];
            $_SESSION['nombre'] = $user['nombre'];
            $_SESSION['role'] = $user['rol'];
            echo json_encode(['success' => true, 'user' => ['nombre' => $user['nombre'], 'rol' => $user['rol']]]);
        } else {
            http_response_code(401);
            echo json_encode(['error' => 'Usuario o contraseña incorrectos']);
        }
        break;

    case 'logout':
        session_destroy();
        echo json_encode(['success' => true]);
        break;

    case 'get_orders':
        checkAuth();
        $search = $_GET['q'] ?? '';
        $sql = "SELECT o.*, c.nombre as cliente_nombre, c.documento as cliente_doc 
                FROM ordenes o 
                JOIN clientes c ON o.id_cliente = c.id_cliente";
        if ($search) {
            $sql .= " WHERE c.nombre LIKE ? OR c.documento LIKE ? OR o.id_orden = ?";
            $stmt = $db->prepare($sql);
            $stmt->execute(["%$search%", "%$search%", $search]);
        } else {
            $stmt = $db->query($sql);
        }
        echo json_encode($stmt->fetchAll());
        break;

    case 'save_order':
        checkAuth();
        // Extract data and perform INSERT/UPDATE
        // Note: For brevity, I'm simplifying the client logic. 
        // In a real app, you'd check if client exists by document first.
        
        $documento = $data['documento'] ?? '';
        $clientId = $data['id_cliente'] ?? null;

        if (!$clientId && !empty($documento)) {
            // Check if client already exists by document
            $stmt = $db->prepare("SELECT id_cliente FROM clientes WHERE documento = ?");
            $stmt->execute([$documento]);
            $existing = $stmt->fetch();
            if ($existing) {
                $clientId = $existing['id_cliente'];
                // Update client info with current form data
                $stmt = $db->prepare("UPDATE clientes SET nombre=?, telefono=?, direccion=? WHERE id_cliente=?");
                $stmt->execute([$data['nombre'], $data['telefono'], $data['direccion'], $clientId]);
            } else {
                // New client
                $stmt = $db->prepare("INSERT INTO clientes (nombre, documento, telefono, direccion) VALUES (?, ?, ?, ?)");
                $stmt->execute([$data['nombre'], $documento, $data['telefono'], $data['direccion']]);
                $clientId = $db->lastInsertId();
            }
        } else if ($clientId) {
            // Update existing client data linked to order
            $stmt = $db->prepare("UPDATE clientes SET nombre=?, documento=?, telefono=?, direccion=? WHERE id_cliente=?");
            $stmt->execute([$data['nombre'], $documento, $data['telefono'], $data['direccion'], $clientId]);
        }

        $orderId = $data['id_orden'] ?? null;
        if ($orderId) {
            // Update order
            $reparado = !empty($data['reparado']) ? $data['reparado'] : null;
            $entregado = !empty($data['entregado']) ? $data['entregado'] : null;

            $stmt = $db->prepare("UPDATE ordenes SET tipo_equipo=?, marca=?, modelo=?, serial=?, clave=?, accesorios=?, falla=?, observaciones=?, reparacion=?, abono=?, presupuesto=?, estado=?, reparado=?, entregado=? WHERE id_orden=?");
            $stmt->execute([
                $data['tipo_equipo'] ?? '', $data['marca'] ?? '', $data['modelo'] ?? '', $data['serial'] ?? '', $data['clave'] ?? '', 
                $data['accesorios'] ?? '', $data['falla'] ?? '', $data['observaciones'] ?? '', $data['reparacion'] ?? '', 
                $data['abono'] ?? 0, $data['presupuesto'] ?? 0, $data['estado'] ?? 'POR REVISAR', $reparado, $entregado, $orderId
            ]);
            echo json_encode(['success' => true, 'id_orden' => $orderId]);
        } else {
            // New order
            $stmt = $db->prepare("INSERT INTO ordenes (fecha, id_cliente, tipo_equipo, marca, modelo, serial, clave, accesorios, falla, observaciones, presupuesto, estado) VALUES (CURDATE(), ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'POR REVISAR')");
            $stmt->execute([
                $clientId, $data['tipo_equipo'], $data['marca'], $data['modelo'], $data['serial'], 
                $data['clave'], $data['accesorios'], $data['falla'], $data['observaciones'], $data['presupuesto']
            ]);
            echo json_encode(['success' => true, 'id_orden' => $db->lastInsertId()]);
        }
        break;

    case 'get_media':
        checkAuth();
        $id_orden = $_GET['id_orden'] ?? null;
        $estado = $_GET['estado'] ?? null;
        if ($id_orden && $estado) {
            $stmt = $db->prepare("SELECT * FROM orden_archivos WHERE id_orden = ? AND estado = ? ORDER BY created_at DESC");
            $stmt->execute([$id_orden, $estado]);
            echo json_encode($stmt->fetchAll());
        } else {
            http_response_code(400);
            echo json_encode(['error' => 'Faltan parámetros id_orden o estado']);
        }
        break;

    case 'upload_media':
        checkAuth();
        $id_orden = $_POST['id_orden'] ?? null;
        $estado = $_POST['estado'] ?? null;
        
        if (!$id_orden || !$estado || !isset($_FILES['archivo'])) {
            http_response_code(400);
            echo json_encode(['error' => 'Datos incompletos para la subida']);
            exit;
        }

        $file = $_FILES['archivo'];
        $ext = strtolower(pathinfo($file['name'], PATHINFO_EXTENSION));
        $allowedImages = ['jpg', 'jpeg', 'png', 'gif', 'webp'];
        $allowedVideos = ['mp4', 'webm', 'mov'];
        
        $tipo = '';
        if (in_array($ext, $allowedImages)) $tipo = 'image';
        else if (in_array($ext, $allowedVideos)) $tipo = 'video';
        else {
            echo json_encode(['error' => 'Formato no permitido (Solo imágenes y videos)']);
            exit;
        }

        $targetDir = UPLOAD_DIR . "$id_orden/$estado/";
        if (!is_dir($targetDir)) mkdir($targetDir, 0777, true);

        $fileName = time() . "_" . basename($file['name']);
        $targetFile = $targetDir . $fileName;
        $dbPath = "uploads/$id_orden/$estado/$fileName";

        if (move_uploaded_file($file['tmp_name'], $targetFile)) {
            $stmt = $db->prepare("INSERT INTO orden_archivos (id_orden, estado, archivo_ruta, tipo_archivo) VALUES (?, ?, ?, ?)");
            $stmt->execute([$id_orden, $estado, $dbPath, $tipo]);
            echo json_encode(['success' => true, 'path' => $dbPath, 'tipo' => $tipo]);
        } else {
            http_response_code(500);
            echo json_encode(['error' => 'Error al mover el archivo al servidor']);
        }
        break;

    case 'delete_media':
        checkAuth();
        $id = $_GET['id'] ?? null;
        if ($id) {
            $stmt = $db->prepare("SELECT archivo_ruta FROM orden_archivos WHERE id = ?");
            $stmt->execute([$id]);
            $archivo = $stmt->fetch();
            if ($archivo) {
                $fullPath = __DIR__ . '/' . $archivo['archivo_ruta'];
                if (file_exists($fullPath)) unlink($fullPath);
                
                $stmt = $db->prepare("DELETE FROM orden_archivos WHERE id = ?");
                $stmt->execute([$id]);
                echo json_encode(['success' => true]);
            } else {
                echo json_encode(['error' => 'Archivo no encontrado en BD']);
            }
        }
        break;

    case 'delete_order':
        checkAuth('admin'); // Only admins can delete
        $id = $_GET['id'] ?? null;
        if ($id) {
            $stmt = $db->prepare("DELETE FROM ordenes WHERE id_orden = ?");
            $stmt->execute([$id]);
            echo json_encode(['success' => true]);
        }
        break;

    default:
        http_response_code(404);
        echo json_encode(['error' => 'Acción no encontrada']);
        break;
}
?>
