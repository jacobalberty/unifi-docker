FROM debian:jessie
MAINTAINER Jacob Alberty <jacob.alberty@foundigital.com>

VOLUME ["/var/lib/unifi", "/var/log/unifi", "/var/run/unifi", "/usr/lib/unifi/work"]

ENV DEBIAN_FRONTEND noninteractive

RUN echo "deb http://www.ubnt.com/downloads/unifi/debian unifi5 ubiquiti" > \
  /etc/apt/sources.list.d/20ubiquiti.list && \
  echo "deb http://downloads-distro.mongodb.org/repo/debian-sysvinit dist 10gen" > \
  /etc/apt/sources.list.d/21mongodb.list && \
  apt-key adv --keyserver keyserver.ubuntu.com --recv C0A52C50 && \
  apt-key adv --keyserver keyserver.ubuntu.com --recv 7F0CEB10

RUN apt-get -q update && \
  apt-get install -qy --force-yes --no-install-recommends unifi && \
  apt-get -q clean && \
  rm -rf /var/lib/apt/lists/*

RUN ln -s /var/lib/unifi /usr/lib/unifi/data
EXPOSE 8080/tcp 8081/tcp 8443/tcp 8843/tcp 8880/tcp 3478/udp

## Uncommenting these allows unifi to run as user nobody but I don't know for sure that all features work so leaving commented out for now
#RUN chown -R nobody:nogroup /usr/lib/unifi && \
#    chown -R nobody:nogroup /var/lib/unifi && \
#    chown -R nobody:nogroup /var/log/unifi && \
#    chown -R nobody:nogroup /var/run/unifi
#USER nobody

WORKDIR /var/lib/unifi

ENTRYPOINT ["/usr/bin/java", "-Xmx1024M", "-jar", "/usr/lib/unifi/lib/ace.jar"]
CMD ["start"]
