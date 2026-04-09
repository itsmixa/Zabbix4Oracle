# === CONFIG ===
$GGSCI = "C:\ogg\ggsci.exe"
$ZABBIX_SERVER = "172.20.1.1"
$ZABBIX_HOST = "DWH.ORACLE.GG"
$ZABBIX_KEY = "ogg.discovery"
$ZABBIX_SENDER = "C:\zabbix\zabbix_sender.exe"

$DEBUG = $true

# === FUNCTIONS ===

function Time-ToSec($t) {
    if ([string]::IsNullOrEmpty($t) -or $t -eq "N/A" -or $t -eq "-") { return 0 }

    $p = $t -split ":"
    if ($p.Count -ne 3) { return 0 }

    return ([int]$p[0]*3600 + [int]$p[1]*60 + [int]$p[2])
}

function Status-ToNum($s) {
    switch ($s) {
        "STOPPED"  { 0 }
        "STARTING" { 1 }
        "ABENDED"  { 2 }
        "RUNNING"  { 3 }
        default    { -1 }
    }
}

# === RUN GGSCI ===
$output = cmd /c "echo info all | `"$GGSCI`""

$result = @()

foreach ($line in $output) {

    if ($line -match "^MANAGER\s+(\w+)") {

        $result += [PSCustomObject]@{
            name        = "MANAGER"
            type        = "MANAGER"
            status_num  = (Status-ToNum $matches[1])
        }
    }

    elseif ($line -match "^(EXTRACT|REPLICAT)\s+(\w+)\s+(\S+)\s+(\S+)\s+(\S+)") {

        $type   = $matches[1]
        $status = $matches[2]
        $name   = $matches[3]
        $lag    = $matches[4]
        $tsc    = $matches[5]

        $result += [PSCustomObject]@{
            name        = "$type.$name"
            type        = $type
            status_num  = (Status-ToNum $status)
            lag_sec     = (Time-ToSec $lag)
            tsc_sec     = (Time-ToSec $tsc)
        }
    }
}

$json = @{ data = $result } | ConvertTo-Json -Compress

if ($DEBUG) {
    Write-Host $json
}

# === TEMP FILE ===
$tmpFile = Join-Path $env:TEMP "ogg_metrics.txt"

"$ZABBIX_HOST $ZABBIX_KEY $json" | Out-File -FilePath $tmpFile -Encoding ascii

if ($DEBUG) {
    Write-Host "==== FILE CONTENT ===="
    Get-Content $tmpFile
}

# === SEND ===
& $ZABBIX_SENDER -z $ZABBIX_SERVER -i $tmpFile

# === CLEANUP ===
Remove-Item $tmpFile -ErrorAction SilentlyContinue
