# unifi-docker

## Run as non-root User

It is suggested you start running this as a non root user. The default right now is to run as root but if you set the environment variable RUNAS_UID0 to false then the image will run as a special unfi user with the uid/gid 999/999. You should ideally set your data and logs to owned by the proper gid. The [environment variables section](https://github.com/jacobalberty/unifi-docker/blob/master/README.md#environment-variables) has more details. At some point in the future this feature may default to on and I personally run all of my own containers with it on. So turning it on for your own containers will help prevent any surprises.

## Supported Docker Hub Tags and Respective `Dockerfile` Links

| Tag | Description |
|-----|-------------|
| [`latest`, `stable`, `5.7`](https://github.com/jacobalberty/unifi-docker/blob/master/Dockerfile) | Tracks UniFi stable version - 5.7.23 as of 2018-04-16 |
| [`lts`, `5.6`](https://github.com/jacobalberty/unifi-docker/blob/lts/Dockerfile) | Tracks UniFi LTS stable version - 5.6.37 as of 2018-04-16 |
| [`oldstable`, `5.5`](https://github.com/jacobalberty/unifi-docker/blob/oldstable/Dockerfile) | Tracks UniFi Old Stable version - 5.5.24 as of 2017-11-13 |
| [`sc`](https://github.com/jacobalberty/unifi-docker/blob/sc/Dockerfile) | Tracks UniFi "Stable Candidate", The latest stable candidate may flip between the two branches maintained by Ubuiqiti so it is advised you tag off of the version you want directly instead of the `sc` tag. |

### Latest Stable Candidate tags

| Version | Latest Tag |
|---------|------------|
| 5.6.x   | [`5.6.39-sc`](https://github.com/jacobalberty/unifi-docker/blob/5.6.39-sc/Dockerfile) |
| 5.7.x   | [`5.7.28-sc`](https://github.com/jacobalberty/unifi-docker/blob/5.7.28-sc/Dockerfile) |
| 5.8.x   | [`5.8.21-sc`](https://github.com/jacobalberty/unifi-docker/blob/5.8.21-sc/Dockerfile) |

These tags generally track the UniFi APT repository. We do lead the repository a little when it comes to pushing the latest version. The latest version gets pushed when it moves from `stable candidate` to `stable` instead of waiting for it to hit the repository.

In adition to these tags you may tag specific versions as well, for example `jacobalberty/unifi:5.4.19` will get you unifi 5.4.19 no matter what the current version is. Stable candidates now exist both under the `sc` tag and for tags with the extension `-sc` ie `jacobalberty/unifi:5.6.18-sc`. It is advised to use the specific versions as the `sc` tag may jump from 5.6.x to 5.5.x then back to 5.6.x as new stable candidates come out.

## Description

This is a containerized version of [Ubiqiti Network](https://www.ubnt.com/)'s Unifi Controller version 5.

The following options may be of use:

- Set the timezone with `TZ`
- Bind mount the `data` and `log` volumes

It is suggested that you include --init to handle process reaping
Example to test with

```bash
mkdir -p unifi/data
mkdir -p unifi/log
docker run --rm --init -p 8080:8080 -p 8443:8443 -p 3478:3478/udp -p 10001:10001/udp -e TZ='Africa/Johannesburg' -v ~/unifi:/unifi --name unifi jacobalberty/unifi:stable
```

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
          PKGURL: https://dl.ubnt.com/unifi/5.5.24/unifi_sysvinit_all.deb
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

### `BIND_PRIV`

Default: `true`

This is used to enable binding to ports less than 1024 when running the UniFi service as a restricted user. On some docker filesystem combinations setcap may not work so you would need to set this to false.

### `RUNAS_UID0`

Default: `true`

This is used to determine whether or not the UniFi service runs as a privileged (root) user. The default value is `true` but it is recommended to use `false` instead.

### `UNIFI_UID` and `UNIFI_GID`

Default: `999` for both

These variables set the UID and GID for the user and group the UniFi service runs as when `RUNAS_UID0` is set to false

### `TZ`

TimeZone. (i.e America/Chicago)

### `JVM_MAX_THREAD_STACK_SIZE`

used to set max thread stack size for the JVM

Ex:

```
--env JVM_MAX_THREAD_STACK_SIZE=1280k
```

as a fix for https://community.ubnt.com/t5/UniFi-Routing-Switching/IMPORTANT-Debian-Ubuntu-users-MUST-READ-Updated-06-21/m-p/1968251#M48264

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

### 10001/udp - UBNT Discovery

See [UniFi - Ports Used](https://help.ubnt.com/hc/en-us/articles/218506997-UniFi-Ports-Used)

## Multi-process container

While micro-service patterns try to avoid running multiple processes in a container, the unifi5 container tries to follow the same process execution model intended by the original debian package and it's init script, while trying to avoid needing to run a full init system.

`dumb-init` has now been removed. Instead it is now suggested you include --init in your docker run command line. If you are using docker-compose you can accomplish the same by making sure you use version 2.2 of the yml format and add `init: true` to your service definition.

`unifi.sh` executes and waits on the jsvc process which orchestrates running the controller as a service. The wrapper script also traps SIGTERM to issue the appropriate stop command to the unifi java `com.ubnt.ace.Launcher` process in the hopes that it helps keep the shutdown graceful.


## Init scripts

You may now place init scripts to be launched during the unifi startup in /usr/local/unifi/init.d to perform any actions unique to your unifi setup. An example bash script to set up certificates is in `/usr/unifi/init.d/import.sh`.

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
