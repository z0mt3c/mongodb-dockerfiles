#!/bin/bash

set -e

if [[ ! -f /opt/mongodb_password ]]; then
    echo "No mongodb password defined"
    exit 1
fi
if [[ ! -f /opt/mongodb/initialized ]]; then
    mkdir -p /opt/mongodb
    /usr/bin/mongod --bind_ip=127.0.0.1 --dbpath=/opt/mongodb --noauth --fork --syslog
    DB_PASSWORD="$(cat "/opt/mongodb_password")"
    sleep 2s
    echo "Creating admin user..."
    mongo <<EOF
use admin
db.createUser({user: "admin", pwd:"${DB_PASSWORD}", roles:["clusterAdmin", "userAdminAnyDatabase"]})
EOF
    kill $(pidof mongod)
    sleep 8s
    touch /opt/mongodb/initialized
fi

# always update permissions in case of user-id being switched
chown -R mongodb:mongodb /opt/mongodb
chmod 755 /opt/mongodb

exec /usr/bin/mongod --dbpath=/opt/mongodb --auth
