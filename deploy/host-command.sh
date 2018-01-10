#!/bin/bash
# Run a command on a host
set -euo pipefail

SSH_KEY_FILE=""
SSH_KNOWNHOSTS="${SSH_KNOWNHOSTS:-/dev/null}"
SSH_STRICTHOSTKEYS="${SSH_STRICTHOSTKEYS:-no}"
SSH_USER="${SSH_USER:-root}"
SSH_OPTS="${SSH_OPTS:-}"
HOST="${1}"

if [ -z "$1" ] ; then
  echo "Host is required"
  exit 1
fi

if [ -z "$2" ] ; then
  echo "Command is required"
  exit 1
fi

if [ ! -z "${SSH_STRICTHOSTKEYS}" ] ; then
    SSH_OPTS="-o StrictHostKeyChecking=${SSH_STRICTHOSTKEYS} ${SSH_OPTS}"
fi

if [ ! -z "${SSH_KNOWNHOSTS}" ] ; then
    SSH_OPTS="-o UserKnownHostsFile=\"${SSH_KNOWNHOSTS}\" ${SSH_OPTS}"
fi

if [ ! -z "${SSH_KEY_FILE}" ] ; then
    SSH_OPTS="-i \"${SSH_KEY_FILE}\" ${SSH_OPTS}"
fi

shift

ssh ${SSH_OPTS} \
  -o BatchMode=yes \
  ${SSH_USER}@${HOST} "$@"
