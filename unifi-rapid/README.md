#docker UniFi

## Supported tags and respective `Dockerfile` links

[`beta` (unifi-beta/Dockerfile)](/unifi-beta/Dockerfile)
[`rapid`, `latest` (unifi-rapid/Dockerfile)](/unifi-rapid/Dockerfile)
[`stable` (unifi/Dockerfile)](/unifi/Dockerfile)

## Description 
This is a containerized version of the Unifi Access Point controller.
I have included tags for beta stable and rapid. Latest points to the rapid version.

Beta and Rapid both use debian:jessie as their base where stable still uses debian:wheezy.

Use `docker run --net=host -d jacobalberty/unifi:rapid` for the quickest setup

## Volumes:

### `/var/lib/unifi`
Configuration data

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
