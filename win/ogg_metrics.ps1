# === CONFIG ===
$GGSCI = "C:\ogg\ggsci.exe"
$ZABBIX_SERVER = "172.20.1.1"
$ZABBIX_HOST = "DWH.ORACLE.GG"
$ZABBIX_KEY = "ogg.metrics"
$ZABBIX_SENDER = "C:\zabbix\zabbix_sender.exe"

$DEBUG = $true   # on / off

# === FUNCTIONS ===

function Time-ToSec($t) {

    if ([string]::IsNullOrEmpty($t) -or $t -eq "N/A" -or $t -eq "-") {
        if ($DEBUG) { Write-Host "Time '$t' -> 0" }
        return 0
    }

    $parts = $t -split ":"
    if ($parts.Count -ne 3) {
        if ($DEBUG) { Write-Host "Invalid time format '$t' -> 0" }
        return 0
    }

    $sec = ([int]$parts[0] * 3600 + [int]$parts[1] * 60 + [int]$parts[2])

    if ($DEBUG) { Write-Host "Time '$t' -> $sec sec" }

    return $sec
}

function Status-ToNum($s) {

    $val = switch ($s) {
        "STOPPED"  { 0 }
        "STARTING" { 1 }
        "ABENDED"  { 2 }
        "RUNNING"  { 3 }
        default    { -1 }
    }

    if ($DEBUG) { Write-Host "Status '$s' -> $val" }

    return $val
}

# === RUN GGSCI ===
$output = cmd /c "echo info all | `"$GGSCI`""

if ($DEBUG) {
    Write-Host "==== RAW GGSCI OUTPUT ===="
    $output
}

$result = @()

foreach ($line in $output) {

    if ($DEBUG) {
        Write-Host "`nProcessing line: $line"
    }

    # MANAGER
    if ($line -match "^MANAGER\s+(\w+)") {

        $status = $matches[1]

        if ($DEBUG) {
            Write-Host "Detected MANAGER with status $status"
        }

        $result += @{
            DEST_NAME = "MANAGER"
            STATUS    = (Status-ToNum $status)
        }
    }

    # EXTRACT / REPLICAT
    elseif ($line -match "^(EXTRACT|REPLICAT)\s+(\w+)\s+(\S+)\s+(\S+)\s+(\S+)") {

        $type   = $matches[1]
        $status = $matches[2]
        $name   = $matches[3]
        $lag    = $matches[4]
        $tsc    = $matches[5]

        if ($DEBUG) {
            Write-Host "Detected $type.$name"
            Write-Host "  Status: $status"
            Write-Host "  Lag: $lag"
            Write-Host "  TSC: $tsc"
        }

        $result += @{
            DEST_NAME = "$type.$name"
            STATUS    = (Status-ToNum $status)
            LAG       = (Time-ToSec $lag)
            TSC       = (Time-ToSec $tsc)
        }
    }
}

$json = $result | ConvertTo-Json -Compress

if ($DEBUG) {
    Write-Host "`n==== GENERATED JSON ===="
    Write-Host $json
}

# === SEND ===
$sendResult = & $ZABBIX_SENDER -z $ZABBIX_SERVER -s $ZABBIX_HOST -k $ZABBIX_KEY -o $json

if ($DEBUG) {
    Write-Host "`n==== ZABBIX SENDER RESULT ===="
    Write-Host $sendResult
}
