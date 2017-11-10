FROM debian:stretch-slim
  # WORKING: work around openjdk issue which expects the man-page directory, failing to configure package if it doesn't
# FROM debian:stretch-slim
  # needs minor fixes to get working but results in much larger image
MAINTAINER Jacob Alberty <jacob.alberty@foundigital.com>

ARG DEBIAN_FRONTEND=noninteractive

ENV PKGURL=https://dl.ubnt.com/unifi/5.6.22/unifi_sysvinit_all.deb

ENV BASEDIR=/usr/lib/unifi \
    DATADIR=/unifi/data \
    LOGDIR=/unifi/log \
    CERTDIR=/unifi/cert \
    RUNDIR=/var/run/unifi \
    ODATADIR=/var/lib/unifi \
    OLOGDIR=/var/log/unifi \
    GOSU_VERSION=1.10 \
    BIND_PRIV=true \
    RUNAS_UID0=true \
    UNIFI_GID=999 \
    UNIFI_UID=999

# Install gosu
# https://github.com/tianon/gosu/blob/master/INSTALL.md
# This should be integrated with the main run because it duplicates a lot of the steps there
# but for now while shoehorning gosu in it is seperate
RUN set -ex \
    && fetchDeps=' \
        ca-certificates \
        dirmngr \
        gpg \
        wget \
    ' \
    && apt-get update \
    && apt-get install -y --no-install-recommends $fetchDeps \
    && dpkgArch="$(dpkg --print-architecture | awk -F- '{ print $NF }')" \
    && wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch" \
    && wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch.asc" \
# verify the signature
    && export GNUPGHOME="$(mktemp -d)" \
    && for server in $(shuf -e ha.pool.sks-keyservers.net \
                            hkp://p80.pool.sks-keyservers.net:80 \
                            keyserver.ubuntu.com \
                            hkp://keyserver.ubuntu.com:80 \
                            pgp.mit.edu) ; do \
        gpg --keyserver "$server" --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 && break || : ; \
    done \
    && gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu \
    && rm -rf "$GNUPGHOME" /usr/local/bin/gosu.asc \
    && chmod +x /usr/local/bin/gosu \
# verify that the binary works
    && gosu nobody true \
    && apt-get purge -y --auto-remove $fetchDeps \
    && rm -rf /var/lib/apt/lists/*


# Push installing openjdk-8-jre first, so that the unifi package doesn't pull in openjdk-7-jre as a dependency? Else uncomment and just go with openjdk-7.
RUN mkdir -p /usr/share/man/man1/ \
 && groupadd -r unifi -g $UNIFI_GID \
 && useradd --no-log-init -r -u $UNIFI_UID -g $UNIFI_GID unifi \
 && apt-get update \
 && apt-get install -qy --no-install-recommends \
    curl \
    dirmngr \
    gnupg \
    openjdk-8-jre-headless \
    procps \
    libcap2-bin \
 && echo "deb http://www.ubnt.com/downloads/unifi/debian unifi5 ubiquiti" > /etc/apt/sources.list.d/20ubiquiti.list \
 && apt-key adv --keyserver keyserver.ubuntu.com --recv C0A52C50 \
 && curl -L -o ./unifi.deb "${PKGURL}" \
 && apt -qy install ./unifi.deb \
 && apt-get -qy purge --auto-remove \
    dirmngr \
    gnupg \
 && rm -f ./unifi.deb \
 && chown -R unifi:unifi /usr/lib/unifi \
 && rm -rf /var/lib/apt/lists/*

RUN rm -rf ${ODATADIR} ${OLOGDIR} \
 && mkdir -p ${DATADIR} ${LOGDIR} \
 && ln -s ${DATADIR} ${BASEDIR}/data \
 && ln -s ${RUNDIR} ${BASEDIR}/run \
 && ln -s ${LOGDIR} ${BASEDIR}/logs \
 && rm -rf {$ODATADIR} ${OLOGDIR} \
 && ln -s ${DATADIR} ${ODATADIR} \
 && ln -s ${LOGDIR} ${OLOGDIR} \
 && mkdir -p /var/cert ${CERTDIR} \
 && ln -s ${CERTDIR} /var/cert/unifi

VOLUME ["/unifi", "${RUNDIR}"]

EXPOSE 6789/tcp 8080/tcp 8443/tcp 8880/tcp 8843/tcp 3478/udp

RUN mkdir -p /usr/unifi \
     /usr/local/unifi/init.d \
     /usr/unifi/init.d
COPY docker-entrypoint.sh /usr/local/bin/
COPY docker-healthcheck.sh /usr/local/bin/
COPY functions /usr/unifi/functions
COPY import_cert /usr/unifi/init.d/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh \
 && chmod +x /usr/unifi/init.d/import_cert \
 && chmod +x /usr/local/bin/docker-healthcheck.sh

WORKDIR /unifi

HEALTHCHECK CMD /usr/local/bin/docker-healthcheck.sh || exit 1

# execute controller using JSVC like original debian package does
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

CMD ["unifi"]

# execute the conroller directly without using the service
#ENTRYPOINT ["/usr/bin/java", "-Xmx${JVM_MAX_HEAP_SIZE}", "-jar", "/usr/lib/unifi/lib/ace.jar"]
  # See issue #12 on github: probably want to consider how JSVC handled creating multiple processes, issuing the -stop instraction, etc. Not sure if the above ace.jar class gracefully handles TERM signals.
#CMD ["start"]
