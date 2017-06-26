# unifi-docker

## Important note

UniFi is presently broken in the current kernel of many popular distributions \(See [UniFi Forum post](https://community.ubnt.com/t5/UniFi-Routing-Switching/IMPORTANT-Debian-Ubuntu-users-MUST-READ-Updated-06-21/m-p/1968251#M48264) for details\). This image contains a fix you can activate throught the `JVM_MAX_THREAD_STACK_SIZE` environment variable. An example of how to do this on the docker command line is `--env JVM_MAX_THREAD_STACK_SIZE=1280k`. Depending on your docker stack you may need to pass this environment variable another way, please see the relevant software's documentation for passing environment variables. 

## Description

This is a containerized version of [Ubiqiti Network](https://www.ubnt.com/)'s Unifi Controller version 5.

Use `docker run --net=host -d jacobalberty/unifi:unifi5` to run it.

The following options may be of use:

- Set the timezone with `TZ`
- Bind mount the `data` and `log` volumes

Example to test with

```bash
mkdir -p unifi/data
mkdir -p unifi/logs
docker run --rm --net=host -e TZ='Africa/Johannesburg' -v ~/unifi/data:/var/lib/unifi -v ~/unifi/logs:/var/log/unifi --name unifi jacobalberty/unifi:unifi5
```

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

## Mulit-process container

While micro-service patterns try to avoid running multiple processes in a container, the unifi5 container tries to follow the same process execution model intended by the original debian package and it's init script, while trying to avoid needing to run a full init system.

Essentially, `dump-init` runs a simple shell wrapper script placed at `/usr/local/bin/unifi.sh`. `unifi.sh` executes and waits on the jsvc process which orchestrates running the controller as a service. The wrapper script also traps SIGTERM to issue the appropriate stop command to the unifi java `com.ubnt.ace.Launcher` process in the hopes that it helps keep the shutdown graceful.

Example seen within the container after it was started

```bash
$  docker exec -it ef081fcf6440 bash
# ps -e -o pid,ppid,cmd | more
  PID  PPID CMD
    1     0 /usr/bin/dumb-init -- /usr/local/bin/unifi.sh
    7     1 sh /usr/local/bin/unifi.sh
    9     7 unifi -nodetach -home /usr/lib/jvm/java-8-openjdk-amd64 -classpath /usr/share/java/commons-daemon.jar:/usr/lib/unifi/lib/ace.jar -pidfile /var/run/unifi/unifi.pid -procname unifi -outfile /var/log/unifi/unifi.out.log -errfile /var/log/unifi/unifi.err.log -Dunifi.datadir=/var/lib/unifi -Dunifi.rundir=/var/run/unifi -Dunifi.logdir=/var/log/unifi -Djava.awt.headless=true -Dfile.encoding=UTF-8 -Xmx1024M -Xms32M com.ubnt.ace.Launcher start
   10     9 unifi -nodetach -home /usr/lib/jvm/java-8-openjdk-amd64 -classpath /usr/share/java/commons-daemon.jar:/usr/lib/unifi/lib/ace.jar -pidfile /var/run/unifi/unifi.pid -procname unifi -outfile /var/log/unifi/unifi.out.log -errfile /var/log/unifi/unifi.err.log -Dunifi.datadir=/var/lib/unifi -Dunifi.rundir=/var/run/unifi -Dunifi.logdir=/var/log/unifi -Djava.awt.headless=true -Dfile.encoding=UTF-8 -Xmx1024M -Xms32M com.ubnt.ace.Launcher start
   31    10 /usr/lib/jvm/java-8-openjdk-amd64/jre/bin/java -Xmx1024M -XX:ErrorFile=/usr/lib/unifi/data/logs/hs_err_pid<pid>.log -Dapple.awt.UIElement=true -jar /usr/lib/unifi/lib/ace.jar start
   58    31 bin/mongod --dbpath /usr/lib/unifi/data/db --port 27117 --logappend --logpath logs/mongod.log --nohttpinterface --bind_ip 127.0.0.1
  108     0 bash
  116   108 ps -e -o pid,ppid,cmd
  117   108 [bash]
```

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
