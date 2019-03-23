FROM ubuntu:bionic

LABEL maintainer="Jacob Alberty <jacob.alberty@foundigital.com>"

ARG DEBIAN_FRONTEND=noninteractive

ENV PKGURL=https://dl.ubnt.com/unifi/5.10.20/unifi_sysvinit_all.deb

ENV BASEDIR=/usr/lib/unifi \
    DATADIR=/unifi/data \
    LOGDIR=/unifi/log \
    CERTDIR=/unifi/cert \
    RUNDIR=/var/run/unifi \
    ODATADIR=/var/lib/unifi \
    OLOGDIR=/var/log/unifi \
    CERTNAME=cert.pem \
    CERT_PRIVATE_NAME=privkey.pem \
    CERT_IS_CHAIN=false \
    BIND_PRIV=true \
    RUNAS_UID0=true \
    UNIFI_GID=999 \
    UNIFI_UID=999 \
    JVM_MAX_HEAP_SIZE=1024M

# Copy install and runtime scripts
RUN mkdir -p /usr/unifi \
    /usr/local/unifi/init.d \
    /usr/unifi/init.d
COPY docker-entrypoint.sh /usr/local/bin/
COPY docker-healthcheck.sh /usr/local/bin/
COPY docker-build.sh /usr/local/bin/
COPY functions /usr/unifi/functions
COPY import_cert /usr/unifi/init.d/

# Install Gosu
RUN set -ex \
    && apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates gnupg wget gosu \
# Install Unifi
    && chmod +x /usr/local/bin/docker-entrypoint.sh \
    && chmod +x /usr/unifi/init.d/import_cert \
    && chmod +x /usr/local/bin/docker-healthcheck.sh \
    && chmod +x /usr/local/bin/docker-build.sh \
    && apt-get install -y --no-install-recommends openjdk-8-jre-headless \
    && mkdir -p /usr/share/man/man1/ \
    && groupadd -r unifi -g $UNIFI_GID \
    && useradd --no-log-init -r -u $UNIFI_UID -g $UNIFI_GID unifi \
    && /usr/local/bin/docker-build.sh "${PKGURL}" \
    && apt-get purge -y --auto-remove wget \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

VOLUME ["/unifi", "${RUNDIR}"]

EXPOSE 6789/tcp 8080/tcp 8443/tcp 8880/tcp 8843/tcp 3478/udp

WORKDIR /unifi

HEALTHCHECK CMD /usr/local/bin/docker-healthcheck.sh || exit 1

# execute controller using JSVC like original Debian package does
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

CMD ["unifi"]
