#!/usr/bin/env bash

DIRS="${RUNDIR} ${LOGDIR} ${DATADIR} ${BASEDIR}"

echo "Setting ownership of '${DIRS}' to ${UNIFI_UID}:${UNIFI_GID}"

# Using a loop here so I can check more directories easily later
for dir in ${DIRS}; do
  if [ "$(stat -c '%u' "${dir}")" != "${UNIFI_UID}" ]; then
    chown -R "${UNIFI_UID}:${UNIFI_GID}" "${dir}"
  fi
done
