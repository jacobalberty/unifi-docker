# Unifi-in-Docker (unifi-docker)

This repo contains a Dockerized version of [Ubiqiti Network's](https://www.ubnt.com/) Unifi Controller.

No more hassling with Controller, Java, or OS updates:
a Docker container simplifies the installation procedure
and eliminates problems with dependencies and versions.

This container has been tested on Ubuntu, Debian, macOS,
and even Raspberry Pi hardware.
For information about running on Windows, see [Unifi-in-Docker on Windows](#unifi-in-docker-on-windows) below.

## Current Information

The current version is Unifi Controller 7.1.66.
There are currently no hot-fix or CVE warnings affecting Unifi Controller.

## Setting up, Running, Stopping, Upgrading Unifi-in-Docker

First, install Docker on the machine that will run the Docker
and Unifi Controller software (the "Docker host")
using any of the guides on the internet.
Then use the following steps to set up the directories
and start the Docker container running.

### Setting up directories

One-time setup: create the "unifi" directory on the Docker host.
Within the "unifi" directory, create two sub-directories: "data" and "log".

```bash
cd # by default, use the home directory
mkdir -p unifi/data
mkdir -p unifi/log
```

_Note:_ By default, this README assumes you will use the home directory
on Linux, Unix, macOS.
If you create the directory elsewhere, read the
[Options section](#options-on-the-command-line)
below to adjust.)

### Running Unifi-in-Docker

Each time you want to start Unifi, use this command.
Each of the options is [described below.](#options-on-the-command-line)

```bash
docker run -d --init \
   --restart=unless-stopped \
   -p 8080:8080 -p 8443:8443 -p 3478:3478/udp \
   -e TZ='Africa/Johannesburg' \
   -v ~/unifi:/unifi \
   --user unifi \
   --name unifi \
   jacobalberty/unifi
```

In a minute or two, (after Unifi Controller starts up) you can go to
[https://docker-host-address:8443](https://docker-host-address:8443)
to complete configuration from the web (initial install) or resume using Unifi Controller.

**Important:** Two points to be aware of when you're setting up your Unifi Controller:

* When you initially connect to the link above, you will
see a warning about an untrusted certificate.
If you are _sure_ that you have used the address of the host
running Unifi-in-Docker, agree to the connection.
* See the note below about **Override "Inform Host" IP** so your
Unifi devices can "find" the Unifi Controller.
 
### Stopping Unifi-in-Docker

To change options, stop the Docker container then re-run the `docker run...` command
above with the new options.
_Note:_ The `docker rm unifi` command simply removes the "name" from the previous Docker image.
No time-consuming rebuild is required.

```bash
docker stop unifi
docker rm unifi
```
### Upgrading Unifi Controller

All the configuration and other files created by Unifi Controller
are stored on the Docker host's local disk (`~/unifi` by default.)
No information is retained within the container.
An upgrade to a new version of Unifi Controller simply retrieves a new Docker container,
which then re-uses the configuration from the local disk.
The upgrade process is:

1. **MAKE A BACKUP** on another computer, not the Docker host _(Always, every time...)_
2. Stop the current container (see above)
3. Enter `docker run...` with the newer container tag (see [Supported Tags](#supported-tags) below.)

## Options on the Command Line

The options for the `docker run...` command are:

- `-d` - Detached mode: Unifi-in-Docker runs in the background
- `--init` - Recommended to ensure processes get reaped when they die
- `--restart=unless-stopped` - If the container should stop for some reason,
restart it unless you issue a `docker stop ...`
- `-p ...` - Set the ports to pass through to the container.
`-p 8080:8080 -p 8443:8443 -p 3478:3478/udp`
is the minimal set for a working Unifi Controller. 
- `-e TZ=...` Set an environment variable named `TZ` with the desired time zone.
Find your time zone in this 
[list of timezones.](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones)
- `-e ...` See the [Environment Variables](#environment-variables)
section for more environment variables.
- `-v ...` - Bind the volume `~/unifi` on the Docker host
to the directory `/unifi`inside the container.
**These instructions assume you placed the "unifi" directory in your home directory.**
If you created the directory elsewhere, modify the `~/unifi` part of this option to match.
See the [Volumes](#volumes) discussion for other volumes used by Unifi Controller.
- `--user unifi` - Run as a non-root user. See the [Run as non-root User](#run-as-non-root-user) discussion below
- `jacobalberty/unifi` - the name of the container to use.
The `jacobalberty...` image is retrieved from [Dockerhub.](https://hub.docker.com/r/jacobalberty/unifi)
See the discussion about [Supported Tags](#supported-docker-hub-tags-and-respective-dockerfile-links) below.
- **Windows Users:** For information about running on Windows, see [Unifi-in-Docker on Windows](#unifi-in-docker-on-windows) below.

## Supported Tags

You can choose the version of Unifi Controller in the `docker run ...` command.
In Docker terminology, these versions are specified by "tags".

For example, in this project the container named `jacobalberty/unifi`
(with no "tag")
provides the most recent stable release.
See the table below for the current version.

The `rc` tag (for example, `jacobalberty/unifi:rc`)
uses the most recent release candidate from the UniFi APT repository.

You may also specify a version number (e.g., `jacobalberty/unifi:stable6`)
to get a specific version number, as shown in the table below.

_Note:_ In Docker, specifying an image with no tag 
(e.g., `jacobalberty/unifi`) gets the "latest" tag.
For Unifi-in-Docker, this uses the most recent stable version.

| Tag | Description | Changelog |
|-----|-------------|-----------|
| [`latest`, `7.1.66`](https://github.com/jacobalberty/unifi-docker/blob/master/Dockerfile) | Current Stable: Version 7.1.66 as of 2022-05-18 |[Change Log 7.1.66](https://community.ui.com/releases/UniFi-Network-Application-7-1-66/cf1208d2-3898-418c-b841-699e7b773fd4)|
| [`rc`](https://github.com/jacobalberty/unifi-docker/blob/rc/Dockerfile) | Release Candidate: 7.1.67-rc as of yyyy-mm-dd | [Change Log 7.1.67-rc](https://community.ui.com/releases/UniFi-Network-Application-7-1-67/f85ec723-ae52-405b-8905-077afcc97bb5) |
| [`stable6`](https://github.com/jacobalberty/unifi-docker/blob/stable-6/Dockerfile) | Final stable version 6 (6.5.55) | [Change Log 6.5.55](https://community.ui.com/releases/UniFi-Network-Application-6-5-55/48c64137-4a4a-41f7-b7e4-3bee505ae16e) |
| [`stable5`](https://github.com/jacobalberty/unifi-docker/blob/stable-5/Dockerfile) | Final stable version 5 (5.4.23) | [Change Log 5.14.23](https://community.ui.com/releases/UniFi-Network-Controller-5-14-23/daf90732-30ad-48ee-81e7-1dcb374eba2a) |

## Adopting Access Points/Switches/Security Gateway

#### Override "Inform Host" IP

For your Unifi devices to "find" the Unifi Controller running in Docker,
you _MUST_ override the Inform Host IP
with the address of the Docker host computer.
(By default, the Docker container usually gets the address 172.17.x.x.)
To do this:

* Find **Settings -> System -> Override Inform Host:** in the Unifi Controller web GUI.
* Check the "Enable" box, and enter the IP address of the Docker host machine. 
* Save settings in Unifi Controller
* Restart UniFi-in-Docker container with `docker stop ...` and `docker run ...` commands.

## Other Techniques for Adoption

The following are not strictly required for Unifi-in-Docker, but they collect information that may be helpful as you move to a new controller instance.

### Use Unifi export and migrate tool

Unifi can export and migrate the APs to a new controller [see this article for example.](https://lazyadmin.nl/home-network/migrate-unifi-controller/) 

#### SSH Adoption

SSH into the device:
```
set-inform http://<docker-host-ip>:8080/inform
```

#### Force Migration

Force an AP to migrate using [this Unifi community article.](https://community.ui.com/questions/Migrating-UNIFI-APs-to-new-controller/9ca9d8e9-780d-404d-84df-e7762cb810fd)

#### Older versions of Unifi Controller

Older Unifi Controllers use a different name for the "Override Inform Host option".
Look for **Settings -> Controller:**
Enter the IP address of the Docker host machine in "Controller Hostname/IP",
and check the "Override inform host with controller hostname/IP". 

#### Other Options

You can see more options on the [UniFi website](https://help.ubnt.com/hc/en-us/articles/204909754-UniFi-Layer-3-methods-for-UAP-adoption-and-management)

### Layer 2 Adoption

The layer 3 techniques above should be all you need to get new APs to adopt your controller running in Docker.
You can also configure the Docker instance so that its IP address matches its host address so that Layer 2 adoption works
using either of these settings.

#### Host Networking

If you launch the container using host networking \(With the `--net=host` parameter on `docker run`\) Layer 2 adoption works as if the controller is installed on the host.

#### Bridge Networking

It is possible to configure the `macvlan` driver to bridge your container to the host's networking adapter.
Specific instructions for this container are not yet available but you can read a write-up for docker at
[collabnix.com/docker-17-06-swarm-mode-now-with-macvlan-support](http://collabnix.com/docker-17-06-swarm-mode-now-with-macvlan-support/).

## Volumes

Unifi looks for the `/unifi` directory (within the container)
for its special purpose subdirectories:

* `/unifi/data` This contains your UniFi configuration data. (formerly: `/var/lib/unifi`) 

* `/unifi/log` This contains UniFi log files (formerly: `/var/log/unifi`)

* `/unifi/cert` Place custom SSL certs in this directory. 
For more information regarding the naming of the certificates,
see [Certificate Support](#certificate-support). (formerly: `/var/cert/unifi`)

* `/unifi/init.d`
You can place scripts you want to launch every time the container starts in here

* `/var/run/unifi` 
Run information, in general you will not need to touch this volume.
It is there to ensure UniFi has a place to write its PID files

### Legacy Volumes

These are no longer actually volumes, rather they exist for legacy compatibility.
You are urged to move to the new volumes ASAP.

* `/var/lib/unifi` New name: `/unifi/data`
* `/var/log/unifi` New name: `/unifi/log`

## Environment Variables:

You can pass in environment variables using the `-e` option when you invoke `docker run...`
See the `TZ` in the example above.
Other environment variables:

* `UNIFI_HTTP_PORT`
This is the HTTP port used by the Web interface. Browsers will be redirected to the `UNIFI_HTTPS_PORT`.
**Default:** `8080`

* `UNIFI_HTTPS_PORT`
This is the HTTPS port used by the Web interface.
**Default:** `8443`

* `PORTAL_HTTP_PORT`
Port used for HTTP portal redirection.
**Default:** `80`

* `PORTAL_HTTPS_PORT`
Port used for HTTPS portal redirection.
**Default:** `8843`

* `UNIFI_STDOUT`
Controller outputs logs to stdout in addition to server.log
**Default:** `unset`

* `TZ`
TimeZone. (i.e America/Chicago)

* `JVM_MAX_THREAD_STACK_SIZE`
Used to set max thread stack size for the JVM
Example:

   ```
   --env JVM_MAX_THREAD_STACK_SIZE=1280k
   ```

   as a fix for https://community.ubnt.com/t5/UniFi-Routing-Switching/IMPORTANT-Debian-Ubuntu-users-MUST-READ-Updated-06-21/m-p/1968251#M48264

* `LOTSOFDEVICES`
Enable this with `true` if you run a system with a lot of devices
and/or with a low powered system (like a Raspberry Pi).
This makes a few adjustments to try and improve performance: 

   * enable unifi.G1GC.enabled
   * set unifi.xms to JVM\_INIT\_HEAP\_SIZE
   * set unifi.xmx to JVM\_MAX\_HEAP\_SIZE
   * enable unifi.db.nojournal
   * set unifi.dg.extraargs to --quiet

   See [the Unifi support site](https://help.ui.com/hc/en-us/articles/115005159588-UniFi-How-to-Tune-the-Network-Application-for-High-Number-of-UniFi-Devices)
for an explanation of some of those options.
**Default:** `unset`

* `JVM_EXTRA_OPTS`
Used to start the JVM with additional arguments.
**Default:** `unset`

* `JVM_INIT_HEAP_SIZE`
Set the starting size of the javascript engine for example: `1024M`
**Default:** `unset`

* `JVM_MAX_HEAP_SIZE`
Java Virtual Machine (JVM) allocates available memory. 
For larger installations a larger value is recommended. For memory constrained system this value can be lowered. 
**Default:** `1024M`

### External MongoDB environment variables

These variables are used to implement support for an [external MongoDB server](https://community.ubnt.com/t5/UniFi-Wireless/External-MongoDB-Server/td-p/1305297) and must all be set in order for this feature to work. Once all are set then the configuration file value for `db.mongo.local` will automatically be set to `false`.

* `DB_URI`
Maps to `db.mongo.uri`.

* `STATDB_URI`
Maps to `statdb.mongo.uri`.

* `DB_NAME`
Maps to `unifi.db.name`.

## Exposed Ports

This container exposes the following ports. A minimal Unifi Controller requires the first three.

* 8080/tcp - Device command/control
* 8443/tcp - Web interface + API
* 3478/udp - STUN service
* 8843/tcp - HTTPS portal
* 8880/tcp - HTTP portal
* 6789/tcp - Speed Test (unifi5 only)

See [UniFi - Ports Used](https://help.ubnt.com/hc/en-us/articles/218506997-UniFi-Ports-Used) for more information.

## Run as non-root User

It is suggested you start running the Unifi Controller as a non-root user.
The default container runs it as root but if you set the docker run flag `--user` to `unifi`,
then the image will run as a special unfi user with the uid/gid 999/999.
You should ideally set your data and logs to owned by the proper gid.

Note: If you run as `unifi`, you will not be able to bind to lower ports by default.
This should not be needed if you are using the default ports.
If you need this, also pass the `docker run ...` flag `--sysctl` with `net.ipv4.ip_unprivileged_port_start=0`
to bind to whatever port you wish.

## Unifi-in-Docker on Windows
Unifi uses the Mongo database to store its data.
Mongo uses the fsync() system call on its data files.
Because of how Docker for Windows works, you can't bind mount `/unifi/db/data` on a Docker for Windows container.

The article [MongoDB on Windows in Minutes with Docker](https://blog.jeremylikness.com/blog/2018-12-27_mongodb-on-windows-in-minutes-with-docker/) also provides guidance for setting up a Docker Volume to work with Mongo database.

Alternatively, use the `docker-compose` command as described
in the next section since it uses a pre-built
Mongo container that addresses the problem.

### Running with separate Mongo container

The `docker-compose.yml` file in this repository
provides single command that orchestrates all the actions required
to bring up Mongo and Unifi Controller in separate containers,
using named volumes for important directories.

Simply clone this repo or copy the `docker-compose.yml` file
to your host computer's local disk and run:

```bash
cd <directory with docker-compose.yml>
docker-compose up -d 
```

**Setting Options:**

* The `docker-compose.yml` file contains the options
passed to Unifi Controller when it starts.
Edit that file to modify the options.
* _Optional:_ Add additional `-e <any-environment-variables-you-want>` to the `docker-compose up` line

To change options to Unifi Controller::

```bash
cd <directory with docker-compose.yml>
docker-compose down # this stops Unifi Controller and MongoDB
... edit the options in the docker-compose.yml file ...
docker-compose up ... # to resume operation
```

The options in the `docker-compose.yml` file are described in the 
[Options on the command line](#options-on-the-command-line) section.

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
and pass in the environment variable `-e PKGURL=https://dl.ubnt.com/unifi/5.6.30/unifi_sysvinit_all.deb` to your usual command line.

Simply replace the url to the debian package with the version you prefer.

### Running the Beta Using `docker-compose.yml` 

In the containers service definition of the `docker-compose.yml` file, replace `image: jacobalberty/unifi` with the following:

```shell
        image: jacobalberty/unifi:beta
         environment:
          PKGURL: https://dl.ubnt.com/unifi/5.6.40/unifi_sysvinit_all.deb
```

Replace the PKGURL: link with a link to the package you want.

_[Earlier versions talked about "Version 2". Is it still relevant to mention it?]_

## Init scripts

_[Is this section still true? Relevant?]_

You may now place init scripts to be launched during the unifi startup in /usr/local/unifi/init.d to perform any actions unique to your unifi setup. An example bash script to set up certificates is in `/usr/unifi/init.d/import_cert`.

## Certificate Support

To use custom SSL certs, you must map a volume with the certs to `/unifi/cert`

They should be named:

```shell
cert.pem  # The Certificate
privkey.pem # Private key for the cert
chain.pem # full cert chain
```

If your certificate or private key have different names, you can set the environment variables `CERTNAME` and `CERT_PRIVATE_NAME` to the name of your certificate/private key, e.g. `CERTNAME=my-cert.pem` and `CERT_PRIVATE_NAME=my-privkey.pem`.

For letsencrypt certs, we'll autodetect that and add the needed Identrust X3 CA Cert automatically. In case your letsencrypt cert is already the chained certificate, you can set the `CERT_IS_CHAIN` environment variable to `true`, e.g. `CERT_IS_CHAIN=true`. This option also works together with a custom `CERTNAME`.

### multiarch

_[Is this section still true? Relevant? Do the currently-listed Tags make this section obsolete?]_

All available containers now support multiarch with `amd64`, `armhf`, and `arm64` builds included.
`armhf` for now uses mongodb 3.4, I do not see much of a path forward for `armhf` due
to the lack of mongodb support for 32 bit arm, but I will
support it as long as feasibly possible, for now that date seems to be expiration of support for ubuntu 18.04.

## Multi-process container
_[Is this section still true? Relevant? Does the `docker-compose`section supercede this?]_

While micro-service patterns try to avoid running multiple processes in a container, the unifi5 container tries to follow the same process execution model intended by the original debian package and its init script, while trying to avoid needing to run a full init system.

`dumb-init` has now been removed. Instead it is now suggested you include --init in your docker run command line. If you are using docker-compose you can accomplish the same by making sure you use version 2.2 of the yml format and add `init: true` to your service definition.

`unifi.sh` executes and waits on the jsvc process which orchestrates running the controller as a service. The wrapper script also traps SIGTERM to issue the appropriate stop command to the unifi java `com.ubnt.ace.Launcher` process in the hopes that it helps keep the shutdown graceful.

## TODO

This list is empty for now, please [add your suggestions](https://github.com/jacobalberty/unifi-docker/issues).
