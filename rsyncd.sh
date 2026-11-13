#!/bin/bash
set -e
source /etc/container_environment.sh

VOLUME=${VOLUME:-/data}
ALLOW=${ALLOW:-192.168.0.0/16 172.16.0.0/12}
OWNER=${OWNER:-nobody}
GROUP=${GROUP:-nogroup}
VOLUME_NAME=${VOLUME_NAME:-volume}
READ_ONLY=${READ_ONLY:-true}
COMMENT=${COMMENT:-"docker volume"}
MAX_CONNECTIONS=${MAX_CONNECTIONS:-20}
BWLIMIT=${BWLIMIT:-0}
REVERSE_LOOKUP=${REVERSE_LOOKUP:-yes}
TRANSFER_LOGGING=${TRANSFER_LOGGING:-no}
# %a client address, %m module, %o operation (send/recv), %f file,
# %l file length, %b bytes actually transferred
LOG_FORMAT=${LOG_FORMAT:-"%t [%p] %a %m %o %f %l %b"}

# ALLOW is a list of addresses/networks. An empty value or "*" means anybody:
# no "hosts" lines are written, so rsync does no access check at all.
HOSTS_CONF=""
if [ -n "${ALLOW}" ] && [ "${ALLOW}" != "*" ]; then
  HOSTS_CONF="    hosts deny = *
    hosts allow = ${ALLOW}
"
fi

chown "${OWNER}:${GROUP}" "${VOLUME}" || true

[ -f /etc/rsyncd.conf ] || cat <<EOF > /etc/rsyncd.conf
uid = ${OWNER}
gid = ${GROUP}
use chroot = yes
pid file = /var/run/rsyncd.pid
log file = /dev/stdout
max connections = ${MAX_CONNECTIONS}
strict modes = yes
ignore errors = no
ignore nonreadable = yes
reverse lookup = ${REVERSE_LOOKUP}
transfer logging = ${TRANSFER_LOGGING}
log format = ${LOG_FORMAT}
timeout = 600
refuse options = checksum
dont compress = *.gz *.tgz *.zip *.z *.rpm *.deb *.iso *.bz2 *.tbz

[${VOLUME_NAME}]
${HOSTS_CONF}    read only = ${READ_ONLY}
    path = ${VOLUME}
    comment = "${COMMENT}"

EOF

OPTS="--no-detach --daemon --config /etc/rsyncd.conf"
if [ $BWLIMIT -gt 0 ]; then
  OPTS="$OPTS --bwlimit=${BWLIMIT}"
fi

exec /usr/bin/ionice -c3 /usr/bin/rsync ${OPTS}
