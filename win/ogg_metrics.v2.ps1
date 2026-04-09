# === CONFIG ===
$GGSCI = "C:\ogg\ggsci.exe"
$ZABBIX_SERVER = "172.20.1.1"
$ZABBIX_HOST = "DWH.ORACLE.GG"
$ZABBIX_KEY = "ogg.discovery"
$ZABBIX_SENDER = "C:\zabbix\zabbix_sender.exe"

$DEBUG = $true

# === RUN GGSCI ===
$output = cmd /c "echo info all | `"$GGSCI`""

if ($DEBUG) {
    Write-Host "==== RAW GGSCI OUTPUT ===="
    $output
}

# === BUILD DATA ARRAY ===
$data = @()

foreach ($line in $output) {

    if ($line -match "^MANAGER\s+(\w+)") {

        $obj = New-Object PSObject
        $obj | Add-Member -MemberType NoteProperty -Name "{#DEST_NAME}" -Value "MANAGER"

        $data += $obj
    }

    elseif ($line -match "^(EXTRACT|REPLICAT)\s+\w+\s+(\S+)") {

        $type = $matches[1]
        $name = $matches[2]

        $obj = New-Object PSObject
        $obj | Add-Member -MemberType NoteProperty -Name "{#DEST_NAME}" -Value "$type.$name"

        $data += $obj
    }
}

# === BUILD FINAL JSON ===
$final = New-Object PSObject
$final | Add-Member -MemberType NoteProperty -Name "data" -Value $data

$json = $final | ConvertTo-Json -Compress

if ($DEBUG) {
    Write-Host "==== GENERATED JSON ===="
    Write-Host $json
}

# === VALIDATION ===
try {
    $json | ConvertFrom-Json | Out-Null
    if ($DEBUG) { Write-Host "JSON VALID" }
}
catch {
    Write-Host "JSON INVALID"
    exit 1
}

# === SEND ===
$result = & $ZABBIX_SENDER -z $ZABBIX_SERVER -s $ZABBIX_HOST -k $ZABBIX_KEY -o "$json"

if ($DEBUG) {
    Write-Host "==== ZABBIX SENDER RESULT ===="
    Write-Host $result
}