#!/usr/bin/env bash

. /usr/unifi/functions

if [ -x /usr/local/bin/docker-build.sh ]; then
    /usr/local/bin/docker-build.sh "${PKGURL}"
fi

exit_handler() {
    log "Exit signal received, shutting down"
    java -jar ${BASEDIR}/lib/ace.jar stop
    for i in `seq 1 10` ; do
        [ -z "$(pgrep -f ${BASEDIR}/lib/ace.jar)" ] && break
        # graceful shutdown
        [ $i -gt 1 ] && [ -d ${BASEDIR}/run ] && touch ${BASEDIR}/run/server.stop || true
        # savage shutdown
        [ $i -gt 7 ] && pkill -f ${BASEDIR}/lib/ace.jar || true
        sleep 1
    done
    # shutdown mongod
    if [ -f ${MONGOLOCK} ]; then
        mongo localhost:${MONGOPORT} --eval "db.getSiblingDB('admin').shutdownServer()" >/dev/null 2>&1
    fi
    exit ${?};
}

trap 'kill ${!}; exit_handler' SIGHUP SIGINT SIGQUIT SIGTERM

[ "x${JAVA_HOME}" != "x" ] || set_java_home


# vars similar to those found in unifi.init
MONGOPORT=27117

CODEPATH=${BASEDIR}
DATALINK=${BASEDIR}/data
LOGLINK=${BASEDIR}/logs
RUNLINK=${BASEDIR}/run

DIRS="${RUNDIR} ${LOGDIR} ${DATADIR} ${BASEDIR}"

JVM_MAX_HEAP_SIZE=${JVM_MAX_HEAP_SIZE:-1024M}
#JVM_INIT_HEAP_SIZE=

#JAVA_ENTROPY_GATHER_DEVICE=
#UNIFI_JVM_EXTRA_OPTS=
#ENABLE_UNIFI=yes


MONGOLOCK="${DATAPATH}/db/mongod.lock"
JVM_EXTRA_OPTS="${JVM_EXTRA_OPTS} -Dunifi.datadir=${DATADIR} -Dunifi.logdir=${LOGDIR} -Dunifi.rundir=${RUNDIR}"
PIDFILE=/var/run/unifi/unifi.pid

if [ ! -z "${JVM_MAX_HEAP_SIZE}" ]; then
  JVM_EXTRA_OPTS="${JVM_EXTRA_OPTS} -Xmx${JVM_MAX_HEAP_SIZE}"
fi

if [ ! -z "${JVM_INIT_HEAP_SIZE}" ]; then
  JVM_EXTRA_OPTS="${JVM_EXTRA_OPTS} -Xms${JVM_INIT_HEAP_SIZE}"
fi

if [ ! -z "${JVM_MAX_THREAD_STACK_SIZE}" ]; then
  JVM_EXTRA_OPTS="${JVM_EXTRA_OPTS} -Xss${JVM_MAX_THREAD_STACK_SIZE}"
fi


JVM_OPTS="${JVM_EXTRA_OPTS}
  -Djava.awt.headless=true
  -Dfile.encoding=UTF-8"

# Cleaning /var/run/unifi/* See issue #26, Docker takes care of exlusivity in the container anyway.
rm -f /var/run/unifi/unifi.pid

run-parts /usr/local/unifi/init.d
run-parts /usr/unifi/init.d

if [ -d "/unifi/init.d" ]; then
    run-parts "/unifi/init.d"
fi

# Used to generate simple key/value pairs, for example system.properties
confSet () {
  file=$1
  key=$2
  value=$3
  if [ "$newfile" != true ] && grep -q "^${key} *=" "$file"; then
    ekey=$(echo "$key" | sed -e 's/[]\/$*.^|[]/\\&/g')
    evalue=$(echo "$value" | sed -e 's/[\/&]/\\&/g')
    sed -i "s/^\(${ekey}\s*=\s*\).*$/\1${evalue}/" "$file"
  else
    echo "${key}=${value}" >> "$file"
  fi
}

confFile="${DATADIR}/system.properties"
if [ -e "$confFile" ]; then
  newfile=false
else
  newfile=true
fi

declare -A settings

h2mb() {
  awkcmd='
    /[0-9]$/{print $1/1024/1024;next};
    /[mM]$/{printf "%u\n", $1;next};
    /[kK]$/{printf "%u\n", $1/1024;next}
    /[gG]$/{printf "%u\n", $1*1024;next}
  '
  echo $1 | awk "${awkcmd}"
}

if ! [[ -z "$LOTSOFDEVICES" ]]; then
  settings["unifi.G1GC.enabled"]="true"
  settings["unifi.xms"]="$(h2mb $JVM_INIT_HEAP_SIZE)"
  settings["unifi.xmx"]="$(h2mb ${JVM_MAX_HEAP_SIZE:-1024M})"
  # Reduce MongoDB I/O (issue #300)
  settings["unifi.db.nojournal"]="true"
  settings["unifi.db.extraargs"]="--quiet"
fi

# Implements issue #30
if ! [[ -z "$DB_URI" || -z "$STATDB_URI" || -z "$DB_NAME" ]]; then
  settings["db.mongo.local"]="false"
  settings["db.mongo.uri"]="$DB_URI"
  settings["statdb.mongo.uri"]="$STATDB_URI"
  settings["unifi.db.name"]="$DB_NAME"
fi

if ! [[ -z "$UNIFI_HTTP_PORT"  ]]; then
  settings["unifi.http.port"]="$UNIFI_HTTP_PORT"
fi

if ! [[ -z "$UNIFI_HTTPS_PORT"  ]]; then
  settings["unifi.https.port"]="$UNIFI_HTTPS_PORT"
fi

if [[ "$UNIFI_ECC_CERT" == "true" ]]; then
  settings["unifi.https.sslEnabledProtocols"]="TLSv1.2"
  settings["unifi.https.ciphers"]="TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384,TLS_ECDHE_ECDSA_WITH_AES_256_CBC_SHA384,TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA256"
fi

for key in "${!settings[@]}"; do
  confSet "$confFile" "$key" "${settings[$key]}"
done
UNIFI_CMD="java ${JVM_OPTS} -jar ${BASEDIR}/lib/ace.jar start"

# controller writes to relative path logs/server.log
cd ${BASEDIR}

CUID=$(id -u)

if [[ "${@}" == "unifi" ]]; then
    # keep attached to shell so we can wait on it
    log 'Starting unifi controller service.'
    for dir in "${DATADIR}" "${LOGDIR}"; do
        if [ ! -d "${dir}" ]; then
            if [ "${UNSAFE_IO}" == "true" ]; then
                rm -rf "${dir}"
            fi
            mkdir -p "${dir}"
        fi
    done
    if [ "${RUNAS_UID0}" == "true" ] || [ "${CUID}" != "0" ]; then
        if [ "${CUID}" == 0 ]; then
            log 'WARNING: Running UniFi in insecure (root) mode'
        fi
        ${UNIFI_CMD} &
    elif [ "${RUNAS_UID0}" == "false" ]; then
        if [ "${BIND_PRIV}" == "true" ]; then
            if setcap 'cap_net_bind_service=+ep' "${JAVA_HOME}/jre/bin/java"; then
                sleep 1
            else
                log "ERROR: setcap failed, can not continue"
                log "ERROR: You may either launch with -e BIND_PRIV=false and only use ports >1024"
                log "ERROR: or run this container as root with -e RUNAS_UID0=true"
                exit 1
            fi
        fi
        if [ "$(id unifi -u)" != "${UNIFI_UID}" ] || [ "$(id unifi -g)" != "${UNIFI_GID}" ]; then
            log "INFO: Changing 'unifi' UID to '${UNIFI_UID}' and GID to '${UNIFI_GID}'"
            usermod -o -u ${UNIFI_UID} unifi && groupmod -o -g ${UNIFI_GID} unifi
        fi
        # Using a loop here so I can check more directories easily later
        for dir in ${DIRS}; do
            if [ "$(stat -c '%u' "${dir}")" != "${UNIFI_UID}" ]; then
                chown -R "${UNIFI_UID}:${UNIFI_GID}" "${dir}"
            fi
        done
        gosu unifi:unifi ${UNIFI_CMD} &
    fi
    wait
    log "WARN: unifi service process ended without being signaled? Check for errors in ${LOGDIR}." >&2
else
    log "Executing: ${@}"
    exec ${@}
fi
exit 1
