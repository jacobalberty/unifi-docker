#!/usr/bin/env bash

set_java_home() {
    JAVA_HOME=$(readlink -f /usr/bin/java | sed "s:/jre/bin/java::")
    if [ ! -d "${JAVA_HOME}" ]; then
        # For some reason readlink failed so lets just make some assumptions instead
        # We're assuming openjdk 8 since thats what we install in Dockerfile
        arch=`dpkg --print-architecture 2>/dev/null`
        JAVA_HOME=/usr/lib/jvm/java-8-openjdk-${arch}
    fi
}
exit_handler() {
    echo "Exit signal received, shutting down"
    ${JSVC} -nodetach -pidfile ${PIDFILE} -stop ${MAINCLASS} stop
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
JSVC=$(command -v jsvc)
MONGOPORT=27117

CODEPATH=${BASEDIR}
DATALINK=${BASEDIR}/data
LOGLINK=${BASEDIR}/logs
RUNLINK=${BASEDIR}/run

JAVA_ENTROPY_GATHER_DEVICE=
JVM_MAX_HEAP_SIZE=1024M
JVM_INIT_HEAP_SIZE=
UNIFI_JVM_EXTRA_OPTS=

ENABLE_UNIFI=yes
JVM_EXTRA_OPTS=
JSVC_EXTRA_OPTS=

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


JSVC_OPTS="
  -home ${JAVA_HOME}
  -classpath /usr/share/java/commons-daemon.jar:${BASEDIR}/lib/ace.jar
  -pidfile ${PIDFILE}
  -procname unifi
  -outfile ${LOGDIR}/unifi.out.log
  -errfile ${LOGDIR}/unifi.err.log
  ${JVM_OPTS}"

# One issue might be no cron and lograte, causing the log volume to become bloated over time! Consider `-keepstdin` and `-errfile &2` options for JSVC.
MAINCLASS='com.ubnt.ace.Launcher'

# Cleaning /var/run/unifi/* See issue #26, Docker takes care of exlusivity in the container anyway.
rm -f /var/run/unifi/unifi.pid

if [ -d "/var/cert/unifi" ]; then
  echo 'Cert directory found. Checking Certs'
  import_cert.sh
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

confFile=/var/lib/unifi/system.properties
if [ -e "$confFile" ]; then
  newfile=false
else
  newfile=true
fi

declare -A settings

# Implements issue #30
if ! [[ -z "$DB_URI" || -z "$STATDB_URI" || -z "$DB_NAME" ]]; then
  settings["db.mongo.local"]="false"
  settings["db.mongo.uri"]="$DB_URI"
  settings["statdb.mongo.uri"]="$STATDB_URI"
  settings["unifi.db.name"]="$DB_NAME"
fi

for key in "${!settings[@]}"; do
  confSet "$confFile" "$key" "${settings[$key]}"
done

if [[ "${@}" == "unifi" ]]; then
    # keep attached to shell so we can wait on it
    echo 'Starting unifi controller service.'
    ${JSVC} -nodetach ${JSVC_OPTS} ${MAINCLASS} start &

    wait
    echo "WARN: unifi service process ended without being singaled? Check for errors in ${LOGDIR}." >&2
else
    echo "Executing: ${@}"
    exec ${@}
fi
exit 1
