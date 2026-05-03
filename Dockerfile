
FROM golang:1.24-bullseye AS permset

WORKDIR /src

RUN set -eux; \
    git clone --depth=1 https://github.com/jacobalberty/permset.git .; \
    mkdir -p /out; \
    go build -ldflags "-X main.chownDir=/unifi" -o /out/permset


# ---------- Runtime image ----------
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

# Install runtime dependencies
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        gosu \
        ca-certificates \
        runit-helper \
    ; \
    rm -rf /var/lib/apt/lists/*

# Create required directories
RUN set -eux; \
    mkdir -p \
        /usr/unifi \
        /usr/local/unifi/init.d \
        /usr/unifi/init.d \
        /usr/local/docker \
        /usr/share/man/man1 \
        /unifi

COPY docker-entrypoint.sh docker-healthcheck.sh docker-build.sh /usr/local/bin/
COPY functions /usr/unifi/functions
COPY import_cert /usr/unifi/init.d/
COPY pre_build /usr/local/docker/pre_build

RUN set -eux; \
    chmod +rx /usr/local/bin/docker-entrypoint.sh; \
    chmod +rx /usr/local/bin/docker-healthcheck.sh; \
    chmod +rx /usr/local/bin/docker-build.sh; \
    chmod +rx /usr/unifi/init.d/import_cert; \
    chmod +r /usr/unifi/functions; \
    chmod -R +rx /usr/local/docker/pre_build

# Create unifi user and install UniFi package
RUN set -eux; \
    groupadd -r unifi -g "${UNIFI_GID}"; \
    useradd --no-log-init -r -u "${UNIFI_UID}" -g "${UNIFI_GID}" unifi; \
    /usr/local/bin/docker-build.sh "${PKGURL}"

# Install permset helper
COPY --from=permset /out/permset /usr/local/bin/permset

RUN set -eux; \
    chown root:root /usr/local/bin/permset; \
    chmod 4755 /usr/local/bin/permset; \
    chown -R unifi:unifi /unifi

# Apply included hotfixes
COPY hotfixes /usr/local/unifi/hotfixes

RUN set -eux; \
    if [ -d /usr/local/unifi/hotfixes ]; then \
        chmod +x /usr/local/unifi/hotfixes/* || true; \
        run-parts /usr/local/unifi/hotfixes || true; \
    fi

VOLUME ["/unifi", "/unifi/run"]

EXPOSE 6789/tcp \
       8080/tcp \
       8443/tcp \
       8880/tcp \
       8843/tcp \
       3478/udp \
       10001/udp

WORKDIR /unifi

HEALTHCHECK --start-period=5m CMD /usr/local/bin/docker-healthcheck.sh || exit 1

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

CMD ["unifi"]
