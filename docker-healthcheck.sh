#!/usr/bin/env bash

SYSPROPS_FILE=${DATADIR}/system.properties
SYSPROPS_PORT=`grep "^unifi.https.port=" ${SYSPROPS_FILE} | cut -d'=' -f2`
PORT=${SYSPROPS_PORT:-8443}

curl -k -L --fail https://localhost:${PORT}
