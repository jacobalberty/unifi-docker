# unifi-docker

## `latest` tag

`latest` is now tracking unifi 6.5.x as of 2021-11-22.

## multiarch

All tags are now multiarch capable with `amd64`, `armhf`, and `arm64` builds included.
`armhf` for now uses mongodb 3.4, I do not see much of a path forward for `armhf` due to the lack of mongodb support for 32 bit arm, but I will
support it as long as feasibly possible, for now that date seems to be expiration of support for ubuntu 18.04.

## Run as non-root User

It is suggested you start running this as a non root user. The default right now is to run as root but if you set the docker run flag `--user` to `unifi` then the image will run as a special unfi user with the uid/gid 999/999. You should ideally set your data and logs to owned by the proper gid.
You will not be able to bind to lower ports by default. If you also pass the docker run flag `--sysctl` with `net.ipv4.ip_unprivileged_port_start=0` then you will be able to freely bind to whatever port you wish. This should not be needed if you are using the default ports.

## Mongo and Docker for windows
 Unifi uses mongo store its data. Mongo uses the fsync() system call on its data files. Because of how docker for windows works you can't bind mount `/unifi/db/data` on a docker for windows container. Therefore `-v ~/unifi:/unifi` won't work.
 [Discussion on the issue](https://github.com/docker/for-win/issues/138).

## Supported Docker Hub Tags and Respective `Dockerfile` Links

| Tag | Description |
|-----|-------------|
| [`latest`, `v6`, `v6.5`](https://github.com/jacobalberty/unifi-docker/blob/master/Dockerfile) | Tracks UniFi stable version - 6.5.53 as of 2021-11-22 [Change Log 6-5-53](https://community.ui.com/releases/UniFi-Network-Application-6-5-53/16025ec1-4bbc-46a9-8f4f-8561fd59cd4c)|
| [`latest-5`, `stable-5`, `5.0`](https://github.com/jacobalberty/unifi-docker/blob/master-5/Dockerfile) | Tracks UniFi 5.14 stable version - 5.14.23 as of 2020-09-14 |

### Latest Release Candidate tags

| Version | Latest Tag |
|---------|------------|
| 6.5.x   | [`6.5.52-rc`](https://github.com/jacobalberty/unifi-docker/blob/6.5.52-rc/Dockerfile) |

These tags generally track the UniFi APT repository. We do lead the repository a little when it comes to pushing the latest version. The latest version gets pushed when it moves from `release candidate` to `stable` instead of waiting for it to hit the repository.

In adition to these tags you may tag specific versions as well, for example `jacobalberty/unifi:v6.2.26` will get you unifi 6.2.26 no matter what the current version is.
For release candidates it is advised to use the specific versions as the `rc` tag may jump from 5.6.x to 5.8.x then back to 5.6.x as new release candidates come out.

## Description

This is a containerized version of [Ubiqiti Network](https://www.ubnt.com/)'s Unifi Controller.

The following options may be of use:

- Set the timezone with `TZ`
- Bind mount the `data` and `log` volumes

It is suggested that you include --init to handle process reaping
Example to test with

```bash
mkdir -p unifi/data
mkdir -p unifi/log
docker run --rm --init -p 8080:8080 -p 8443:8443 -p 3478:3478/udp -e TZ='Africa/Johannesburg' -v ~/unifi:/unifi --name unifi jacobalberty/unifi:v6
```

**Note** you must omit `-v ~/unifi:/unifi` on windows, but you can use a local volume e.g. `-v unifi:/unifi` (omit the leading ~/) to persist the data on a local volume.

## Running with separate mongo container

A compose file has been included that will bring up mongo and the controller,
using named volumes for important directories.

Simply clone this repo or copy the `docker-compose.yml` file and run
```bash
docker-compose up -d
```

## Adopting Access Points/Switches/Security Gateway

### Layer 3 Adoption

The default example requires some l3 adoption method. You have a couple options to adopt.

#### Force adoption IP

Run UniFi Docker and open UniFi in browser. Go under Settings -> Controller and then enter the IP address of the Docker host machine in "Controller Hostname/IP", and check the "Override inform host with controller hostname/IP". Save settings and restart UniFi Docker container. 

#### SSH Adoption

The quickest one off method is to ssh into the access point and run the following commands:

```shell
mca-cli
set-inform http://<host_ip>:8080/inform
```

#### Other Options

You can see more options on the [UniFi website](https://help.ubnt.com/hc/en-us/articles/204909754-UniFi-Layer-3-methods-for-UAP-adoption-and-management)


### Layer 2 Adoption

You can also enable layer 2 adoption through one of two methods.

#### Host Networking

If you launch the container using host networking \(With the `--net=host` parameter on `docker run`\) Layer 2 adoption works as if the controller is installed on the host.

#### Bridge Networking

It is possible to configure the `macvlan` driver to bridge your container to the host's networking adapter. Specific instructions for this container are not yet available but you can read a write-up for docker at [collabnix.com/docker-17-06-swarm-mode-now-with-macvlan-support](http://collabnix.com/docker-17-06-swarm-mode-now-with-macvlan-support/).

## Beta Users

The `beta` image has been updated to support package installation at run time. With this change you can now install the beta releases on more systems, such as Synology. This should open up access to the beta program for more users of this docker image.


If you would like to submit a new feature for the images the beta branch is probably a good one to apply it against as well. I will be cleaing up the Dockerfile under beta and gradually pushing out the improvements to the other branches. So any major changes should apply cleanly against the `beta` branch.

### Installing Beta Builds On The Command Line

Using the Beta build is pretty easy, just use the `jacobalberty/unifi:beta` image and add `-e PKGURL=https://dl.ubnt.com/unifi/5.6.30/unifi_sysvinit_all.deb` to your usual command line.

Simply replace the url to the debian package with the version you prefer.


### Building Beta Using `docker-compose.yml` Version 2

This is just as easy when using version 2 of the docker-compose.yml file format.

Under your containers service definition instead of using `image: jacobalberty/unifi` use the following:

```shell
        image: jacobalberty/unifi:beta
         environment:
          PKGURL: https://dl.ubnt.com/unifi/5.6.40/unifi_sysvinit_all.deb
```

Once again, simply change PKGURL to point to the package you would like to use.

## Volumes:

### `/unifi`

This is a single monolithic volume that contains several subdirectories, you can do a single volume for everything or break up your old volumes into the subdirectories

#### `/unifi/data`

Old: `/var/lib/unifi`

This contains your UniFi configuration data.

#### `/unifi/log`

old: `/var/log/unifi`

This contains UniFi log files

#### `/unifi/cert`

old: `/var/cert/unifi`

To use custom SSL certs, you must map a volume with the certs to /unifi/cert

For more information regarding the naming of the certificates, see [Certificate Support](#certificate-support).

#### `/unifi/init.d`

This is an entirely new volume. You can place scripts you want to launch every time the container starts in here

### `/var/run/unifi`

Run information, in general you will not need to touch this volume. It is there to ensure UniFi has a place to write its PID files


### Legacy Volumes

These are no longer actually volumes, rather they exist for legacy compatibility. You are urged to move to the new volumes ASAP.

#### `/var/lib/unifi`

New name: `/unifi/data`

#### `/var/log/unifi`

New name: `/unifi/log`

## Environment Variables:

### `UNIFI_HTTP_PORT`

Default: `8080`

This is the HTTP port used by the Web interface. Browsers will be redirected to the `UNIFI_HTTPS_PORT`.

### `UNIFI_HTTPS_PORT`

Default: `8443`

This is the HTTPS port used by the Web interface.

### `PORTAL_HTTP_PORT`

Default: `80`

Port used for HTTP portal redirection.

### `PORTAL_HTTPS_PORT`

Default: `8443`

Port used for HTTPS portal redirection.

### `UNIFI_STDOUT`

Default: `unset`

Controller outputs logs to stdout in addition to server.log

### `TZ`

TimeZone. (i.e America/Chicago)

### `JVM_MAX_THREAD_STACK_SIZE`

used to set max thread stack size for the JVM

Ex:

```
--env JVM_MAX_THREAD_STACK_SIZE=1280k
```

as a fix for https://community.ubnt.com/t5/UniFi-Routing-Switching/IMPORTANT-Debian-Ubuntu-users-MUST-READ-Updated-06-21/m-p/1968251#M48264

### `JVM_EXTRA_OPTS`

Default: `unset`

Used to start the JVM with additional arguments.

### `JVM_INIT_HEAP_SIZE`

Default: `unset`

### `JVM_MAX_HEAP_SIZE`
Java Virtual Machine (JVM) allocates available memory. 
For larger installations a larger value is recommended. For memory constrained system this value can be lowered. 
Default `1024M`

### External MongoDB environment variables

These variables are used to implement support for an [external MongoDB server](https://community.ubnt.com/t5/UniFi-Wireless/External-MongoDB-Server/td-p/1305297) and must all be set in order for this feature to work. Once all are set then the configuration file value for `db.mongo.local` will automatically be set to `false`.

### `DB_URI`

Maps to `db.mongo.uri`.

### `STATDB_URI`

Maps to `statdb.mongo.uri`.

### `DB_NAME`

Maps to `unifi.db.name`.


## Expose:

### 8080/tcp - Device command/control

### 8443/tcp - Web interface + API

### 8843/tcp - HTTPS portal

### 8880/tcp - HTTP portal

### 3478/udp - STUN service

### 6789/tcp - Speed Test (unifi5 only)

See [UniFi - Ports Used](https://help.ubnt.com/hc/en-us/articles/218506997-UniFi-Ports-Used)

## Multi-process container

While micro-service patterns try to avoid running multiple processes in a container, the unifi5 container tries to follow the same process execution model intended by the original debian package and it's init script, while trying to avoid needing to run a full init system.

`dumb-init` has now been removed. Instead it is now suggested you include --init in your docker run command line. If you are using docker-compose you can accomplish the same by making sure you use version 2.2 of the yml format and add `init: true` to your service definition.

`unifi.sh` executes and waits on the jsvc process which orchestrates running the controller as a service. The wrapper script also traps SIGTERM to issue the appropriate stop command to the unifi java `com.ubnt.ace.Launcher` process in the hopes that it helps keep the shutdown graceful.


## Init scripts

You may now place init scripts to be launched during the unifi startup in /usr/local/unifi/init.d to perform any actions unique to your unifi setup. An example bash script to set up certificates is in `/usr/unifi/init.d/import_cert`.

## Certificate Support

To use custom SSL certs, you must map a volume with the certs to /unifi/cert

They should be named:

```shell
cert.pem  # The Certificate
privkey.pem # Private key for the cert
chain.pem # full cert chain
```

If your certificate or private key have different names, you can set the environment variables `CERTNAME` and `CERT_PRIVATE_NAME` to the name of your certificate/private key, e.g. `CERTNAME=my-cert.pem` and `CERT_PRIVATE_NAME=my-privkey.pem`.

For letsencrypt certs, we'll autodetect that and add the needed Identrust X3 CA Cert automatically. In case your letsencrypt cert is already the chained certificate, you can set the `CERT_IS_CHAIN` environment variable to `true`, e.g. `CERT_IS_CHAIN=true`. This option also works together with a custom `CERTNAME`.

## TODO

This list is empty for now, please [add your suggestions](https://github.com/jacobalberty/unifi-docker/issues).
