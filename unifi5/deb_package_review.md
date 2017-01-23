Debian packages provide a decent amount of meta-data to understand where software installs.

Here a notes from skimming of the package's `data` and `control` portions.

# data

The `init` script probably gives away the most info about how the controller software runs. It can be found at `usr/lib/unifi/bin/unifi.ini`

```bash
BASEDIR="/usr/lib/unifi"
...

PIDFILE="/var/run/${NAME}/${NAME}.pid"
...

CODEPATH=${BASEDIR}
DATALINK=${BASEDIR}/data
LOGLINK=${BASEDIR}/logs
RUNLINK=${BASEDIR}/run

DATADIR=/var/lib/${NAME}
LOGDIR=/var/log/${NAME}
RUNDIR=/var/run/${NAME}

# fix path for ace
dir_symlink_fix ${DATADIR} ${DATALINK}
dir_symlink_fix ${LOGDIR} ${LOGLINK}
dir_symlink_fix ${RUNDIR} ${RUNLINK}
[ -z "${UNIFI_SSL_KEYSTORE}" ] || file_symlink_fix ${UNIFI_SSL_KEYSTORE} ${DATALINK}/keystore
```

And

```
MONGOLOCK="${DATAPATH}/db/mongod.lock"
JVM_EXTRA_OPTS="${JVM_EXTRA_OPTS} -Dunifi.datadir=${DATADIR} -Dunifi.logdir=${LOGDIR} -Dunifi.rundir=${RUNDIR}"
```

Note Java settings, 1G heap probably covers a large site!? Smaller installations could drop this?

```bash
JAVA_ENTROPY_GATHER_DEVICE=
JVM_MAX_HEAP_SIZE=1024M
JVM_INIT_HEAP_SIZE=
```

And all the Java JSVC options for running the java app as a service. It uses the pidfile and output to SYSLOG.

```bash
JSVC_OPTS="${JSVC_OPTS}\
 -home ${JAVA_HOME} \
 -cp /usr/share/java/commons-daemon.jar:${BASEDIR}/lib/ace.jar \
 -pidfile ${PIDFILE} \
 -procname ${NAME} \
 -outfile SYSLOG \
 -errfile SYSLOG \
 ${JSVC_EXTRA_OPTS} \
 ${JVM_OPTS}"
```

Another key observation is that the process is run with `/usr/lib/unif` as the base directory.

```bash
cd ${BASEDIR}
```

A truncated view of the directories in the `data` portion of the package.

```
$ tree -d data
data
├── etc
│   └── init.d
├── lib
│   └── systemd
│       └── system
└── usr
    ├── lib
    │   └── unifi
    │       ├── bin
    │       ├── conf
    │       ├── dl
    │       │   └── firmware
    │       │       ├── BZ2
    │       │       │   └── 3.7.28.5442
...
    │       ├── lib
    │       │   └── native
    │       │       ├── Linux
    │       │       │   ├── amd64
    │       │       │   └── armhf
    │       │       ├── Mac
    │       │       │   └── x86_64
    │       │       └── Windows
    │       │           └── amd64
    │       └── webapps
    │           └── ROOT
    │               ├── app-unifi
    │               │   ├── config
...
    │               │   ├── js
    │               │   └── locales
    │               │       ├── cs
...
    │               ├── pages
    │               └── WEB-INF
    └── share
        └── doc
            └── unifi
```

# control

## Version assessed

```
Package: unifi
Version: 5.3.8-8920
```

## Dependency notes

Notable dependencies

- mongodb-server (>=2.4.10) | mongodb-10gen (>=2.4.14) | mongodb-org-server (>=2.6.0)
- openjdk-7-jre-headless | java8-runtime-headless

## Package scripts

A few code snippets are shown to backup some assumptions.

### prerm

`prerm` shows which directories should be removed before the remove/upgrade task occurs. This indicates parts that need not be in a permanent volume.

```bash
CODEPATH=/usr/lib/unifi
...

if [ "$1" == "remove" ] || [ "$1" == "upgrade" ]; then
...

  [ ! -d ${CODEPATH}/webapps/ROOT ] || rm -rf ${CODEPATH}/webapps/ROOT
  [ ! -d ${CODEPATH}/work ] || rm -rf ${CODEPATH}/work
  rm -rf ${CODEPATH}/data ${CODEPATH}/logs ${CODEPATH}/run ${CODEPATH}/bin/mongod
...

fi
```

So for `/usr/lib/unifi/`, `webapps/ROOT`, `data`, `logs`, `run`, and `bin/mongod` are removed suggesting they don't have critical data and should be cleared out between upgrades.

### postrm

`postrm` helps identify `/var/lib/unifi`, `/var/log/unifi` and `/var/run/unifi` as directories that should probably be managed as permanent volumes, given the `--purge` command would target those.

Note

```bash
NAME=unifi
BASEDIR=/usr/lib/${NAME}

DATADIR=/var/lib/${NAME}
LOGDIR=/var/log/${NAME}
RUNDIR=/var/run/${NAME}
```

And the purge condition logic helps confirm that Unifi most likely persists those directories

```bash
purge)
    update-rc.d -f unifi remove
    systemd_purge
    [ ! -d ${DATADIR} ] || rm -rf ${DATADIR}
    [ ! -d ${LOGDIR} ] || rm -rf ${LOGDIR}
    [ ! -d ${RUNDIR} ] || rm -rf ${RUNDIR}
```

Also, `/etc/default/unfi` will contain more settings related to starting unifi.

Furthermore, there is some logic to back-out and revert to the previous version if the package update detects an error.

### preinst

Updates should backup the Mongo DB?

`preinst` script shows that backups of the UniFi Mongo DB at `/var/lib/unifi/db/` are done when upgrading. It may then follow that the docker approach of building a new image to deploy over previously mounted volumes should consider the backup check. Perhaps the the volume containing /var/lib/unifi/db should be mounted during the docker build process?

# UniFi Controller processes

Observations from running in a VM

```bash
# ps -e -o user,pid,ppid,cmd | less
UID   PID  PPID CMD
...

mongodb   3498     1 /usr/bin/mongod --config /etc/mongodb.conf
root      4406     1 unifi -home /usr/lib/jvm/java-8-openjdk-amd64 -cp /usr/share/java/commons-daemon.jar:/usr/lib/unifi/lib/ace.jar -pidfile /var/run/unifi/unifi.pid -procname unifi -outfile SYSLOG -errfile SYSLOG -Dunifi.datadir=/var/lib/unifi -Dunifi.logdir=/var/log/unifi -Dunifi.rundir=/var/run/unifi -Xmx1024M -Djava.awt.headless=true -Dfile.encoding=UTF-8 com.ubnt.ace.Launcher start
root      4407  4406 unifi -home /usr/lib/jvm/java-8-openjdk-amd64 -cp /usr/share/java/commons-daemon.jar:/usr/lib/unifi/lib/ace.jar -pidfile /var/run/unifi/unifi.pid -procname unifi -outfile SYSLOG -errfile SYSLOG -Dunifi.datadir=/var/lib/unifi -Dunifi.logdir=/var/log/unifi -Dunifi.rundir=/var/run/unifi -Xmx1024M -Djava.awt.headless=true -Dfile.encoding=UTF-8 com.ubnt.ace.Launcher start
root      4409  4406 unifi -home /usr/lib/jvm/java-8-openjdk-amd64 -cp /usr/share/java/commons-daemon.jar:/usr/lib/unifi/lib/ace.jar -pidfile /var/run/unifi/unifi.pid -procname unifi -outfile SYSLOG -errfile SYSLOG -Dunifi.datadir=/var/lib/unifi -Dunifi.logdir=/var/log/unifi -Dunifi.rundir=/var/run/unifi -Xmx1024M -Djava.awt.headless=true -Dfile.encoding=UTF-8 com.ubnt.ace.Launcher start
root      4430  4409 /usr/lib/jvm/java-8-openjdk-amd64/jre/bin/java -Xmx1024M -XX:ErrorFile=/usr/lib/unifi/data/logs/hs_err_pid<pid>.log -Dapple.awt.UIElement=true -jar /usr/lib/unifi/lib/ace.jar start
root      5405  4430 bin/mongod --dbpath /usr/lib/unifi/data/db --port 27117 --logappend --logpath logs/mongod.log --nohttpinterface --bind_ip 127.0.0.1
```

And network port information

```bash
# netstat -lntp
Active Internet connections (only servers)
Proto Recv-Q Send-Q Local Address           Foreign Address         State       PID/Program name
tcp        0      0 127.0.0.1:27017         0.0.0.0:*               LISTEN      3498/mongod     
tcp        0      0 127.0.0.1:27117         0.0.0.0:*               LISTEN      5405/mongod     
tcp        0      0 0.0.0.0:22              0.0.0.0:*               LISTEN      171/sshd        
tcp6       0      0 :::8843                 :::*                    LISTEN      4430/java       
tcp6       0      0 :::8880                 :::*                    LISTEN      4430/java       
tcp6       0      0 :::8080                 :::*                    LISTEN      4430/java       
tcp6       0      0 :::22                   :::*                    LISTEN      171/sshd        
tcp6       0      0 :::8443                 :::*                    LISTEN      4430/java
```

Example way to stop gracefully

```bash
jsvc -nodetach -pidfile /var/run/unifi/unifi.pid -stop com.ubnt.ace.Launcher stop
```

# Info from ubnt docs/site

- [UniFi - Ports Used](https://help.ubnt.com/hc/en-us/articles/218506997-UniFi-Ports-Used)
- [UniFi - What log files exist and where can I view them?](https://help.ubnt.com/hc/en-us/articles/204959834?input_string=errors+in+debian+unifi.init+file)
