#!/bin/sh

if [ -d "work" ]; then
  sudo rm -fr work
fi

echo "Create database volume..."
mkdir -p work/init work/data
cp db.sql work/init
sudo chcon -Rt container_file_t work
sudo chown -R 27:27 work

# TODO Add podman run for mysql image here
# Assign the container an IP from range defined the RFC 1918: 10.88.0.0/16


sleep 9

# TODO Add podman run for todonodejs image here

sudo podman run -d --name todoapi -e MYSQL_DATABASE=items -e MYSQL_USER=user1 \
-e MYSQL_PASSWORD=mypa55 -p 30080:30080 \
do180/todonodejs
