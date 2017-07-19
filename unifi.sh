#!/usr/bin/env bash

# vars similar to those found in unifi.init
JSVC=$(command -v jsvc)
PIDFILE=/var/run/unifi/unifi.pid
JVM_OPTS="
  -Dunifi.datadir=${DATADIR}
  -Dunifi.rundir=${RUNDIR}
  -Dunifi.logdir=${LOGDIR}
  -Djava.awt.headless=true
  -Dfile.encoding=UTF-8"

if [ ! -z "${JVM_MAX_HEAP_SIZE}" ]; then
  JVM_OPTS="${JVM_OPTS} -Xmx${JVM_MAX_HEAP_SIZE}"
fi

if [ ! -z "${JVM_INIT_HEAP_SIZE}" ]; then
  JVM_OPTS="${JVM_OPTS} -Xms${JVM_INIT_HEAP_SIZE}"
fi

if [ ! -z "${JVM_MAX_THREAD_STACK_SIZE}" ]; then
  JVM_OPTS="${JVM_OPTS} -Xss${JVM_MAX_THREAD_STACK_SIZE}"
fi

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

# trap SIGTERM (or SIGINT or SIGHUP) and send `-stop`
trap "echo 'Stopping unifi controller service (TERM signal caught).'; ${JSVC} -nodetach -pidfile ${PIDFILE} -stop ${MAINCLASS} stop; exit 0" 1 2 15

# Cleaning /var/run/unifi/* See issue #26, Docker takes care of exlusivity in the container anyway.
rm -f /var/run/unifi/unifi.pid

if [ -d "/var/cert/unifi" ]; then
  echo 'Cert directory found. Checking Certs'
  import_cert.sh
fi

# keep attached to shell so we can wait on it
echo 'Starting unifi controller service.'
${JSVC} -nodetach ${JSVC_OPTS} ${MAINCLASS} start &

wait

echo "WARN: unifi service process ended without being singaled? Check for errors in ${LOGDIR}." >&2
exit 1
