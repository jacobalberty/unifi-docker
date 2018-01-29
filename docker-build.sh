#!/usr/bin/env bash

if [ "x${1}" == "x" ]; then
    echo please pass PKGURL as an environment variable
    exit 0
fi

apt-get update
apt-get install -qy --no-install-recommends \
    curl \
    openjdk-8-jre-headless \
    procps \
    libcap2-bin
echo "deb http://www.ubnt.com/downloads/unifi/debian unifi5 ubiquiti" > /etc/apt/sources.list.d/20ubiquiti.list
apt-key adv --keyserver keyserver.ubuntu.com --recv C0A52C50
curl -L -o ./unifi.deb "${1}"
apt -qy install ./unifi.deb
rm -f ./unifi.deb
chown -R unifi:unifi /usr/lib/unifi
rm -rf /var/lib/apt/lists/*

rm -rf ${ODATADIR} ${OLOGDIR}
mkdir -p ${DATADIR} ${LOGDIR}
ln -s ${DATADIR} ${BASEDIR}/data
ln -s ${RUNDIR} ${BASEDIR}/run
ln -s ${LOGDIR} ${BASEDIR}/logs
rm -rf {$ODATADIR} ${OLOGDIR}
ln -s ${DATADIR} ${ODATADIR}
ln -s ${LOGDIR} ${OLOGDIR}
mkdir -p /var/cert ${CERTDIR}
ln -s ${CERTDIR} /var/cert/unifi

rm -rf "${0}"
