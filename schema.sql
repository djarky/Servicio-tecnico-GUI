-- Schema for Servicio Técnico (MySQL)

CREATE DATABASE IF NOT EXISTS servicio_tecnico;
USE servicio_tecnico;

-- Users Table
CREATE TABLE IF NOT EXISTS usuarios (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    usuario VARCHAR(50) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    rol ENUM('admin', 'user') NOT NULL DEFAULT 'user',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Clients Table
CREATE TABLE IF NOT EXISTS clientes (
    id_cliente INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(150) NOT NULL,
    direccion TEXT,
    documento VARCHAR(50) UNIQUE,
    telefono VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Orders Table
CREATE TABLE IF NOT EXISTS ordenes (
    id_orden INT AUTO_INCREMENT PRIMARY KEY,
    fecha DATE NOT NULL,
    id_cliente INT NOT NULL,
    tipo_equipo VARCHAR(100),
    marca VARCHAR(100),
    modelo VARCHAR(100),
    serial VARCHAR(100),
    clave VARCHAR(100),
    accesorios TEXT,
    falla TEXT,
    observaciones TEXT,
    reparacion TEXT,
    abono DECIMAL(10, 2) DEFAULT 0.00,
    presupuesto DECIMAL(10, 2) DEFAULT 0.00,
    estado VARCHAR(50) DEFAULT 'POR REVISAR',
    reparado DATE NULL,
    entregado DATE NULL,
    imagen1 VARCHAR(255),
    imagen2 VARCHAR(255),
    imagen3 VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_cliente) REFERENCES clientes(id_cliente) ON DELETE CASCADE
);

-- Order Items Table (Materiales/Repuestos usados)
CREATE TABLE IF NOT EXISTS orden_repuestos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    id_orden INT NOT NULL,
    id_inventario INT NOT NULL,
    cantidad INT NOT NULL DEFAULT 1,
    precio_costo DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    precio_venta DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_orden) REFERENCES ordenes(id_orden) ON DELETE CASCADE,
    FOREIGN KEY (id_inventario) REFERENCES inventario(id) ON DELETE RESTRICT
);

-- Configuration Table
CREATE TABLE IF NOT EXISTS configuracion (
    id INT AUTO_INCREMENT PRIMARY KEY,
    clave VARCHAR(100) NOT NULL UNIQUE,
    valor TEXT
);

-- Service Conditions Table
CREATE TABLE IF NOT EXISTS condiciones_servicio (
    id INT AUTO_INCREMENT PRIMARY KEY,
    contenido TEXT NOT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Archivos de las órdenes (Multimedia)
CREATE TABLE IF NOT EXISTS orden_archivos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    id_orden INT NOT NULL,
    estado INT NOT NULL COMMENT '1=Antes, 2=Durante, 3=Después',
    archivo_ruta VARCHAR(255) NOT NULL,
    tipo_archivo ENUM('image', 'video') NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_orden) REFERENCES ordenes(id_orden) ON DELETE CASCADE
);

-- Inventario
CREATE TABLE IF NOT EXISTS inventario (
    id INT AUTO_INCREMENT PRIMARY KEY,
    codigo VARCHAR(100),
    nombre VARCHAR(150) NOT NULL,
    descripcion TEXT,
    categoria VARCHAR(100),
    cantidad INT DEFAULT 0,
    precio_costo DECIMAL(10, 2) DEFAULT 0.00,
    precio_venta DECIMAL(10, 2) DEFAULT 0.00,
    ubicacion VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Base de datos lista para recibir administradores via front-end
