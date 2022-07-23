# Side Projects and Background Info

The [README.md](./README.md) document describes how to get
Unifi-in-Docker running for the most common case -
a single easy-to-use container that runs everything.

This document describes background, side projects,
or other information we discovered while producing the
Unifi-in-Docker container. 

## Running with separate Mongo container

The `docker-compose.yml` file in this repository provides a
single command that orchestrates all the actions required
to bring up Mongo and Unifi Controller in separate containers,
using named volumes for important directories.

Simply copy the `docker-compose.yml` file
to your host computer's local disk
(or clone this repo) and run:

```bash
cd <directory with docker-compose.yml>
docker-compose up -d 
```

**Setting Options:**

* The `docker-compose.yml` file contains the options
passed to Unifi Controller when it starts.
Edit the `docker-compose.yml` file setting its values according to the 
[Options on the command line.](./README.md#options-on-the-command-line)
* _Optional:_ Add additional `-e <any-environment-variables-you-want>` to the `docker-compose up` line

To change options to Unifi Controller::

```bash
cd <directory with docker-compose.yml>
docker-compose down # this stops Unifi Controller and MongoDB
# ... edit the options in the docker-compose.yml file ...
docker-compose up ... # to resume operation
```

### External MongoDB environment variables

These variables are used to implement support for an [external MongoDB server](https://community.ubnt.com/t5/UniFi-Wireless/External-MongoDB-Server/td-p/1305297) and must all be set in order for this feature to work. Once all are set then the configuration file value for `db.mongo.local` will automatically be set to `false`.

* `DB_URI`
Maps to `db.mongo.uri`.

* `STATDB_URI`
Maps to `statdb.mongo.uri`.

* `DB_NAME`
Maps to `unifi.db.name`.

## Beta Users

The `beta` image has been updated to support package installation at run time.
With this change you can now install the beta releases on more systems,
such as Synology.
This should open up access to the beta program for more users of this docker image.

**NOTE:** This Beta image only works if you run as root.
It also may need updates to handle permissions to handle the
`RUNAS_UID0=false` changes.
If you have questions, look for or create an issue about this.

If you would like to submit a new feature for the images,
the beta branch is probably a good one to apply it against as well.
I will be cleaing up the Dockerfile under beta and gradually pushing out
the improvements to the other branches.
So any major changes should apply cleanly against the `beta` branch.

### Running Beta Builds from the Command Line

Using the Beta build is pretty easy:
just substitute the correct URL from the Unifi site
for the `PKGURL` parameter,
and use `jacobalberty/unifi:beta` for the image
like this:

```bash
docker run -d --init \
   --restart=unless-stopped \
   -p 8080:8080 -p 8443:8443 -p 3478:3478/udp \
   -e TZ='Africa/Johannesburg' \
   -v ~/unifi:/unifi \
   --name unifi \
   -e PKGURL=https://dl.ubnt.com/unifi/5.6.30/unifi_sysvinit_all.deb \
   jacobalberty/unifi:beta
```

### Running the Beta Using `docker-compose.yml` 

In the containers service definition of the `docker-compose.yml` file, replace `image: jacobalberty/unifi` with the following:

```shell
        image: jacobalberty/unifi:beta
         environment:
          PKGURL: https://dl.ubnt.com/unifi/5.6.40/unifi_sysvinit_all.deb
```

Replace the PKGURL: link with a link to the package you want.

## Init scripts

You may now place init scripts to be launched during the unifi startup in /usr/local/unifi/init.d to perform any actions unique to your unifi setup. An example bash script to set up certificates is in `/usr/unifi/init.d/import_cert`.

## Other Techniques for Adoption

The following are not strictly required for Unifi-in-Docker,
but they collect information that may be helpful as you
move to a new controller instance.

### Use Unifi export and migrate tool

Unifi can export and migrate the APs to a new controller
[see this article for example.](https://lazyadmin.nl/home-network/migrate-unifi-controller/) 

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
