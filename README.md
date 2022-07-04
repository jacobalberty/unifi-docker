# Unifi-in-Docker (unifi-docker)

This repo contains a Dockerized version of [Ubiqiti Network's](https://www.ubnt.com/) Unifi Controller.

No more hassling with Controller, Java, or OS updates:
a Docker container simplifies the installation procedure
and eliminates problems with dependencies and versions.

The current version is Unifi Controller 7.1.66.
This container has been tested on Ubuntu, Debian, and even Raspberry Pi hardware. 

## Setting up, Running, Stopping, Upgrading Unifi-in-Docker

First, install Docker on your machine (the "Docker host")
using any of the guides on the internet.
Then set up the directories and start the Docker container running.

### Setting up directories

```bash
cd 	# by default, use the home directory
mkdir -p unifi/data
mkdir -p unifi/log
```

### Running Unifi-in-Docker

Each time you want to start Unifi, use these commands:

```bash
cd <directory-to-hold-Unifi-files>
docker run -d --init \
   --restart=unless-stopped \
   -p 8080:8080 -p 8443:8443 -p 3478:3478/udp \
   -e TZ='Africa/Johannesburg' \
   -v ~/unifi:/unifi \
   --user unifi \
   jacobalberty/unifi:v7
```

In a minute or two, (after Unifi Controller starts up) you can go to
[https://your-server-address:8443](https://your-server-address:8443)
to complete configuration from the web (initial install) or resume using Unifi Controller.

**Important:** See the note below about Overriding the "Inform Host" IP during initial configuration.

### Stopping Unifi-in-Docker

To change options, stop the Docker container then re-run the `docker run...` command
above with the new options.
To do this, you need to get the name for the running container.
It's a two-word phrase, separated by "_", shown at the end of the `docker ps` command.

```bash
docker ps # to find the container name - it'll be two_words
docker stop two_words
```
### Upgrading Unifi Controller

All the files created/maintained by Unifi Controller actually live on the host's volume.
An upgrade to a new version of Unifi Controller simply retrieves a new Docker container,
reusing the configuration from the local disk. The process is:

1. **MAKE A BACKUP** on another computer, not the Docker host _(Always, every time...)_
2. Stop the current container (see above)
3. Enter `docker run...` with the new container name (see above)

## Options for Unifi-in-Docker

The options for the `docker run...` command are:

- `-d` - Detached mode: Unifi-in-Docker runs in the background
- `--init` - Recommended to ensure processes get reaped
- `--restart=unless-stopped` - If the container should stop for some reason,
restart it unless you issue a `docker stop ...`
- `-p 8443:8443` - Set the ports to pass through to the container.
The list above is the minimal set for a working Unifi Controller. 
- `-e TZ=...` Set an environment variable named `TZ` with the desired time zone
([list of timezones](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones))
- `-e ...` See the [Environment Variables](#environment-variables)
section for more environment variables.
- `-v ...` - Bind the volume `~/unifi` on the host to the directory `/unifi`inside the container.
See the [Volumes](#volumes) discussion for other volumes used by Unifi Controller.
- `--user unifi` - Run as a non-root user. See the [Run as non-root User](#run-as-non-root-user) discussion below
- `jacobalberty/unifi:7` - the name of the container to use.
The `jacobalberty...` image comes from [Dockerhub.](https://hub.docker.com/r/jacobalberty/unifi)
See the discussion about [Supported Tags](#supported-docker-hub-tags-and-respective-dockerfile-links) below.
- **Windows Users:** There is a problem with Mongo database and a bind-mount volume.
You can keep data locally but should use `-v unifi:/unifi` (no leading `~/`)
**_IS THIS TRUE?_** See [Mongo and Docker for Windows](#mongo-and-docker-for-windows) for more details.

## Supported Docker Hub Tags and Respective `Dockerfile` Links

### "latest" tag

`latest` now tracks unifi 7.1.x as of 2022-05-18.

| Tag | Description |
|-----|-------------|
| [`latest`, `v7`, `v7.1`](https://github.com/jacobalberty/unifi-docker/blob/master/Dockerfile) | Tracks UniFi stable version - 7.1.66 as of 2022-05-18 [Change Log 7.1.66](https://community.ui.com/releases/UniFi-Network-Application-7-1-66/cf1208d2-3898-418c-b841-699e7b773fd4)|

### Latest Release Candidate tags

| Version | Latest Tag |
|---------|------------|
| 7.1.x   | [`7.1.66`](https://github.com/jacobalberty/unifi-docker/blob/7.1.66/Dockerfile) |

These tags generally track the UniFi APT repository. We do lead the repository a little when it comes to pushing the latest version. The latest version gets pushed when it moves from `release candidate` to `stable` instead of waiting for it to hit the repository.

In adition to these tags you may tag specific versions as well,
for example `jacobalberty/unifi:v6.2.26` will get you unifi 6.2.26
no matter what the current version is.
For release candidates it is advised to use the specific versions as the `rc` tag
may jump from 5.6.x to 5.8.x then back to 5.6.x as new release candidates come out.

### multiarch

All tags are now multiarch capable with `amd64`, `armhf`, and `arm64` builds included.
`armhf` for now uses mongodb 3.4, I do not see much of a path forward for `armhf` due
to the lack of mongodb support for 32 bit arm, but I will
support it as long as feasibly possible, for now that date seems to be expiration of support for ubuntu 18.04.

## Run as non-root User

It is suggested you start running this as a non root user.
The default right now is to run as root but if you set the docker run flag `--user` to `unifi`,
then the image will run as a special unfi user with the uid/gid 999/999.
You should ideally set your data and logs to owned by the proper gid.
You will not be able to bind to lower ports by default.
If you also pass the docker run flag `--sysctl` with `net.ipv4.ip_unprivileged_port_start=0`
then you will be able to freely bind to whatever port you wish.
This should not be needed if you are using the default ports.

## Mongo and Docker for windows
 Unifi uses mongo store its data.
 Mongo uses the fsync() system call on its data files.
 Because of how Docker for Windows works, you can't bind mount `/unifi/db/data`
 on a Docker for Windows container.
 Therefore `-v ~/unifi:/unifi` won't work.
See the [discussion on the issue](https://github.com/docker/for-win/issues/138).

_Also:_ Does this provide any guidance for Window? https://blog.jeremylikness.com/blog/2018-12-27_mongodb-on-windows-in-minutes-with-docker/

## Running with separate mongo container

A compose file has been included that will bring up mongo and the controller,
using named volumes for important directories.

Simply clone this repo or copy the `docker-compose.yml` file and run
```bash
docker-compose up -d
```

## Adopting Access Points/Switches/Security Gateway

For your Unifi devices to "find" the Unifi Controller running in Docker, you _MUST_ override the Inform Host IP (described below).
You may need some of the other techniques below to adopt all the APs.

#### Override "Inform Host" IP

Configure Unifi Controller to use the address of the Docker host, instead of the internal Docker address (usually 172.17.x.x).
The way to do this depends on the version of your Unifi Controller:
* **Current (7.x):** Use **Settings -> System -> Override Inform Host** Check the "Enable" box, and enter the IP address of the Docker host machine.
* **Older:** Use **Settings -> Controller** Enter the IP address of the Docker host machine in "Controller Hostname/IP", and check the "Override inform host with controller hostname/IP". 

In either case, save settings and **restart UniFi-in-Docker container** with `docker stop ...` and `docker run ...`

## Other Techniques for Adoption

The following are not strictly required for your Unifi-in-Docker, but they collect information that may be helpful as you move to a new controller instance.

### Use Unifi export and migrate tool

Unifi can export and migrate the APs to a new controller [see, for example](https://lazyadmin.nl/home-network/migrate-unifi-controller/) 

#### SSH Adoption

SSH into the device:
```
set-inform http://<docker-host-ip>:8080/inform
```

#### Force Migration

Force an AP to migrate using https://community.ui.com/questions/Migrating-UNIFI-APs-to-new-controller/9ca9d8e9-780d-404d-84df-e7762cb810fd

#### Other Options

You can see more options on the [UniFi website](https://help.ubnt.com/hc/en-us/articles/204909754-UniFi-Layer-3-methods-for-UAP-adoption-and-management)

### Layer 2 Adoption

The Layer 3 techniques above should be all you need to get new APs to adopt your controller running in Docker.
You can also configure the Docker instance so that its IP address matches its host address so that Layer 2 adoption works
using either of these settings.

#### Host Networking

If you launch the container using host networking \(With the `--net=host` parameter on `docker run`\) Layer 2 adoption works as if the controller is installed on the host.

#### Bridge Networking

It is possible to configure the `macvlan` driver to bridge your container to the host's networking adapter.
Specific instructions for this container are not yet available but you can read a write-up for docker at
[collabnix.com/docker-17-06-swarm-mode-now-with-macvlan-support](http://collabnix.com/docker-17-06-swarm-mode-now-with-macvlan-support/).

## Beta Users

The `beta` image has been updated to support package installation at run time.
With this change you can now install the beta releases on more systems,
such as Synology.
This should open up access to the beta program for more users of this docker image.


If you would like to submit a new feature for the images,
the beta branch is probably a good one to apply it against as well.
I will be cleaing up the Dockerfile under beta and gradually pushing out
the improvements to the other branches.
So any major changes should apply cleanly against the `beta` branch.

### Installing Beta Builds On The Command Line

Using the Beta build is pretty easy, just use the `jacobalberty/unifi:beta` image
and add `-e PKGURL=https://dl.ubnt.com/unifi/5.6.30/unifi_sysvinit_all.deb` to your usual command line.

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

This is a single monolithic volume that contains several subdirectories,
you can do a single volume for everything or break up your old volumes into the subdirectories

#### `/unifi/data`

Old: `/var/lib/unifi`

This contains your UniFi configuration data.

#### `/unifi/log`

old: `/var/log/unifi`

This contains UniFi log files

#### `/unifi/cert`

old: `/var/cert/unifi`

To use custom SSL certs, you must map a volume with the certs to /unifi/cert

For more information regarding the naming of the certificates,
see [Certificate Support](#certificate-support).

#### `/unifi/init.d`

This is an entirely new volume.
You can place scripts you want to launch every time the container starts in here

### `/var/run/unifi`

Run information, in general you will not need to touch this volume.
It is there to ensure UniFi has a place to write its PID files


### Legacy Volumes

These are no longer actually volumes, rather they exist for legacy compatibility.
You are urged to move to the new volumes ASAP.

#### `/var/lib/unifi`

New name: `/unifi/data`

#### `/var/log/unifi`

New name: `/unifi/log`

## Environment Variables:

You can pass in environment variables using the `-e` option when you invoke `docker run...`
See the `TZ` in the example above.
Other environment variables:

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

Default: `8843`

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

### `LOTSOFDEVICES`
Enable this with `true` if you run a system with a lot of devices and/or
with a low powered system (like a Raspberry Pi)
This makes a few adjustments to try and improve performance: 

* enable unifi.G1GC.enabled
* set unifi.xms to JVM_INIT_HEAP_SIZE
* set unifi.xmx to JVM_MAX_HEAP_SIZE
* enable unifi.db.nojournal
* set unifi.dg.extraargs to --quiet

See [This website](https://help.ui.com/hc/en-us/articles/115005159588-UniFi-How-to-Tune-the-Network-Application-for-High-Number-of-UniFi-Devices) for an explanation 
of some of those options.

Default: `unset`

### `JVM_EXTRA_OPTS`
Used to start the JVM with additional arguments.

Default: `unset`

### `JVM_INIT_HEAP_SIZE`
Set the starting size of the javascript engine for example: `1024M`

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

This container exposes the following ports. A minimal Unifi Controller requires the first three.

* 8080/tcp - Device command/control

* 8443/tcp - Web interface + API

* 3478/udp - STUN service

* 8843/tcp - HTTPS portal

* 8880/tcp - HTTP portal

* 6789/tcp - Speed Test (unifi5 only)

See [UniFi - Ports Used](https://help.ubnt.com/hc/en-us/articles/218506997-UniFi-Ports-Used) for more information.

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
