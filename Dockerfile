FROM debian:jessie-slim
  # WORKING: work around openjdk issue which expects the man-page directory, failing to configure package if it doesn't
# FROM debian:stretch-slim
  # needs minor fixes to get working but results in much larger image
MAINTAINER Jacob Alberty <jacob.alberty@foundigital.com>

ARG DEBIAN_FRONTEND=noninteractive

ENV PKGURL=https://dl.ubnt.com/unifi/5.5.20/unifi_sysvinit_all.deb

# Need backports for openjdk-8
RUN echo "deb http://deb.debian.org/debian/ jessie-backports main" > /etc/apt/sources.list.d/10backports.list \
 && echo "deb http://www.ubnt.com/downloads/unifi/debian unifi5 ubiquiti" > /etc/apt/sources.list.d/20ubiquiti.list \
 && apt-key adv --keyserver keyserver.ubuntu.com --recv C0A52C50

# Push installing openjdk-8-jre first, so that the unifi package doesn't pull in openjdk-7-jre as a dependency? Else uncomment and just go with openjdk-7.
RUN mkdir -p /usr/share/man/man1/ \
 && mkdir -p /var/cache/apt/archives/ \
 && apt-get update &&  apt-get install -qy --no-install-recommends \
    curl \
    gdebi-core \
 && apt-get install -t jessie-backports -qy --no-install-recommends \
    ca-certificates-java \
    openjdk-8-jre-headless \
 && curl -o ./unifi.deb ${PKGURL} \
 && yes | gdebi ./unifi.deb \
 && rm -f ./unifi.deb \
 && apt-get purge -qy --auto-remove \
    curl \
    gdebi-core \
 && rm -rf /var/lib/apt/lists/*

ENV BASEDIR=/usr/lib/unifi \
  DATADIR=/var/lib/unifi \
  RUNDIR=/var/run/unifi \
  LOGDIR=/var/log/unifi \
  JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64 \
  JVM_MAX_HEAP_SIZE=1024M \
  JVM_INIT_HEAP_SIZE=

RUN ln -s ${DATADIR} ${BASEDIR}/data \
 && ln -s ${RUNDIR} ${BASEDIR}/run \
 && ln -s ${LOGDIR} ${BASEDIR}/logs
# Can't use env var, RUN doesn't support them?

VOLUME ["${DATADIR}", "${RUNDIR}", "${LOGDIR}"]

EXPOSE 6789/tcp 8080/tcp 8443/tcp 8880/tcp 8843/tcp 3478/udp

COPY unifi.sh /usr/local/bin/
COPY import_cert.sh /usr/local/bin
RUN chmod +x /usr/local/bin/unifi.sh
RUN chmod +x /usr/local/bin/import_cert.sh

WORKDIR /var/lib/unifi

# execute controller using JSVC like original debian package does
CMD ["/usr/local/bin/unifi.sh"]

# execute the conroller directly without using the service
#ENTRYPOINT ["/usr/bin/java", "-Xmx${JVM_MAX_HEAP_SIZE}", "-jar", "/usr/lib/unifi/lib/ace.jar"]
  # See issue #12 on github: probably want to consider how JSVC handled creating multiple processes, issuing the -stop instraction, etc. Not sure if the above ace.jar class gracefully handles TERM signals.
#CMD ["start"]
