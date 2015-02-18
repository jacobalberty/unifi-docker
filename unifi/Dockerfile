FROM debian:wheezy
MAINTAINER Jacob Alberty <jacob.alberty@foundigital.com>

ENV DEBIAN_FRONTEND noninteractive

RUN echo "deb http://www.ubnt.com/downloads/unifi/distros/deb/debian debian ubiquiti" \
  > /etc/apt/sources.list.d/20ubiquiti.list
RUN echo "deb http://downloads-distro.mongodb.org/repo/debian-sysvinit dist 10gen" \
  > /etc/apt/sources.list.d/21mongodb.list

RUN apt-key adv --keyserver keyserver.ubuntu.com --recv C0A52C50
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv 7F0CEB10

RUN apt-get update && apt-get install -qy --force-yes unifi=2.4.6-1884 && apt-get clean

EXPOSE 8080/tcp 8081/tcp 8443/tcp 8843/tcp 8880/tcp 3478/udp

VOLUME ["/var/lib/unifi"]
WORKDIR ["/var/lib/unifi"]

CMD ["/usr/bin/java", "-Xmx1024M", "-jar", "/usr/lib/unifi/lib/ace.jar", "start"]
