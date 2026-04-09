# === CONFIG ===
$GGSCI = "C:\ogg\ggsci.exe"
$ZABBIX_SERVER = "172.20.1.1"
$ZABBIX_HOST = "DWH.ORACLE.GG"
$ZABBIX_KEY = "ogg.discovery"
$ZABBIX_SENDER = "C:\zabbix\zabbix_sender.exe"

$DEBUG = $true   # on / off

# === RUN GGSCI ===
$output = cmd /c "echo info all | `"$GGSCI`""

if ($DEBUG) {
    Write-Host "==== RAW GGSCI OUTPUT ===="
    $output
}

$data = @()

foreach ($line in $output) {

    if ($DEBUG) {
        Write-Host "Processing line: $line"
    }

    if ($line -match "^MANAGER\s+(\w+)") {

        if ($DEBUG) {
            Write-Host "Detected MANAGER"
        }

        $data += @{ "{#DEST_NAME}" = "MANAGER" }
    }

    elseif ($line -match "^(EXTRACT|REPLICAT)\s+\w+\s+(\S+)") {

        $type = $matches[1]
        $name = $matches[2]

        if ($DEBUG) {
            Write-Host "Detected $type.$name"
        }

        $data += @{ "{#DEST_NAME}" = "$type.$name" }
    }
}

$json = @{ data = $data } | ConvertTo-Json -Compress

if ($DEBUG) {
    Write-Host "==== GENERATED JSON ===="
    Write-Host $json
}

# === SEND ===
$result = & $ZABBIX_SENDER -z $ZABBIX_SERVER -s $ZABBIX_HOST -k $ZABBIX_KEY -o $json

if ($DEBUG) {
    Write-Host "==== ZABBIX SENDER RESULT ===="
    Write-Host $result
}
