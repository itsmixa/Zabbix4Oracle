# === CONFIG ===
$GGSCI = "C:\ogg\ggsci.exe"
$ZABBIX_SERVER = "172.20.1.1"
$ZABBIX_HOST = "DWH.ORACLE.GG"
$ZABBIX_KEY = "ogg.discovery"
$ZABBIX_SENDER = "C:\zabbix\zabbix_sender.exe"

$DEBUG = $true   # on / off

# === RUN GGSCI ===
$output = cmd /c "echo info all | `"$GGSCI`""

# === BUILD DATA ===
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

# === JSON ===
$final = [PSCustomObject]@{
    data = $data
}

$json = $final | ConvertTo-Json -Compress

if ($DEBUG) {
    Write-Host $json
}

# === TEMP FILE ===
$tmpFile = Join-Path $env:TEMP "ogg_lld.txt"

# ÂÀÆÍÎ: ASCII áåç BOM
"$ZABBIX_HOST $ZABBIX_KEY $json" | Out-File -FilePath $tmpFile -Encoding ascii

if ($DEBUG) {
    Write-Host "==== FILE CONTENT ===="
    Get-Content $tmpFile
}

# === SEND ===
& $ZABBIX_SENDER -z $ZABBIX_SERVER -i $tmpFile

# === CLEANUP ===
Remove-Item $tmpFile -ErrorAction SilentlyContinue

