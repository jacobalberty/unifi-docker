#docker UniFi

## Supported tags and respective `Dockerfile` links

[`unifi4`, `latest` (*unifi4/Dockerfile*)](https://github.com/jacobalberty/unifi-docker/blob/master/unifi4/Dockerfile)
[`stable`, `latest` (*unifi4/Dockerfile*)](https://github.com/jacobalberty/unifi-docker/blob/master/unifi4/Dockerfile)

[`unifi3`, (*unifi3/Dockerfile*)](https://github.com/jacobalberty/unifi-docker/blob/master/unifi3/Dockerfile)
[`oldstable`, (*unifi3/Dockerfile*)](https://github.com/jacobalberty/unifi-docker/blob/master/unifi3/Dockerfile)

## Description 
This is a containerized version of the Unifi Access Point controller.
I have included tags for unifi4, stable, unifi3 and oldstable. Latest points to the unifi4 version.

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
