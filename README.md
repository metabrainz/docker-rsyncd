# docker-volume-container-rsync

A volume container using rsync.

## Usage

First, you can launch a volume container exposing a volume with rsync.

```sh
$ CID=$(docker run -d -p 10873:873 -v /tmp/:/data --name rsyncd metabrainz/docker-rsyncd)
```

You can connect to rsync server inside a container like this:

```sh
$ rsync rsync://<docker>:10873/
volume          docker volume
```

To sync:

```sh
$ rsync -avP /path/to/dir rsync://<docker>:10873/volume/
```

Next, you can launch a container connected with the volume under `/data`.

```sh
$ docker run -it --volumes-from $CID ubuntu /bin/sh
```

## Advanced

In default, rsync server accepts a connection only from `192.168.0.0/16` and `172.12.0.0/12` for security reasons.
You can override via an environment variable like this:

```sh
$ docker run -d -p 10873:873 -e ALLOW='10.0.0.0/8 x.x.x.x/y' nabeken/docker-volume-container-rsync
```

## All Variables

* `VOLUME` - Define the volume path (default: `/data`)
* `ALLOW` - Which network segments to allow (default: `192.168.0.0/16 172.16.0.0/12`). An empty value or `*` allows anybody (no `hosts` lines are written)
* `VOLUME_NAME` - The logical name of the volume (default: `volume`)
* `COMMENT` - The share comment (default: `docker volume`)
* `READ_ONLY` - A boolean to set if the share should be read-only or not (default: `true`)
* `OWNER/GROUP` - Define the owner/group name or uid/gid to use (default: `nobody/nogroup`)
* `BWLIMIT` - Bandwidth limit in Kb/s (default: `0`)
* `MAX_CONNECTIONS` - Maximum number of connections (default: `20`)
* `REVERSE_LOOKUP` - Resolve client names (`reverse lookup`, default: `yes`). Use `no` if `ALLOW` only has addresses
* `TRANSFER_LOGGING` - Log every transferred file to stdout (default: `no`)
* `LOG_FORMAT` - Format of those lines (default: `%t [%p] %a %m %o %f %l %b`: client address, module, operation, file, file size, bytes transferred)

## Seeing the real client address

With a published port (`-p 873:873`) Docker may hide the client address: if the daemon runs with
`"iptables": false`, `docker-proxy` terminates the connection and every client appears as the bridge
gateway (`172.17.0.1`). Run the container with `--net=host` instead (no `-p`), and set `ALLOW='*'`
if the module is public, since `ALLOW` is then checked against real client addresses:

```sh
$ docker run -d --net=host -v /srv/pub:/data:ro \
    -e VOLUME_NAME=public -e ALLOW='*' -e REVERSE_LOOKUP=no -e TRANSFER_LOGGING=yes \
    --name rsyncd metabrainz/docker-rsyncd
```



### Based on https://github.com/InAnimaTe/docker-rsync
