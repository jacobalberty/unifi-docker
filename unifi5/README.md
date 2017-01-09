# unifi-docker

## Description

This is a containerized version of [Ubiqiti Network](https://www.ubnt.com/)'s Unifi Controller.

Included tags for unifi5, unifi4, stable, unifi3 and oldstable. Latest currently points to the unifi5 version.

Use `docker run --net=host -d jacobalberty/unifi:latest` for the quickest setup

## Supported tags and respective `Dockerfile` links

[`unifi3`, `oldstable` (_unifi3/Dockerfile_)](https://github.com/jacobalberty/unifi-docker/blob/master/unifi3/Dockerfile)

[`unifi4`, `stable` (_unifi4/Dockerfile_)](https://github.com/jacobalberty/unifi-docker/blob/master/unifi4/Dockerfile)

[`unifi5`, `latest` (_unifi5/Dockerfile_)](https://github.com/jacobalberty/unifi-docker/blob/master/unifi5/Dockerfile)

## Volumes:

### `/var/lib/unifi`

Configuration data

### `/var/log/unifi`

Log Files

### `/var/run/unifi`

Run Information

## Environment Variables:

### `TZ`

TimeZone. (i.e America/Chicago)

## Expose:

### 8080/tcp

### 8081/tcp

### 8443/tcp

### 8843/tcp

### 8880/tcp

### 3478/udp

### 6789/tcp
