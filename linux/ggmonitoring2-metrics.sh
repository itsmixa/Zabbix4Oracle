#!/bin/bash

# === CONFIG ===
GGSCI="/u01/app/oracle/product/gg19c/ggsci"
ZABBIX_SERVER="172.20.1.1"
ZABBIX_HOST="DWH.ORACLE.GG"
ZABBIX_KEY="ogg.metrics"

# === ENV ===
export ORACLE_HOME=/u01/app/oracle/product/19.0.0/dbhome_1
export LD_LIBRARY_PATH=/usr/lib:/u01/app/oracle/product/19.0.0/dbhome_1/lib

# === GET DATA ===
OUTPUT=$(echo "info all" | $GGSCI 2>/dev/null)

# === BUILD JSON ===
JSON=$(echo "$OUTPUT" | awk '
function time_to_sec(t,   a) {

    if (t == "" || t == "N/A" || t == "-") return 0;

    if (split(t, a, ":") != 3) return 0;

    return a[1]*3600 + a[2]*60 + a[3];
}

function status_to_num(s) {
    if (s == "STOPPED")  return 0;
    if (s == "STARTING") return 1;
    if (s == "ABENDED")  return 2;
    if (s == "RUNNING")  return 3;
    return -1; # unknown
}

BEGIN {
    printf "[";
    first=1;
}

/^MANAGER/ {

    status_raw=$2;
    status_num=status_to_num(status_raw);

    if (!first) printf(",");

    printf "{";
    printf "\"DEST_NAME\":\"MANAGER\",";
    # printf "\"type\":\"MANAGER\",";
    # printf "\"status_raw\":\"%s\",", status_raw;
    printf "\"STATUS\":%d", status_num;
    printf "}";

    first=0;
}

/^(EXTRACT|REPLICAT)/ {

    name=$1 "." $3;

    status_raw=$2;
    status_num=status_to_num(status_raw);

    lag_raw=$4;
    tsc_raw=$5;

    lag_sec=time_to_sec(lag_raw);
    tsc_sec=time_to_sec(tsc_raw);

    if (lag_raw == "") lag_raw="00:00:00";
    if (tsc_raw == "") tsc_raw="00:00:00";

    if (!first) printf(",");

    printf "{";
    printf "\"DEST_NAME\":\"%s\",", name;
    # printf "\"type\":\"%s\",", $1;

    # status
    # printf "\"status_raw\":\"%s\",", status_raw;
    printf "\"STATUS\":%d,", status_num;

    # time raw
    # printf "\"lag_raw\":\"%s\",", lag_raw;
    # printf "\"tsc_raw\":\"%s\",", tsc_raw;

    # time numeric
    printf "\"LAG\":%d,", lag_sec;
    printf "\"TSC\":%d", tsc_sec;

    printf "}";

    first=0;
}

END {
    printf "]";
}
')

# === DEBUG ===
# echo "$JSON"


# === SEND ===
zabbix_sender \
  -z "$ZABBIX_SERVER" \
  -s "$ZABBIX_HOST" \
  -k "$ZABBIX_KEY" \
  -o "$JSON"

