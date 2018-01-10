#!/bin/bash
# Release a set of reserved hosts
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RES_ID="${1:-}"

HOSTS_FILE="${HOSTS_FILE:-hosts.txt}"
RES_DIR="/root/.reservation"

for PARAM in RES_ID; do
  if [ -z "${!PARAM}" ] ; then
    echo "Missing require parameter: ${PARAM}"  >&2
    echo "Usage ${0} RES_ID" >&2
    exit 1
  fi
done

if [ ! -f "${HOSTS_FILE}" ] ; then
  echo "Hosts file not found ${HOSTS_FILE}" >&2
  exit 1
fi

HOSTS=$(<"${HOSTS_FILE}")
if [ -z "${HOSTS}" ] ; then
  echo "No hosts defined in ${HOSTS_FILE}" >&2
  exit 1
fi

RESERVED_HOSTS=""
for HOST_RES in ${HOSTS} ; do
  HOST=${HOST_RES/_*}
  echo "Checking host ${HOST}" >&2
  HOST_RES_ID=$("${SCRIPT_DIR}/host-command.sh" ${HOST} 'cat /root/.reservation/id' 2>/dev/null || true)
  if [ ! -z "${HOST_RES_ID}" ] && [ "${HOST_RES_ID}" = "${RES_ID}" ] ; then
    echo "Found host in reservation ${HOST}" >&2
    RESERVED_HOSTS=$("${SCRIPT_DIR}/host-command.sh" ${HOST} 'cat /root/.reservation/hosts' 2>/dev/null)
    break
  fi
done

echo "Freeing hosts in reservation ${RES_ID} ${RESERVED_HOSTS}" >&2
for HOST in ${RESERVED_HOSTS} ; do
  "${SCRIPT_DIR}/host-free.sh" ${HOST}
done

exit 0
