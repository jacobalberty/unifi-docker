FROM golang:1.24-bullseye AS permset
WORKDIR /src
RUN git clone https://github.com/jacobalberty/permset.git /src && \
    mkdir -p /out && \
    go build -ldflags "-X main.chownDir=/unifi" -o /out/permset

FROM ubuntu:20.04

LABEL maintainer="Jacob Alberty <jacob.alberty@foundigital.com>"

ARG DEBIAN_FRONTEND=noninteractive

ARG PKGURL=https://dl.ui.com/unifi/10.0.162/unifi_sysvinit_all.deb

ENV BASEDIR=/usr/lib/unifi \
    DATADIR=/unifi/data \
    LOGDIR=/unifi/log \
    CERTDIR=/unifi/cert \
    RUNDIR=/unifi/run \
    ORUNDIR=/var/run/unifi \
    ODATADIR=/var/lib/unifi \
    OLOGDIR=/var/log/unifi \
    CERTNAME=cert.pem \
    CERT_PRIVATE_NAME=privkey.pem \
    CERT_IS_CHAIN=false \
    GOSU_VERSION=1.10 \
    BIND_PRIV=true \
    RUNAS_UID0=true \
    UNIFI_GID=999 \
    UNIFI_UID=999

# Install gosu
# https://github.com/tianon/gosu/blob/master/INSTALL.md
# This should be integrated with the main run because it duplicates a lot of the steps there
# but for now while shoehorning gosu in it is seperate
RUN set -eux; \
	apt-get update; \
	apt-get install -y gosu; \
	rm -rf /var/lib/apt/lists/*

RUN mkdir -p /usr/unifi \
     /usr/local/unifi/init.d \
     /usr/unifi/init.d \
     /usr/local/docker
COPY docker-entrypoint.sh /usr/local/bin/
COPY docker-healthcheck.sh /usr/local/bin/
COPY docker-build.sh /usr/local/bin/
COPY functions /usr/unifi/functions
COPY import_cert /usr/unifi/init.d/
COPY pre_build /usr/local/docker/pre_build
RUN chmod +x /usr/local/bin/docker-entrypoint.sh \
 && chmod +x /usr/unifi/init.d/import_cert \
 && chmod +x /usr/local/bin/docker-healthcheck.sh \
 && chmod +x /usr/local/bin/docker-build.sh \
 && chmod -R +x /usr/local/docker/pre_build

# Push installing openjdk-8-jre first, so that the unifi package doesn't pull in openjdk-7-jre as a dependency? Else uncomment and just go with openjdk-7.
RUN set -ex \
 && mkdir -p /usr/share/man/man1/ \
 && groupadd -r unifi -g $UNIFI_GID \
 && useradd --no-log-init -r -u $UNIFI_UID -g $UNIFI_GID unifi \
 && /usr/local/bin/docker-build.sh "${PKGURL}"

COPY --from=permset /out/permset /usr/local/bin/permset
RUN chown 0.0 /usr/local/bin/permset && \
    chmod +s /usr/local/bin/permset

RUN mkdir -p /unifi && chown unifi:unifi -R /unifi

# Apply any hotfixes that were included
COPY hotfixes /usr/local/unifi/hotfixes

RUN chmod +x /usr/local/unifi/hotfixes/* && run-parts /usr/local/unifi/hotfixes

VOLUME ["/unifi", "${RUNDIR}"]

EXPOSE 6789/tcp 8080/tcp 8443/tcp 8880/tcp 8843/tcp 3478/udp 10001/udp

WORKDIR /unifi

HEALTHCHECK --start-period=5m CMD /usr/local/bin/docker-healthcheck.sh || exit 1

# execute controller using JSVC like original debian package does
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

CMD ["unifi"]

# execute the conroller directly without using the service
#ENTRYPOINT ["/usr/bin/java", "-Xmx${JVM_MAX_HEAP_SIZE}", "-jar", "/usr/lib/unifi/lib/ace.jar"]
  # See issue #12 on github: probably want to consider how JSVC handled creating multiple processes, issuing the -stop instraction, etc. Not sure if the above ace.jar class gracefully handles TERM signals.
#CMD ["start"]
