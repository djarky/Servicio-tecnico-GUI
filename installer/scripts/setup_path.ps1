# setup_path.ps1
# Agrega los directorios de PHP y MySQL de XAMPP al PATH del sistema.
# Se ejecuta con privilegios de Administrador durante la instalacion de ST-PRO.

param()

$phpPath   = "C:\xampp\php"
$mysqlPath = "C:\xampp\mysql\bin"

$regPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment"

try {
    $currentPath = (Get-ItemProperty -Path $regPath -Name Path -ErrorAction Stop).Path
} catch {
    Write-Host "[WARN] No se pudo leer el PATH del sistema. Continuando..."
    exit 0
}

$pathParts = $currentPath -split ';' | Where-Object { $_ -ne "" }
$modified  = $false

foreach ($entry in @($phpPath, $mysqlPath)) {
    $already = $pathParts | Where-Object { $_.TrimEnd('\') -ieq $entry.TrimEnd('\') }
    if (-not $already) {
        $pathParts += $entry
        $modified = $true
        Write-Host "[PATH] Agregado: $entry"
    } else {
        Write-Host "[PATH] Ya existia: $entry"
    }
}

if ($modified) {
    $newPath = ($pathParts -join ';').TrimStart(';')
    try {
        Set-ItemProperty -Path $regPath -Name Path -Value $newPath -Type ExpandString -ErrorAction Stop
        # Notifica a Windows del cambio sin reiniciar
        [System.Environment]::SetEnvironmentVariable("Path", $newPath, [System.EnvironmentVariableTarget]::Machine)
        Write-Host "[OK] PATH del sistema actualizado."
    } catch {
        Write-Host "[WARN] No se pudo escribir el PATH: $_"
    }
} else {
    Write-Host "[OK] PATH ya estaba configurado correctamente."
}

exit 0
