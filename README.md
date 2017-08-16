# unifi-docker

## Supported docker hub tags and respective `Dockerfile` links 
| Tag | Description |
| --- | --- |
| [`latest`, `stable`, `unifi-5.5` ](https://github.com/jacobalberty/unifi-docker/blob/master/Dockerfile ) | Tracks UniFi stable version - 5.5.20 as of 2017-07-31 |
| [`oldstable`, `unifi-5.4` ](https://github.com/jacobalberty/unifi-docker/blob/oldstable/Dockerfile ) | Tracks UniFi Old Stable version - 5.4.19 as of 2017-07-31 |


These tags generally track the UniFi APT repository. We do lead the repository a little when it comes to pushing the latest version. The latest version gets pushed when it moves from `stable candidate` to `stable` instead of waiting for it to hit the repository.

In adition to these tags you may tag specific versions as well, for example `jacobalberty/unifi:5.4.19` will get you unifi 5.4.19 no matter what the current version is.

## Description

This is a containerized version of [Ubiqiti Network](https://www.ubnt.com/)'s Unifi Controller version 5.

The following options may be of use:

- Set the timezone with `TZ`
- Bind mount the `data` and `log` volumes

It is suggested that you include --init to handle process reaping
Example to test with

```bash
mkdir -p unifi/data
mkdir -p unifi/logs
docker run --rm --init -p 8080:8080 -p 8443:8443 -p 3478:3478 -p 10001:10001 -e TZ='Africa/Johannesburg' -v ~/unifi/data:/var/lib/unifi -v ~/unifi/logs:/var/log/unifi --name unifi jacobalberty/unifi:unifi5
```
## Adopting access points/switches/security gateway
### Layer 3 adoption

The default example requires some l3 adoption method. You have a couple options to adopt.

#### SSH Adoption
The quickest one off method is to ssh into the access point and run the following commands
```
mca-cli
set-inform http://<host_ip>:8080/inform
```
#### Other options

You can see more options on the (UniFi website)[https://help.ubnt.com/hc/en-us/articles/204909754-UniFi-Layer-3-methods-for-UAP-adoption-and-management]


### Layer 2 adoption
You can also enable layer 2 adoption through one of two methods.

#### host networking

If you launch the container using host networking \(With the `--net=host` parameter on `docker run`\) Layer 2 adoption works as if the controller is installed on the host.

#### Bridge networking

It is possible to configure the macvlan driver to bridge your container to the host's networking adapter. Specific instructions for this container are not yet available but you can read a write-up for docker at http://collabnix.com/docker-17-06-swarm-mode-now-with-macvlan-support/


## Beta users

There is now a new `beta` branch on github to support easier building of betas. This branch does not exist on the docker hub at all, and must be built from the git repository.
You simply build and pass the build argument `PKGURL` with the url to the .deb file for the appropriate beta you wish to build. I believe
this will keep closest with the letter and spirit of the beta agreement on the unifi forums while still allowing relatively easy access to the betas.
This build method is the method I will be using for my own personal home network to test the betas on so it should remain relatively well tested.


If you would like to submit a new feature for the images the beta branch is probably a good one to apply it against as well.
I will be cleaing up the Dockerfile under beta and gradually pushing out the improvements to the other branches. So any major changes
should apply cleanly against the `beta` branch.

### Building beta using docker build

The command line is pretty simple:

```
docker build -t unifi-beta --build-arg PKGURL=https://dl.ubnt.com/unifi/5.5.20/unifi_sysvinit_all.deb "https://github.com/jacobalberty/unifi-docker.git#beta"
```

Simply replace the url to the debian package with the version you prefer.


### Building beta using docker-compose.yml version 2
This is just as easy when using version 2 of the docker-compose.yml file format.

Under your containers service definition instead of using `image: jacobalberty/unifi` use the following:

```
        build:
         context: https://github.com/jacobalberty/unifi-docker.git#beta
         args:
          PKGURL: https://dl.ubnt.com/unifi/5.5.20/unifi_sysvinit_all.deb
```

Once again, simply change PKGURL to point to the package you would like to use.

## Volumes:

### `/var/lib/unifi`

Configuration data

### `/var/log/unifi`

Log files

### `/var/run/unifi`

Run information

## Environment Variables:

### `TZ`

TimeZone. (i.e America/Chicago)

### `JVM_MAX_THREAD_STACK_SIZE`

used to set max thread stack size for the JVM

Ex:

```--env JVM_MAX_THREAD_STACK_SIZE=1280k```

as a fix for https://community.ubnt.com/t5/UniFi-Routing-Switching/IMPORTANT-Debian-Ubuntu-users-MUST-READ-Updated-06-21/m-p/1968251#M48264

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

`dumb-init` has now been removed. Instead it is now suggested you include --init in your docker run command line.
If you are using docker-compose you can accomplish the same by making sure you use version 2.2 of the yml format and add `init: true` to your service definition.

`unifi.sh` executes and waits on the jsvc process which orchestrates running the controller as a service. The wrapper script also traps SIGTERM to issue the appropriate stop command to the unifi java `com.ubnt.ace.Launcher` process in the hopes that it helps keep the shutdown graceful.


## Certificate Support

To use custom SSL certs, you must map a volume with the certs to /var/cert/unifi

They should be named:
```
cert.pem  # The Certificate
privkey.pem # Private key for the cert
chain.pem # full cert chain
```
For letsencrypt certs, we'll autodetect that and add the needed Identrust X3 CA Cert automatically.


## TODO

Future work?

- Don't run as root (but Unifi's Debian package does by the way...)
- Possibly use Debian image with systemd init included (but thus far, I don't know of an official Debian systemd image to base off)
