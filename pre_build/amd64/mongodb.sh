#!/usr/bin/env bash

# Retry 5 times with a wait of 10 seconds between each retry
tryfail() {
    for i in $(seq 1 5);
        do [ $i -gt 1 ] && sleep 10; $* && s=0 && break || s=$?; done;
    (exit $s)
}

tryfail apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 2930ADAE8CAF5059EE73BB4B58712A2291FA4AD5

echo "deb [ arch=amd64 ] https://repo.mongodb.org/apt/ubuntu bionic/mongodb-org/3.6 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-3.6.list

apt-get update
apt-get install -y mongodb-org
