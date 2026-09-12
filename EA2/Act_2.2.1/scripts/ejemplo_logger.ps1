# Ejemplo didáctico (equivalente Windows de ejemplo_logger.sh): crea un pseudo-respaldo
# y registra el resultado en el Visor de eventos de Windows (Event Log), en vez de
# un archivo de texto — para practicar la revisión de logs "del sistema" también en Windows.
#
# Ejecutar como Administrador la PRIMERA vez (New-EventLog requiere permisos elevados).
# Usa rutas y nombres de ejemplo: adapta todo antes de reutilizarlo en un caso real.

$SourceDir = "C:\Temp\act221-ejemplo\origen"
$BackupDir = "C:\Temp\act221-ejemplo\destino"
$LogSource = "RespaldoEjemplo"

New-Item -ItemType Directory -Force -Path $SourceDir | Out-Null
New-Item -ItemType Directory -Force -Path $BackupDir | Out-Null

# Registra el origen de eventos una sola vez (queda instalado en el sistema).
if (-not [System.Diagnostics.EventLog]::SourceExists($LogSource)) {
    New-EventLog -LogName Application -Source $LogSource
}

$BackupName = "respaldo_$(Get-Date -Format 'yyyyMMdd_HHmmss').zip"
$BackupPath = Join-Path $BackupDir $BackupName

Write-EventLog -LogName Application -Source $LogSource -EntryType Information -EventId 1000 -Message "Inicio de respaldo: $BackupName"

try {
    Compress-Archive -Path $SourceDir -DestinationPath $BackupPath -ErrorAction Stop
    Write-EventLog -LogName Application -Source $LogSource -EntryType Information -EventId 1001 -Message "Respaldo OK: $BackupName"
} catch {
    Write-EventLog -LogName Application -Source $LogSource -EntryType Error -EventId 1002 -Message "ERROR al generar respaldo: $_"
}
