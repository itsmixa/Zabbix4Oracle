#!/bin/bash

# === CONFIG ===
GGSCI="/u01/app/oracle/product/gg19c/ggsci"
ZABBIX_SERVER="172.20.1.1"
ZABBIX_HOST="DWH.ORACLE.GG"
ZABBIX_KEY="ogg.discovery"

# === ENV ===
export ORACLE_HOME=/u01/app/oracle/product/19.0.0/dbhome_1
export LD_LIBRARY_PATH=/usr/lib:/u01/app/oracle/product/19.0.0/dbhome_1/lib

# === GET DATA ===
OUTPUT=$(echo "info all" | $GGSCI 2>/dev/null)

# === BUILD JSON ===
JSON=$(echo "$OUTPUT" | awk '
BEGIN {
    printf "{\"data\":[";
    first=1;
}

/^MANAGER/ {
    if (!first) printf(",");
    printf "{\"{#DEST_NAME}\":\"MANAGER\"}";
    first=0;
}

/^(EXTRACT|REPLICAT)/ {
    name=$1 "." $3;
    if (!first) printf(",");
    printf "{\"{#DEST_NAME}\":\"%s\"}", name;
    first=0;
}

END {
    printf "]}";
}
')

# === DEBUG ===
#echo "$JSON"

# === SEND ===
zabbix_sender \
  -z "$ZABBIX_SERVER" \
  -s "$ZABBIX_HOST" \
  -k "$ZABBIX_KEY" \
  -o "$JSON"
