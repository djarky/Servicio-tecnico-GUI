<?php
require_once 'config.php';

header('Content-Type: application/json');

// Manejo global de errores para que siempre devuelva JSON
set_error_handler(function($errno, $errstr, $errfile, $errline) {
    if (!(error_reporting() & $errno)) return false;
    http_response_code(500);
    echo json_encode([
        'error' => "PHP Error [$errno]: $errstr",
        'file' => $errfile,
        'line' => $errline
    ]);
    exit;
});

set_exception_handler(function($e) {
    http_response_code(500);
    echo json_encode([
        'error' => "Uncaught Exception: " . $e->getMessage(),
        'file' => $e->getFile(),
        'line' => $e->getLine()
    ]);
    exit;
});

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
    if (!isset($_SESSION['user_id']) && !isset($_SESSION['cliente_id'])) {
        http_response_code(401);
        echo json_encode(['error' => 'No autorizado']);
        exit;
    }
    
    $currentRole = $_SESSION['role'] ?? 'cliente';

    if ($role) {
        if (is_array($role)) {
            if (!in_array($currentRole, $role)) {
                http_response_code(403);
                echo json_encode(['error' => 'Permisos insuficientes']);
                exit;
            }
        } else if ($currentRole !== $role) {
            http_response_code(403);
            echo json_encode(['error' => 'Permisos insuficientes']);
            exit;
        }
    }
}

function formatDatePicker($date) {
    if (empty($date)) return null;
    // Convierte DD/MM/YYYY a YYYY-MM-DD
    $parts = explode('/', $date);
    if (count($parts) === 3) {
        return "{$parts[2]}-{$parts[1]}-{$parts[0]}";
    }
    return $date;
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

    case 'client_login':
        $documento = $data['documento'] ?? '';
        $nombre = $data['nombre'] ?? '';
        
        $stmt = $db->prepare("SELECT * FROM clientes WHERE documento = ? AND nombre LIKE ?");
        $stmt->execute([$documento, "%$nombre%"]);
        $cliente = $stmt->fetch();
        
        if ($cliente) {
            $_SESSION['cliente_id'] = $cliente['id_cliente'];
            $_SESSION['nombre'] = $cliente['nombre'];
            $_SESSION['role'] = 'cliente';
            echo json_encode(['success' => true, 'user' => ['nombre' => $cliente['nombre'], 'rol' => 'cliente']]);
        } else {
            http_response_code(401);
            echo json_encode(['error' => 'No se encontró un cliente con esos datos o el nombre no coincide.']);
        }
        break;

    case 'logout':
        session_destroy();
        echo json_encode(['success' => true]);
        break;

    case 'get_orders':
        checkAuth();
        $search = $_GET['q'] ?? '';
        $desde = $_GET['desde'] ?? null;
        $hasta = $_GET['hasta'] ?? null;
        
        $sql = "SELECT o.*, c.nombre as cliente_nombre, c.documento as cliente_doc,
                u1.nombre as creador_nombre, u2.nombre as actualizador_nombre
                FROM ordenes o 
                JOIN clientes c ON o.id_cliente = c.id_cliente 
                LEFT JOIN usuarios u1 ON o.id_usuario_creador = u1.id
                LEFT JOIN usuarios u2 ON o.id_usuario_actualizador = u2.id
                WHERE 1=1";
        $params = [];
        
        if ($_SESSION['role'] === 'cliente') {
            $sql .= " AND o.id_cliente = ?";
            array_push($params, $_SESSION['cliente_id']);
        } else if ($search) {
            $sql .= " AND (c.nombre LIKE ? OR c.documento LIKE ? OR o.id_orden = ?)";
            array_push($params, "%$search%", "%$search%", $search);
        }
        
        if ($desde && $hasta) {
            $sql .= " AND o.fecha BETWEEN ? AND ?";
            array_push($params, $desde, $hasta);
        }
        
        $stmt = $db->prepare($sql);
        $stmt->execute($params);
        echo json_encode($stmt->fetchAll());
        break;

    case 'get_customers':
        checkAuth();
        $search = $_GET['q'] ?? '';
        $sql = "SELECT * FROM clientes WHERE 1=1";
        $params = [];
        if ($search) {
            $sql .= " AND (nombre LIKE ? OR documento LIKE ? OR telefono LIKE ?)";
            array_push($params, "%$search%", "%$search%", "%$search%");
        }
        $sql .= " ORDER BY nombre ASC LIMIT 100";
        $stmt = $db->prepare($sql);
        $stmt->execute($params);
        echo json_encode($stmt->fetchAll());
        break;

    case 'save_order':
        try {
            checkAuth(['admin', 'empleado']);
            
            $documento = $data['documento'] ?? '';
            $clientId = $data['id_cliente'] ?? null;

            if (!$clientId && !empty($documento)) {
                $stmt = $db->prepare("SELECT id_cliente FROM clientes WHERE documento = ?");
                $stmt->execute([$documento]);
                $existing = $stmt->fetch();
                if ($existing) {
                    $clientId = $existing['id_cliente'];
                    $stmt = $db->prepare("UPDATE clientes SET nombre=?, telefono=?, direccion=? WHERE id_cliente=?");
                    $stmt->execute([$data['nombre'], $data['telefono'], $data['direccion'], $clientId]);
                } else {
                    $stmt = $db->prepare("INSERT INTO clientes (nombre, documento, telefono, direccion) VALUES (?, ?, ?, ?)");
                    $stmt->execute([$data['nombre'], $documento, $data['telefono'], $data['direccion']]);
                    $clientId = $db->lastInsertId();
                }
            } else if ($clientId) {
                $stmt = $db->prepare("UPDATE clientes SET nombre=?, documento=?, telefono=?, direccion=? WHERE id_cliente=?");
                $stmt->execute([$data['nombre'], $documento, $data['telefono'], $data['direccion'], $clientId]);
            }

            $orderId = $data['id_orden'] ?? null;
            $userId = $_SESSION['user_id'] ?? null;

            if ($orderId) {
                // Update order
                $reparado = formatDatePicker($data['reparado'] ?? null);
                $entregado = formatDatePicker($data['entregado'] ?? null);

                $stmt = $db->prepare("UPDATE ordenes SET tipo_equipo=?, marca=?, modelo=?, serial=?, clave=?, accesorios=?, falla=?, observaciones=?, reparacion=?, abono=?, presupuesto=?, estado=?, reparado=?, entregado=?, id_usuario_actualizador=? WHERE id_orden=?");
                $stmt->execute([
                    $data['tipo_equipo'] ?? '', $data['marca'] ?? '', $data['modelo'] ?? '', $data['serial'] ?? '', $data['clave'] ?? '', 
                    $data['accesorios'] ?? '', $data['falla'] ?? '', $data['observaciones'] ?? '', $data['reparacion'] ?? '', 
                    $data['abono'] ?? 0, $data['presupuesto'] ?? 0, $data['estado'] ?? 'POR REVISAR', $reparado, $entregado, $userId, $orderId
                ]);
                echo json_encode(['success' => true, 'id_orden' => $orderId]);
            } else {
                // New order
                $stmt = $db->prepare("INSERT INTO ordenes (fecha, id_cliente, tipo_equipo, marca, modelo, serial, clave, accesorios, falla, observaciones, presupuesto, estado, id_usuario_creador) VALUES (CURDATE(), ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'POR REVISAR', ?)");
                $stmt->execute([
                    $clientId, $data['tipo_equipo'], $data['marca'], $data['modelo'], $data['serial'], 
                    $data['clave'], $data['accesorios'], $data['falla'], $data['observaciones'], $data['presupuesto'], $userId
                ]);
                echo json_encode(['success' => true, 'id_orden' => $db->lastInsertId()]);
            }
        } catch (Exception $e) {
            http_response_code(500);
            echo json_encode(['error' => 'Error al guardar la orden: ' . $e->getMessage()]);
        }
        break;

    case 'get_media':
        try {
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
        } catch (Exception $e) {
            http_response_code(500);
            echo json_encode(['error' => $e->getMessage()]);
        }
        break;

    case 'upload_media':
        try {
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
        } catch (Exception $e) {
            http_response_code(500);
            echo json_encode(['error' => $e->getMessage()]);
        }
        break;

    case 'delete_media':
        try {
            checkAuth();
            $id = $_GET['id'] ?? null;
            if ($id) {
                $stmt = $db->prepare("SELECT url FROM orden_archivos WHERE id = ?");
                $stmt->execute([$id]);
                $archivo = $stmt->fetch();
                if ($archivo) {
                    $fullPath = __DIR__ . '/' . $archivo['url'];
                    if (file_exists($fullPath)) @unlink($fullPath);
                    
                    $stmt = $db->prepare("DELETE FROM orden_archivos WHERE id = ?");
                    $stmt->execute([$id]);
                    echo json_encode(['success' => true]);
                } else {
                    echo json_encode(['error' => 'Archivo no encontrado en BD']);
                }
            }
        } catch (Exception $e) {
            http_response_code(500);
            echo json_encode(['error' => $e->getMessage()]);
        }
        break;

    case 'delete_order':
        try {
            checkAuth('admin'); // Solo admins pueden eliminar
            $id = $_GET['id'] ?? null;
            if ($id) {
                // 1. Eliminar archivos físicos primero
                $targetDir = UPLOAD_DIR . "$id/";
                
                if (!function_exists('deleteDir')) {
                    function deleteDir($dirPath) {
                        if (!is_dir($dirPath)) return;
                        $files = array_diff(scandir($dirPath), array('.', '..'));
                        foreach ($files as $file) {
                            (is_dir("$dirPath/$file")) ? deleteDir("$dirPath/$file") : unlink("$dirPath/$file");
                        }
                        return rmdir($dirPath);
                    }
                }
                
                deleteDir($targetDir);

                // 2. Eliminar de la base de datos
                $stmt = $db->prepare("DELETE FROM ordenes WHERE id_orden = ?");
                if ($stmt->execute([$id])) {
                    echo json_encode(['success' => true]);
                } else {
                    http_response_code(500);
                    echo json_encode(['error' => 'No se pudo eliminar la orden de la base de datos']);
                }
            }
        } catch (Exception $e) {
            http_response_code(500);
            echo json_encode(['error' => 'Error al eliminar orden: ' . $e->getMessage()]);
        }
        break;
    
    case 'get_report_data':
        checkAuth();
        $desde = $_GET['desde'] ?? date('Y-01-01'); // Por defecto inicio de año
        $hasta = $_GET['hasta'] ?? date('Y-12-31'); // Por defecto fin de año
        
        // 1. Tipos de Equipo
        $stmt = $db->prepare("SELECT tipo_equipo as label, COUNT(*) as value FROM ordenes WHERE fecha BETWEEN ? AND ? GROUP BY tipo_equipo");
        $stmt->execute([$desde, $hasta]);
        $tipos = $stmt->fetchAll();
        
        // 2. Estado de Reparaciones
        $stmt = $db->prepare("SELECT estado as label, COUNT(*) as value FROM ordenes WHERE fecha BETWEEN ? AND ? GROUP BY estado");
        $stmt->execute([$desde, $hasta]);
        $estados = $stmt->fetchAll();
        
        // 3. Ingresos Mensuales y Gastos
        $stmt = $db->prepare("
            SELECT 
                DATE_FORMAT(o.fecha, '%Y-%m') as label, 
                SUM(o.presupuesto) as value,
                SUM(
                    (SELECT COALESCE(SUM(orep.precio_costo * orep.cantidad), 0) 
                     FROM orden_repuestos orep 
                     WHERE orep.id_orden = o.id_orden)
                ) as costo
            FROM ordenes o 
            WHERE o.fecha BETWEEN ? AND ? 
            GROUP BY label 
            ORDER BY label ASC
        ");
        $stmt->execute([$desde, $hasta]);
        $ingresos = $stmt->fetchAll();
        
        echo json_encode([
            'tipos' => $tipos,
            'estados' => $estados,
            'ingresos' => $ingresos
        ]);
        break;

    case 'get_config':
        checkAuth();
        $stmt = $db->query("SELECT clave, valor FROM configuracion");
        $config = [];
        while ($row = $stmt->fetch()) {
            $config[$row['clave']] = $row['valor'];
        }
        // Default values
        if (!isset($config['moneda_simbolo'])) $config['moneda_simbolo'] = '$';
        echo json_encode($config);
        break;

    case 'save_config':
        checkAuth('admin');
        foreach ($data as $key => $val) {
            $stmt = $db->prepare("INSERT INTO configuracion (clave, valor) VALUES (?, ?) ON DUPLICATE KEY UPDATE valor = ?");
            $stmt->execute([$key, $val, $val]);
        }
        echo json_encode(['success' => true]);
        break;

    case 'get_inventory':
        checkAuth();
        $search = $_GET['q'] ?? '';
        $sql = "SELECT * FROM inventario WHERE 1=1";
        $params = [];
        if ($search) {
            $sql .= " AND (nombre LIKE ? OR codigo LIKE ? OR categoria LIKE ?)";
            array_push($params, "%$search%", "%$search%", "%$search%");
        }
        $sql .= " ORDER BY nombre ASC";
        $stmt = $db->prepare($sql);
        $stmt->execute($params);
        echo json_encode($stmt->fetchAll());
        break;

    case 'save_inventory_item':
        try {
            checkAuth('admin');
            $id = $data['id'] ?? null;
            $codigo = $data['codigo'] ?? '';
            $nombre = $data['nombre'] ?? '';
            $descripcion = $data['descripcion'] ?? '';
            $categoria = $data['categoria'] ?? '';
            $cantidad = (int)($data['cantidad'] ?? 0);
            $precio_costo = (float)($data['precio_costo'] ?? 0);
            $precio_venta = (float)($data['precio_venta'] ?? 0);
            $ubicacion = $data['ubicacion'] ?? '';

            if ($id) {
                $stmt = $db->prepare("UPDATE inventario SET codigo=?, nombre=?, descripcion=?, categoria=?, cantidad=?, precio_costo=?, precio_venta=?, ubicacion=? WHERE id=?");
                $stmt->execute([$codigo, $nombre, $descripcion, $categoria, $cantidad, $precio_costo, $precio_venta, $ubicacion, $id]);
                echo json_encode(['success' => true]);
            } else {
                $stmt = $db->prepare("INSERT INTO inventario (codigo, nombre, descripcion, categoria, cantidad, precio_costo, precio_venta, ubicacion) VALUES (?, ?, ?, ?, ?, ?, ?, ?)");
                $stmt->execute([$codigo, $nombre, $descripcion, $categoria, $cantidad, $precio_costo, $precio_venta, $ubicacion]);
                echo json_encode(['success' => true, 'id' => $db->lastInsertId()]);
            }
        } catch (Exception $e) {
            http_response_code(500);
            echo json_encode(['error' => 'Error al guardar inventario: ' . $e->getMessage()]);
        }
        break;

    case 'get_order_items':
        checkAuth();
        $id_orden = $_GET['id_orden'] ?? null;
        if ($id_orden) {
            $stmt = $db->prepare("SELECT orp.*, i.nombre, i.codigo FROM orden_repuestos orp JOIN inventario i ON orp.id_inventario = i.id WHERE orp.id_orden = ?");
            $stmt->execute([$id_orden]);
            echo json_encode($stmt->fetchAll());
        } else {
            echo json_encode([]);
        }
        break;

    case 'add_order_item':
        try {
            checkAuth();
            $id_orden = $data['id_orden'] ?? null;
            $id_inventario = $data['id_inventario'] ?? null;
            $cantidad = (int)($data['cantidad'] ?? 1);
            
            if ($id_orden && $id_inventario) {
                // Obtener precio de costo y venta del inventario
                $stmt = $db->prepare("SELECT precio_costo, precio_venta, cantidad FROM inventario WHERE id = ?");
                $stmt->execute([$id_inventario]);
                $inv = $stmt->fetch();
                
                if ($inv && $inv['cantidad'] >= $cantidad) {
                    // Descontar del inventario
                    $stmt = $db->prepare("UPDATE inventario SET cantidad = cantidad - ? WHERE id = ?");
                    $stmt->execute([$cantidad, $id_inventario]);
                    
                    // Agregar a orden
                    $stmt = $db->prepare("INSERT INTO orden_repuestos (id_orden, id_inventario, cantidad, precio_costo, precio_venta) VALUES (?, ?, ?, ?, ?)");
                    $stmt->execute([$id_orden, $id_inventario, $cantidad, $inv['precio_costo'], $inv['precio_venta']]);
                    
                    echo json_encode(['success' => true]);
                } else {
                    http_response_code(400);
                    echo json_encode(['error' => 'Stock insuficiente']);
                }
            }
        } catch (Exception $e) {
            http_response_code(500);
            echo json_encode(['error' => $e->getMessage()]);
        }
        break;

    case 'delete_order_item':
        checkAuth();
        $id = $_GET['id'] ?? null;
        if ($id) {
            // Restaurar stock
            $stmt = $db->prepare("SELECT id_inventario, cantidad FROM orden_repuestos WHERE id = ?");
            $stmt->execute([$id]);
            $item = $stmt->fetch();
            
            if ($item) {
                $stmt = $db->prepare("UPDATE inventario SET cantidad = cantidad + ? WHERE id = ?");
                $stmt->execute([$item['cantidad'], $item['id_inventario']]);
                
                $stmt = $db->prepare("DELETE FROM orden_repuestos WHERE id = ?");
                $stmt->execute([$id]);
                echo json_encode(['success' => true]);
            }
        }
        break;

    case 'delete_inventory_item':
        checkAuth('admin'); // Only admins can delete items completely
        $id = $_GET['id'] ?? null;
        if ($id) {
            $stmt = $db->prepare("DELETE FROM inventario WHERE id = ?");
            if ($stmt->execute([$id])) {
                echo json_encode(['success' => true]);
            } else {
                http_response_code(500);
                echo json_encode(['error' => 'No se pudo eliminar el artículo']);
            }
        }
        break;

    case 'get_employees':
        checkAuth('admin');
        $stmt = $db->query("SELECT id, nombre, usuario, rol, created_at FROM usuarios WHERE rol IN ('admin', 'empleado') ORDER BY nombre ASC");
        echo json_encode($stmt->fetchAll());
        break;

    case 'save_employee':
        checkAuth('admin');
        $id = $data['id'] ?? null;
        $nombre = $data['nombre'] ?? '';
        $usuario = $data['usuario'] ?? '';
        $password = $data['password'] ?? '';
        $rol = $data['rol'] ?? 'empleado';

        if ($id) {
            if (!empty($password)) {
                $hash = password_hash($password, PASSWORD_DEFAULT);
                $stmt = $db->prepare("UPDATE usuarios SET nombre=?, usuario=?, password=?, rol=? WHERE id=?");
                $stmt->execute([$nombre, $usuario, $hash, $rol, $id]);
            } else {
                $stmt = $db->prepare("UPDATE usuarios SET nombre=?, usuario=?, rol=? WHERE id=?");
                $stmt->execute([$nombre, $usuario, $rol, $id]);
            }
        } else {
            $hash = password_hash($password, PASSWORD_DEFAULT);
            $stmt = $db->prepare("INSERT INTO usuarios (nombre, usuario, password, rol) VALUES (?, ?, ?, ?)");
            $stmt->execute([$nombre, $usuario, $hash, $rol]);
        }
        echo json_encode(['success' => true]);
        break;

    case 'delete_employee':
        checkAuth('admin');
        $id = $_GET['id'] ?? null;
        if ($id && $id != $_SESSION['user_id']) {
            $stmt = $db->prepare("DELETE FROM usuarios WHERE id = ?");
            $stmt->execute([$id]);
            echo json_encode(['success' => true]);
        } else {
            http_response_code(400);
            echo json_encode(['error' => 'No puedes eliminarte a ti mismo o falta el ID']);
        }
        break;

    default:
        http_response_code(404);
        echo json_encode(['error' => 'Acción no encontrada']);
        break;
}
