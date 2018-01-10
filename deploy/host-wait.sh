#!/bin/bash
# Wait for hosts kickstart to complete
set -uo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOST_WAIT="${HOST_WAIT:-15}" # wait in minutes
START_TIME="$(date +%s)"
WAIT_SSH_OPTS="${WAIT_SSH_OPTS:--o ConnectTimeout=5 -o ConnectionAttempts=1}"

for HOST in "$@"; do
  while true ; do
    CURRENT_TIME="$(date +%s)"
    WAITED_SECONDS="$((CURRENT_TIME - START_TIME))"
    echo "Waiting for host ${HOST} ${WAITED_SECONDS}s"
    ping -n -c 1 -W 5 "${HOST}" &> /dev/null
    if [ $? -eq 0 ] ; then
        SSH_OPTS="${WAIT_SSH_OPTS}" "${SCRIPT_DIR}/host-command.sh" "${HOST}" whoami &> /dev/null
        [ $? -ne 0 ] || continue 2
    fi
    [ ${WAITED_SECONDS} -lt $((HOST_WAIT * 60)) ] || exit 1
    sleep 30
  done
done

echo "Hosts available $*"
